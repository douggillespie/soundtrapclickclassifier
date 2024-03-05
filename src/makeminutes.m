% make a database of porp positive minutes (or counts per minute) for each
% deployment all in one big table. 
% need to get effort data for each period since not all started on midnight
% due to time zone mixumps. 
secsPerDay = 3600*24;
oneSecond = 1/secsPerDay;
maxGap = 30;
hpQStr = ['SELECT ST_Click_Detector_OfflineClicks.UTC, ST_Click_Detector_OfflineClicks.amplitudep2p FROM ST_Click_Detector_OfflineClicks INNER JOIN ',...
    'ST_Click_Detector_OfflineEvents ON ST_Click_Detector_OfflineClicks.ParentId = ',...
    'ST_Click_Detector_OfflineEvents.Id WHERE ST_Click_Detector_OfflineEvents.eventType=''HP'''];
rdQStr = ['SELECT ST_Click_Detector_OfflineClicks.UTC, ST_Click_Detector_OfflineClicks.amplitudep2p FROM ST_Click_Detector_OfflineClicks INNER JOIN ',...
    'ST_Click_Detector_OfflineEvents ON ST_Click_Detector_OfflineClicks.ParentId = ',...
    'ST_Click_Detector_OfflineEvents.Id WHERE ST_Click_Detector_OfflineEvents.eventType=''RDcEv'''];
doQStr = ['SELECT ST_Click_Detector_OfflineClicks.UTC, ST_Click_Detector_OfflineClicks.amplitudep2p FROM ST_Click_Detector_OfflineClicks INNER JOIN ',...
    'ST_Click_Detector_OfflineEvents ON ST_Click_Detector_OfflineClicks.ParentId = ',...
    'ST_Click_Detector_OfflineEvents.Id WHERE ST_Click_Detector_OfflineEvents.eventType=''DcEv'''];
sppNames = {'Amp', 'RD', 'DO'};
ampThresholds = [100:6:130];
outCols = {'Id', 'Deployment', 'Station', 'UTC', 'EndTime', 'Seconds', 'Noise5', 'vx', 'vy'};
colTypes = {'INTEGER NOT NULL', 'INTEGER', 'INTEGER', 'TIMESTAMP', 'TIMESTAMP', 'DOUBLE', 'DOUBLE', 'DOUBLE', 'DOUBLE'};
for s = 1:numel(sppNames)
    for i = 1:numel(ampThresholds)
        outCols{end+1} = sprintf('%sp2pGT%d', sppNames{s}, ampThresholds(i));
        colTypes{end+1} = 'INTEGER';
    end
end
opDatabase = 'C:\ProjectData\Morlais\PositiveMinutes20231107.sqlite3';
con = sqlitedatabase(opDatabase);
tableName = 'PorpoiseMinutes';
exec(con, ['DROP TABLE ' tableName]);
checkTable(con, tableName, true);
for i = 1:numel(outCols)
    checkColumn(con, tableName, outCols{i}, colTypes{i});
end
close(con)

conOut = sqlite(opDatabase);

ind = 0;
interval = 60/secsPerDay;
for stn = 0:14
    for depl = 1:2
        [database, binary, clusters, erinManualDatabase, noise] = morlaisfolders(depl, stn);
        [~,~,erinCheckedDatabase] = erindatabases(depl, stn);
        [detail, deployDate, recoverDate] = deploymentdetail(depl, stn);
        % work out the effort periods. 
        xFiles = dirsub(binary, 'SoundTrap_Click_Detector_ST_Click_Detector_Clicks_*.pgdx');
        clear effStart effEnd
        effStart = [];
        fprintf('Getting effort for depl %d station %d ', depl, stn);
        for i = 1:numel(xFiles)
            [~, fileInf] = loadPamguardBinaryFile(xFiles(i).name);
            fStart = fileInf.fileHeader.dataDate;
            fEnd = fileInf.fileFooter.dataDate;
            if isempty(effStart)
                effStart = fStart;
                effEnd = fEnd;
            elseif fStart-effEnd(end) < maxGap/secsPerDay;
                effEnd(end) = fEnd;
            else
                effStart(end+1) = fStart;
                effEnd(end+1) = fEnd;
            end
        end
        dateOK = effEnd > deployDate | effStart < recoverDate;
        effStart = effStart(dateOK);
        effEnd = effEnd(dateOK);
        effStart = max(effStart, deployDate);
        effEnd = min(effEnd, recoverDate);
        % round down the start time to integer minutes. 
        binStart = floor(effStart(1)*60*24)/(60*24);


        % get all the harbour porpoise clicks for that database. 
        fprintf(', querying database ')
        con = sqlitedatabase(database);
        q = exec(con, hpQStr);
        q = fetch(q);
        clicks = q.Data;
        close(con);
        clickDate = dbdate2datenum(clicks.UTC);
        ampp2p = clicks.amplitudep2p;
        fprintf(', grouping clicks\n')

        % get all the certain dolphin clicks for erind database if it
        % exists. 
        haveDolphins = false;
        if ~isempty(erinCheckedDatabase)
            haveDolphins = true;
            con = sqlitedatabase(erinCheckedDatabase);
            q = exec(con, rdQStr);
            q = fetch(q);
            clicks = q.Data;
            rdDate = dbdate2datenum(clicks.UTC);
            rdAmpp2p = clicks.amplitudep2p;
            q = exec(con, doQStr);
            q = fetch(q);
            clicks = q.Data;
            doDate = dbdate2datenum(clicks.UTC);
            doAmpp2p = clicks.amplitudep2p;
            close(con);
        else
            clear doDate rdDate;
        end
        % get the noise data
        [noise, metrics] = loadnoise(depl, stn);
        noiseStart = noise(:,1); % these should be at minute intervalse too. 
        cal = getcalibration(depl, stn);
        sens = cal.HighGain;
        noise5 = 20*log10(noise(:,7)) + sens;


        % do each effor tperiod separately. 
        for e = 1:numel(effStart)
            nRow = ceil((effEnd(e)-effStart(e))/interval);
            if (nRow < 1)
                continue;
            end
            data = cell(nRow, numel(outCols));
            binStart = floor(effStart(e)*60*24)/(60*24);
            binEnd = binStart + interval;
            iRow = 0;
            binStarts = binStart:60/secsPerDay:effEnd(e)+900/secsPerDay;
            [vx, vy] = interpolatetide(conOut, stn, binStarts);

            while(binEnd < effEnd(e)-1/secsPerDay) 
                iClicks = find(clickDate>=binStart & clickDate<binEnd);
                amps = ampp2p(iClicks);
                if (haveDolphins)
                    rdClicks = find(rdDate>=binStart & rdDate<binEnd);
                    rdAmps = rdAmpp2p(rdClicks);
                    doClicks = find(doDate>=binStart & doDate<binEnd);
                    doAmps = doAmpp2p(doClicks);
                end

                ind = ind+1;
                iRow = iRow+1;
                data{iRow,1} = ind;
                data{iRow,2} = depl;
                data{iRow,3} = stn;
                data{iRow,4} = datestr(binStart,31);
                data{iRow,5} = datestr(binEnd,31);
                data{iRow,6} = round((binEnd-binStart)*secsPerDay);
                % find the noise. 
                laterNoise = find(noiseStart >= binStart - oneSecond);
                data{iRow,7} = noise5(laterNoise(1));
                data{iRow,8} = vx(iRow);
                data{iRow,9} = vy(iRow);
                for a = 1:numel(ampThresholds) 
                    data{iRow,9+a} = sum(amps>ampThresholds(a));
                    iCol = 9+a;
                end
                for a = 1:numel(ampThresholds) 
                    iCol = iCol + 1;
                    if (haveDolphins)
                        data{iRow,iCol} = sum(rdAmps>ampThresholds(a));
                    else
                        data{iRow, iCol} = -1;
                    end
                end
                for a = 1:numel(ampThresholds) 
                    iCol = iCol + 1;
                    if (haveDolphins)
                        data{iRow,iCol} = sum(doAmps>ampThresholds(a));
                    else
                        data{iRow, iCol} = -1;
                    end
                end

                

                binStart = binEnd;
                % round bin start to second, since it ends up rounding down 
                % over 100's of iterations ...
                binStart = round(binStart*secsPerDay)/secsPerDay;

                binEnd = min(binStart+interval, effEnd(e));
            end
            if (iRow < nRow)
                data = data(1:iRow,:);
            end
            if (iRow < 1)
                continue;
            end
            dataTable = cell2table(data, 'VariableNames',outCols);
            sqlwrite(conOut, tableName, dataTable);
        end

% break
    end
    % break;
end
conOut.close