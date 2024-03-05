function reg = getregularity(t, echotime)
% make a measure of regularity of clicks in a sequence
if nargin < 2
    echotime = 0.025;
end
isEcho = [0 diff(t) < echotime];
isClick = find (isEcho==0);
clickTimes = t(isClick);
clickICI = diff(clickTimes);
nCh = numel(clickICI)-2;
irreg = zeros(1,nCh);
% irregularity is the difference between adjacent ICIs
for i = 1:nCh
    t1 = clickICI(i+2)-clickICI(i+1);
    t2 = clickICI(i+1)-clickICI(i);
    irreg(i) = abs(t2-t1)/clickICI(i+1);
end
reg = irreg;