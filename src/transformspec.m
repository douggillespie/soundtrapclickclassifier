function tSpec = transformspec(spec)
% simple transform of a spectrum prior to correlation with another. 
maxdB = 25;
tSpec = (spec/max(spec)).^2;
% tSpec = 20*log10(tSpec)+maxdB;
% tSpec = max(tSpec,0);