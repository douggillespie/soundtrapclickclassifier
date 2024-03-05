function [clusterSpecies clusters classParams classNames] = ...
    classifyclusters(matFolder, countInterval, minClicks, minCorrelation)
% apply average cluster spectra to crudely classify clusters from other
% soundtraps into dolphin, noise and porpoise.
% input
% matFolder = folder containing matlab clusters generated with
% clusterclicks
% countinterval = same count interval as was passed to clusterclicks
% minClicks = minimum clicks per second (same as passed to clusterclicks)
% minCorrelation value (same as passed to clusterclicks)
% these last three params are to identify data in the loadClusters function
% in cases where clusterclicks was run with a range of parameters. 

if isstruct(matFolder)
    allclusters = deployment;
    fBins = dataset;
else
    if nargin < 1
        [~, ~, matFolder] = morlaisfolders(1, 0);
    end
    if nargin < 2
        countInterval = 10;
    end
    if nargin < 3
        minClicks = 5;
    end
    if nargin < 4
        minCorrelation = 0.9;
    end
    % if isempty(fBins)
    %     lastdataset = -1;
    %     lastInterval = -1;
    %     lastMinClicks = -1;
    % end
    % countInterval = 10;
    % minClicks = 5;
    % dataset = 0;
    % matFolder = sprintf('C:\\ProjectData\\Morlais\\WP1a\\STMORLAIS_WP1a_Dep1_%02d_MatlabClusters', dataset);
    % dbName = sprintf('C:\\ProjectData\\Morlais\\WP1a\\ErinDatabases\\Complete_ERV_STMORLAIS_WP1a_Dep1_%02ddatabase.sqlite3', dataset);
    % [dbName, binary, matFolder, erinDatabase] = morlaisfolders(deployment, dataset);

    tic
    fprintf('loading clusters')
    % if  lastdataset ~= dataset | lastInterval ~= countInterval | lastMinClicks ~= minClicks
    [allclusters, fBins, times, uids, day] = loadClusters(matFolder, countInterval, minClicks, minCorrelation);
    %     lastdataset = dataset;
    %     lastMinClicks = minClicks;
    %     lastInterval = countInterval;
    % end
end

load AveDolphin.mat
avePorpoise = classSpec(6,:);
usedSpecs = [aveDolphin; avePorpoise];
% usedSpecs = [classSpec(1,:); classSpec(4,:); classSpec(6,:)];

fprintf(' took %3.1fs\n', toc);
tic
clusters = allclusters;
% fprintf('joining clusters')
% clusters = joinclusters(allclusters);
% fprintf(' took %3.1fs\n', toc);

%clusters = allclusters;
clusterStarts = [clusters.start];
clusterSpecies = zeros(1,numel(clusters));

tic
%% make some variables to classify on
classNames = {'Dolphin',  'Porpoise', 'SNR', 'ICIVar', 'Porpy', 'Rissoy', 'Dolphiny', ...
    'nClicks', 'Mean corr', 'Modal ICI', 'MeanLen80'};
classParams = zeros(numel(clusters),numel(classNames));
% added the second row of parameters for better classifier 4.10.23



% first two columns are correlation coefficients with the usedSpecs
usefulBins{1} = 1:length(fBins);
% usefulBins{2} = 1:100;
usefulBins{2} = 27:length(fBins);
nCorr = 2;
for s = 1:nCorr
    % try on a log scale, but with limited dynamic range so that the
    % smaller values don't dominate.
    tstSpec = (usedSpecs(s,usefulBins{s}));
    tstSpec = transformspec(tstSpec);
    for c = 1:numel(clusters)
        cSpec = transformspec(clusters(c).aveSpec(usefulBins{s}));
        classParams(c,s) = corrval(tstSpec, cSpec);
    end
end
% and some other stuff for each cluster
% SNR
guardBins = find(fBins > 70000 & fBins < 100000 | fBins > 150000 & fBins < 210000);
testBins = find(fBins>100000 & fBins < 150000);
dGuardBins = find(fBins > 0 & fBins < 20000 | fBins > 80000 & fBins < 150000);
dTestBins = find(fBins > 25000 & fBins < 70000);
iciBins = [0:.01:2];
for c = 1:numel(clusters)
    aClus = clusters(c);
    snr = (20*log10(aClus.rms50./aClus.noise));
    classParams(c,nCorr+1) = median(snr);
    % ampli = 20*log10(rms(clusters(c).rms50));
    % ici = diff(clusters(c).times);
    % iciHist = histc(ici, iciBins);
    % [dum maICI] = max(iciHist);
    % modalICI = iciBins(maICI)+rand(1)*iciStep;
    % classParams(c,4) = dum/numel(ici);
    irreg = getregularity(aClus.times, .05);
    classParams(c,nCorr+2) = min(median(irreg),2);
    s2 = clusters(c).aveSpec.^2;
    tst = sum(s2(testBins))/numel(testBins);
    grd = sum(s2(guardBins))/numel(guardBins);
    classParams(c,nCorr+3) = 10*log10(tst/grd);
    %% broad scale correlation of DO and RD spectra are very similar.
    % More difference in the diff of them though ....
    ds = diff(10*log10(s2));
    classParams(c,nCorr+4) = std(ds(30:90));
    tst = sum(s2(dTestBins))/numel(dTestBins);
    grd = sum(s2(dGuardBins))/numel(dGuardBins);
    classParams(c,nCorr+5) = 10*log10(tst/grd);

    classParams(c,nCorr+6) = numel(aClus.times);

    % now the new params of correlationness, etc.
    corrMat = aClus.corrMatrix;
    corrSz = size(corrMat,1);
    corr5 = zeros(1,corrSz);
    for j = 1:size(corrMat,1)
        corrMat(j,j) = 0;
        corrRow = corrMat(j,:);
        corrRow = sort(corrRow);
        corr5(j) = corrRow(end-5);
    end
    classParams(c,nCorr+7) = mean(max(corrMat));


    ici = diff(aClus.clickMillis) / 1000.;
    iciH = histc(ici, iciBins);
    [~ ,maxBin] = max(iciH);
    classParams(c, nCorr+8) = iciBins(maxBin);

    classParams(c, nCorr+9) = mean(aClus.clickLength80);



end


if (false) % only if we have a database with some truth in it!
    %% label the clusters with truth if possible.
    [clusterType, clusterName, evTypes, eventClusters] = labelclusters(erinDatabase, clusterStarts);
    % reduce to two or three categories
    newName = clusterName;
    toChange = {'DcEv', 'DpEv'};
    for t = 1:numel(toChange)
        toCh = find(strcmp(clusterName, toChange{t}));
        for t2 = 1:numel(toCh)
            newName{toCh(t2)} = 'DO';
        end
    end
    toChange = {'RDcEv', 'RDpEv'};
    for t = 1:numel(toChange)
        toCh = find(strcmp(clusterName, toChange{t}));
        for t2 = 1:numel(toCh)
            newName{toCh(t2)} = 'RD';
        end
    end
    % newName{find(strcmp(clusterName, 'RDcEv'))} = 'DO';
    % newName{find(strcmp(clusterName, 'RDpEv'))} = 'DO';
    % newName{find(strcmp(clusterName, 'DcEv'))} = 'DO';
    % newName{find(strcmp(clusterName, 'DpEv'))} = 'DO';
    newclasses = unique(newName);

    [gpm, gpmax] = gplotmatrix(classParams, [], newName', [], 'o', 2, true, 'stairs', classNames);
else
    % [gpm, gpmax] = gplotmatrix(classParams, [], []', [], 'o', 2, true, 'stairs', classNames);
end
% for i = 1:size(classParams,2)
%     set(gpm(i,i),'linewidth',2)
% end
% for i = 1:numel(gpmax)
%     gpmax(i).XGrid = 'on';
%     gpmax(i).YGrid = 'on';
% end
pause(0.1);

% % take a look at some spectra in marginal categories.
% % 0.85 seems like a really good cut off for porpoise clicks.
% figure(3)
% clf
% goodness = classParams(:,2);
% marginal = find(goodness > 0.85 & goodness < 0.9 & classParams(:,4) > 10);
% marginal = find(classParams(:,4) >2 & classParams(:,4) < 4 & goodness > 0.85);
% for i = marginal'
%     figure(3)
%     clf
%     plot(fBins, 20*log10(clusters(i).aveSpec));
%     hold on
%     plot(fBins, 20*log10(avePorpoise));
%     tit = sprintf('%s, corr %3.3f, porp %3.1fdB', datestr(clusters(i).start, 31), goodness(i), classParams(i,4))
%     title(tit)
%     pause
% end

% happy with porpoise corr > 0.85, so selest that and be done.
% clusterSpecies(find(classParams(:,2)>0.85)) = 1; % porpoise
% clusterSpecies(find(classParams(:,1)>0.95)) = 2; % all dolphins
% clusterSpecies(find(classParams(:,6)>1.3 & clusterSpecies' == 2)) = 3; % rissos

% this is the classifiction that was first used to generate a dataset in  
% July/August 2023, which gets a fair number of false positives for much of
% the data, but be wary of loosening these criteria - preference is to
% tighten them if at all possible. 
clusterSpecies = zeros(1, numel(allclusters));
clusterSpecies(find(classParams(:,5)>7.5)) = 1; % porpoise
possPorp = (classParams(:,5)>7.5 | classParams(:,2)>0.9);
clusterSpecies(find(classParams(:,1)>0.88 & classParams(:,7)>9 & possPorp == 0)) = 2; % all dolphins
clusterSpecies(find(classParams(:,1)>0.88 & classParams(:,7)>9 & classParams(:,6)>1.3 & possPorp == 0)) = 3; % rissos

fprintf('Running classifiers took %3.1fs\n', toc);

