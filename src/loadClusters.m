function [clusters, fBins, times, uids, day] = loadClusters(matFolder, countInterval, minClicks, minCorr)
%% read in all the clicks for a particular set of clustering parameters. 
if nargin < 3
    minClicks = 10;
    if nargin < 2
        countInterval = 10;
        if nargin < 1
            matFolder = 'C:\ProjectData\Morlais\WP1a\STMORLAIS_WP1a_Dep1_00_MatlabClusters';
        end
    end
end
if nargin < 4
    minCorr = 0.85;
end

% put in some persistent memory of what was loaded last time so that data
% can be held in memory and regurgitated much more quickly on subsequent
% calls for the same dataset. 
persistent clusters_o fBins_o times_o uids_o day_o matFolder_o countInterval_o minClicks_o minCorr_o
needLoad = false;
if isempty(matFolder_o) | isempty(clusters_o)
    needLoad = true;
elseif strcmp(matFolder, matFolder_o) == 0
    needLoad = true;
elseif (countInterval ~= countInterval_o)
    needLoad = true;
elseif (minClicks ~= minClicks_o)
    nedLoad = true;
elseif minCorr ~= minCorr_o
    needLoad = true;
end
if ~needLoad
    clusters = clusters_o;
    fBins = fBins_o;
    times = times_o;
    uids = uids_o;
    day = day_o;
    return;
end

% countInterval = 10;
% minClicks = 10;
fileMask = sprintf('\\*%ds_%d_%d_clicks.mat', countInterval, minClicks, minCorr*1000);
dd = dir([matFolder, fileMask]);
clusters = [];
times = [];
uids = [];
day = [];
% loadTimes = zeros(1,numel(dd));
for i = 1:numel(dd)
    % tic
    fName = fullfile(matFolder, dd(i).name);
    load(fName);
    if exist('dayClusters')
        clusters = [clusters dayClusters];
        times = [times [dayClusters.times]];
        uids = [uids [dayClusters.UID]];
        day = [day ones(1,numel([dayClusters]))*i];
    end
    % loadTimes(i) = toc;
end
% loadTimes;
clusters_o = clusters;
fBins_o = fBins;
times_o = times;
uids_o = uids;
day_o = day;
matFolder_o = matFolder;
countInterval_o = countInterval;
minClicks_o = minClicks;
minCorr_o = minCorr;