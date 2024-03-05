function gathernoise(binFolder, outFolder, countInterval)
% function to gather noise metrics from soundtrap data. 
if nargin < 3
    countInterval = 60;
end
if nargin < 1
[dbName binFolder] = morlaisfolders(1,0);
end
if nargin < 2
    outFolder = strrep(binFolder, 'binary', '_MatlabNoise');
end

fd = dir(outFolder)
if isempty(fd)
    mkdir(outFolder);
end

noiseSamples = 192;
metrics = {'start', 'end', 'nClicks', 'noiseMean', 'noiseSTD', 'noiseMin', 'noise5', 'noise50', 'noise95', 'noiseMax', ...
    'signalMean', 'signalSTD', 'signalMin', 'signal5', 'signal50', 'signal95', 'signalMax'};

secsPerDay = 3600*24;
dayInterval = countInterval/secsPerDay;
[subFolds, subNames] = subfolders(binFolder);
% countMax = 100;
for i = 1:numel(subNames)
    fprintf('Processing day %d/%d folder %s\n', i, numel(subNames), subNames{i})
    % load all the clicks for one day
    someclicks = loadPamguardBinaryFolder(subNames{i}, 'SoundTrap_Click_Detector_ST_Click_Detector_Clicks*.pgdf', 1);
    if isempty(someclicks)
        continue
    end
    clickDate = [someclicks.date];
    startDate = floor(min(clickDate)/dayInterval) * dayInterval;
    endDate = ceil(max(clickDate)/dayInterval) * dayInterval;
    dateBins = startDate:dayInterval:endDate;
    noiseData = zeros(numel(dateBins)-1,numel(metrics));
    for b = 1:numel(dateBins)-1
        cis = find(clickDate>=dateBins(b) & clickDate < dateBins(b+1));
        noiseData(b,1) = dateBins(b);
        noiseData(b,2) = dateBins(b+1);
        noiseData(b,3) = numel(cis);
        if numel(cis) == 0
            continue;
        end
        noiseVals = zeros(1,numel(cis));
        sigVals = zeros(1,numel(cis));
        parfor c = 1:numel(cis)
            w = someclicks(cis(c)).wave;
            noiseVals(c) = std(w(1:noiseSamples)); % rms of presample
            sigVals(c) = max(w)-min(w); % peak to peak of entire signal
        end
        noiseData(b,4:10) = getMetrics(noiseVals);
        noiseData(b,11:17) = getMetrics(sigVals);
    end
    % now save it. Do as raw data, probably faster than a table. 

    fileName = sprintf('daynoise_%s_%ds.mat', subFolds(i).name, countInterval);
    matName = fullfile(outFolder, fileName);
    fprintf('Writing noise data to %s\n', matName)
    save(matName, 'metrics', 'noiseData');
end

function metrics = getMetrics(levels)
% metrics for noise or signal are 
% 'noiseMean', 'noiseSTD', 'noiseMin', 'noise5', 'noise50', 'noise95', 'noiseMax'
n = numel(levels);
metrics = zeros(1,7);
if n == 0
    return;
end
metrics(1) = mean(levels);
metrics(2) = std(levels);
metrics(3) = min(levels);
metrics(7) = max(levels);
ords = [5 50 95];
levels = sort(levels);
pos = round(n*ords/100);
pos = max(pos,1);
pos = min(pos,n);
metrics(4:6) = levels(pos);