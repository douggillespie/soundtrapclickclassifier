function clusterclicks(binFolder, outFolder, countInterval, minClicks, minCorrelation)
% start to experiment with some clustering of clicks a'la Frasier.
% https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009613
% https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1005823
% This function basically just pulls all the clicks out of binary and does
% the first stage clustering. 
% eventual plan will be to create some events back in the PAMGuard database
% from these, so will need to add some bookkeeping data to each cluster as
% required by the offlineclicks tables. 
% Currently this will take one days binary data at a time, and cluster all
% the clicks in the binary files in that folder. These clusters are then
% written to a mat file in the outFolder. A separate function
% classifyclusters (and classifyallclusters) will then run classifiers on
% the clusters and write event information to the PAMGuard database. 
verbose = 0;
% binFolder = 'C:\\ProjectData\\Mentermon\\WP1aData\\Station0_dep0_Binary3Day'
if nargin < 1
    [database binFolder] = morlaisfolders(0);
%     binFolder = 'C:\ProjectData\Morlais\WP1a\STMORLAIS_WP1a_Dep1_00binary'
end
if nargin < 2
    outFolder = strrep(binFolder, 'binary', 'MatlabClusters');
end
if nargin < 3
    countInterval = 30;
end
if nargin < 4
    % total required clicks is minClicks * countInterval
    minClicks = 5;
end
if nargin < 5
    minCorrelation = 0.85;
end
df = dir(outFolder)
if (isempty(df))
    mkdir(outFolder);
end
% tic
% clicks = loadPamguardBinaryFolder(binFolder, 'SoundTrap_Click_Detector_ST_Click_Detector_Clicks*.pgdf', 1);
% took 7.5 mins to load 3 days data of 325985, mean click rate of 1.2 per sec
% though note that first day had few clicks cos out of water. Size of
% PAMGuard files for these days is 174 MBytes and size of Matlab structures
% 1.9Gbytes.  So Matlab stuff about 10x bigger than binary files (crap!).
% conclude though that it's probably worth working through a day at a time.
%
fs = 384000;
% toc
tic
% try going through a day at a time and see if that's faster
secsPerDay = 3600*24;
[subFolds, subNames] = subfolders(binFolder);
% countMax = 100;
for i = 1:numel(subNames)
    fprintf('Processing day %d/%d folder %s\n', i, numel(subNames), subNames{i})
    % load all the clicks for one day
    someclicks = loadPamguardBinaryFolder(subNames{i}, 'SoundTrap_Click_Detector_ST_Click_Detector_Clicks*.pgdf', 1);
    dayClusterCount = 0;
    clear dayClusters;
    % histogram the number of clicks in countInterval intervals and see if this matches
    % the occurance of animals ?
    % two types classed so far, so can hist each separately.
    if isempty(someclicks)
        continue;
    end
    dayStart = floor(someclicks(1).date);
    daySecs = ([someclicks.date]-dayStart)*secsPerDay;
    dayUID = [someclicks.UID];
    % type = [someclicks.type];
    %     histogram the number of clicks per day
    hBins = [0:countInterval:secsPerDay];
    hDate = hBins/secsPerDay + dayStart;
    cBins = [0:100];
    dayClickNumber = [someclicks.clickNumber];
    dayFileNames = {someclicks.fileName};
    dayClickMillis = [someclicks.millis];
    %     for t = 0:1
    %         hDat = histc(daySecs(find(type==t)), hBins)/countInterval;
    %         figure(1)
    %         subplot(2,1,t+1)
    %         stairs(hDate, hDat);
    %         set(gca, 'yscale', 'log')
    %         datetick
    %         % now histogram the histogram
    %         cDat = histc(min(hDat,countMax), cBins);
    %         figure(2);
    %         subplot(2,1,t+1);
    %         stairs(cBins, cDat);
    %         set(gca, 'yscale', 'log')
    %     end
    % take any bin which has more than 5 clicks per second (10 per 2s bin)
    % and plot average spectra for it.
    clickCount = histc(daySecs, hBins)/countInterval;
    want = find(clickCount >= minClicks);
    fftLen = 512;
    fftLen2 = fftLen/2;
    fBins = [1:fftLen/2]*fs/fftLen;
    for w = want
        startTime = hBins(w)/secsPerDay+dayStart;
        cw = find(daySecs >= hBins(w) & daySecs < hBins(w+1));
        groupTimes = daySecs(cw); % times of these clicks within this day.
        groupUID = dayUID(cw);
        groupClickNumber = dayClickNumber(cw);
        groupClickFiles = dayFileNames(cw);
        groupClickMillis = dayClickMillis(cw);
        % look at similarities of spectra of clicks within this group to
        % see if there is more than one click type present and add each
        % separately to the classifier.
        cFFTData = zeros(numel(cw), fftLen2);
        % get the spectra of each click and also it's 50% energy length
        clickLength50 = zeros(1,numel(cw));
        clickLength80 = zeros(1,numel(cw));
        rms50 = zeros(1,numel(cw));
        rms80 = zeros(1,numel(cw));
        rmsNse = zeros(1,numel(cw));
        amp02p = zeros(1,numel(cw));
        ampp2p = zeros(1,numel(cw));
        parfor c = 1:numel(cw)
            spec = abs(fft(someclicks(cw(c)).wave, fftLen));
            cFFTData(c,:) = spec(1:fftLen2);
            cWave = someclicks(cw(c)).wave;
            [l r] = percentilelength(cWave, 50);
            clickLength50(c) = l;
            rms50(c) = r;
            [l r] = percentilelength(cWave, 80);
            clickLength80(c) = l;
            rms80(c) = r;
            rmsNse(c) = rms(cWave(1:200)); 
            amp02p(c) = max(abs(cWave));
            ampp2p(c) = max(cWave)-min(cWave);
        end
        corrMat = zeros(numel(cw));
        for m = 1:numel(cw)
            for n = m:numel(cw)
                corrMat(m,n) = corrval(cFFTData(m,:), cFFTData(n,:));
                corrMat(n,m) = corrMat(m,n);
            end
        end
        [group, gCount] = quickcluster(corrMat, minCorrelation);
        %         clus = kmeans(corrMat, 2);
        if (verbose)
            figure(5)
            clf
            allVal = reshape(corrMat, 1, numel(cw).^2);
            allVal = allVal(find(allVal>0 & allVal<1));
            corrBins = 0:.05:1;
            hc = histc(allVal, corrBins);
            stairs(corrBins,hc);
            figure(6)
            imagesc(corrMat);
            set(gca, 'clim', [0 1])
            colorbar
            corrMat
            figure(4)
            clf
            clear lgnd;
        end
        groups = unique(group);
        for ig = 1:numel(groups);
            wg = find(group == groups(ig));
            if numel(wg) >= minClicks*countInterval
                clusterTimes = groupTimes(wg);
                aveSpec = mean(cFFTData(wg,:),1);
                cluster.times = clusterTimes-hBins(w); %times relative to start in seconds. 
                cluster.start = startTime;
                cluster.clickLength50 = clickLength50(wg)/fs;
                cluster.clickLength80 = clickLength80(wg)/fs;
                cluster.rms50 = rms50(wg);
                cluster.rms80 = rms80(wg);
                cluster.aveSpec = aveSpec;
                cluster.UID = groupUID(wg);
                cluster.noise = rmsNse(wg);
                cluster.amp02p = amp02p(wg);
                cluster.ampp2p = ampp2p(wg);
                cluster.clickNumber = groupClickNumber(wg);
                cluster.fileNames = groupClickFiles(wg);
                cluster.clickMillis = groupClickMillis(wg);
                cluster.corrMatrix = corrMat(wg,wg);

                if mod(dayClusterCount,500) == 0
                    dayClusters(dayClusterCount+500) = cluster;
                end
                dayClusterCount = dayClusterCount + 1;
                dayClusters(dayClusterCount) = cluster;
            end
            if (verbose)
                plot(fBins, 20*log10(aveSpec));
                lgnd{ig} = sprintf('type %d with %d clicks', groups(ig), gCount(ig));
                hold on
            end
        end
        if (verbose)
            legend(lgnd)
            title(datestr(startTime), 31);
            ylim = get(gca, 'ylim');
            ylim(1) = ylim(2)-40;
            set(gca, 'ylim', ylim)
            figure(7)
            ici = diff(daySecs(cw));
            iciBins = 0:.005:.2;
            hICI = histc(ici, iciBins);
            stairs(iciBins, hICI);
            title(sprintf('Median ICI is %3.1fms', median(ici)*1000));
            pause()
        end
    end
    if dayClusterCount == 0
        continue;
    end
    if dayClusterCount < numel(dayClusters)
        dayClusters = dayClusters(1:dayClusterCount);
    end
    fileName = sprintf('dayclusters_%s_%ds_%d_%d_clicks.mat', subFolds(i).name, ...
        countInterval, minClicks, minCorrelation*1000);
    matName = fullfile(outFolder, fileName);
    fprintf('Writing %d cluster objects to %s\n', numel(dayClusters), matName)
    save(matName, 'dayClusters', 'fBins', '-v7.3');
end
toc
% perhaps loads a single days data a bit quicker (less in memory at a time
% and less concatonating of big arrays ?