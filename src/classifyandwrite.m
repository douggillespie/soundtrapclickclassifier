function classifyandwrite(dbName, matName)
% take all the clusters from a matlab folder of clusters for a dataset. run
% the classifier, then write the results as events into the offline clicks
% tables in a PAMGuard database. If your detector is called anything but 
% ST_Click_Detector you may need to edit some of the table names. 
minCorrelation = 0.9;
clf
secsPerDay = 3600*24;
d1 = datenum(2022,12,1);
d2 = datenum(2023,4,1);
dBins = d1:2:d2;
clear allHist;
clear lgnd
species = 1:2;
clear allHist lgnd
spNames = {'Porpoise', 'Dolphin', 'Rissos'};
eventTable = 'ST_Click_Detector_OfflineEvents';
clickTable = 'ST_Click_Detector_OfflineClicks';
evColumns = {'Id', 'UID', 'UTC', 'UTCMilliseconds', 'PCLocalTime', 'PCTime', 'ChannelBitmap' ...
    'SequenceBitmap', 'EventEnd', 'eventType', 'nClicks', 'comment'};
ckColumns = {'Id', 'UID', 'UTC', 'UTCMilliseconds', 'PCLocalTime', 'PCTime', 'ChannelBitmap' ...
    'SequenceBitmap', 'ParentID', 'ParentUID','LongDataName', 'BinaryFile', 'EventId', 'ClickNo', 'Amplitude', 'Channels',...
    'amplitude02p','amplitudep2p'};

xtraColNames = {'amplitude02p','amplitudep2p'};
xtraColTypes = {'double','double'}
species = {'HP', 'DO', 'RD'};
longDataName = 'ST Click Detector, Clicks';

[oldclusterSpecies, clusters, classParams] = classifyclusters(matName, 10, 1, minCorrelation);
% now run the slightly more stringent classification
[oldSpecies, otherOld, clusterSpecies] = classifyparams(classParams);


fprintf('linking clusters ')
tic
[clusters, clusterSpecies, clusInds] = joinclassifiedclusters(clusters, clusterSpecies, 60);
fprintf('took %3.1fs\n', toc);
classParams = classParams(clusInds,:);
tic;

%% add the extra columns needed for amplitude information.
con = sqlitedatabase(dbName)
for c = 1:numel(xtraColNames)
    checkColumn(con, clickTable, xtraColNames{c}, xtraColTypes{c})
end
close(con)

% now create a record of the events in the database tables.
con = sqlite(dbName);
% con.AutoCommit = 'off';
q = ['DELETE FROM ' eventTable];
exec(con, q);
q = ['DELETE FROM ' clickTable];
exec(con, q);

% commit(con);
% exec(con, 'vacuum');
nRow = sum(clusterSpecies > 0);
evId = 1;
ckId = 1;
warning ('off', 'all');
for c = 1:numel(clusters)
    if (clusterSpecies(c) == 0)
        continue;
    end
    if mod(evId,100) == 0
        fprintf('writing cluster %d of %d\n', evId, nRow);
    end
    evData{1} = evId;
    evData{2} = evId;
    evData{3} = datenum2dbdate(millisToDateNum(clusters(c).clickMillis(1)), '', true);
    evData{4} = 0;
    evData{5} = evData{3};
    evData{6} = datenum2dbdate(now(), '');
    evData{7} = 1;
    evData{8} = 1;
    evData{9} = datenum2dbdate(millisToDateNum(clusters(c).clickMillis(end)), '', true);
    evData{10} = species{clusterSpecies(c)};
    evData{11} = numel(clusters(c).times);
    evData{12} = sprintf('HP %3.2f, DO %3.2f, RD %3.2f', classParams(c,2), ...
        classParams(c,1), classParams(c,6));
    insert(con, eventTable, evColumns, evData);

    times = clusters(c).times;
    uids = clusters(c).UID;
    clickNo = clusters(c).clickNumber;
    clickFile = clusters(c).fileNames;
    amp = clusters(c).rms50;
    ckData = cell(numel(times),16);
    ckDateNum = millisToDateNum(clusters(c).clickMillis);
    for ck = 1:numel(uids)
        ckData{ck,1} = ckId;
        ckData{ck,2} = uids(ck);
        ckData{ck,3} = datenum2dbdate(millisToDateNum(clusters(c).clickMillis(ck)), '', true);
        %ckData{ck,3} = datenum2dbdate(clusters(c).start+times(ck)/secsPerDay);
        ckData{ck,4} = 0;
        ckData{ck,5} = ckData{ck,3};
        ckData{ck,6} = datenum2dbdate(now(), '', true);
        ckData{ck,7} = 1;
        ckData{ck,8} = 1;
        ckData{ck,9} = evId;
        ckData{ck,10} = evId;
        ckData{ck,11} = longDataName;
        ckData{ck,12} = clickFile{ck};
        ckData{ck,13} = evId;
        ckData{ck,14} = clickNo(ck);
        ckData{ck,15} = amp(ck);
        ckData{ck,16} = 1;
        ckData{ck,17} = clusters(c).amp02p(ck);
        ckData{ck,18} = clusters(c).ampp2p(ck);


        ckId = ckId+1;
    end
    insert(con, clickTable, ckColumns, ckData);
    % do instead as a table using sqlwrite. Takes about half the
    % time. This doesn't work with the in built sqlite connection.
    % tbl = cell2table(ckData, 'variablenames', ckColumns);
    % sqlwrite(con, clickTable, tbl);


    evId = evId + 1;
    % if (evId > 30)
    % break
    % end;
end


% commit(con);
close(con);
%% open with my own system and vaccuum it
%(I don't think this works!)
con = sqlitedatabase(dbName);
exec(con, 'VACUUM');
close(con);

% break;
dbEnd = toc;
fprintf('time taken to write %d events is %3.1fs\n', evId-1, dbEnd);

