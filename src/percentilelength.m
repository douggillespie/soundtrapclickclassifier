function [len, rmsLev] = percentilelength(wave, percent)
% get the length as the length of middle part that gts us from
% (1-percent)/2 to .5+p/2
% get the rms in that range too while we're here. 
if nargin < 2
    percent = 50;
end
if percent > 1
    percent = percent/ 100;
end
w = cumsum(wave.^2);
w = w./w(end);
a = .5-percent/2;
b = .5+percent/2;
cBins = find(w>=a & w<=b);
len = numel(cBins);
rmsLev = rms(wave(cBins));

