function [class1 class2 class3] = classifyparams(clusterParams)
% run the classifier on the parameters pulled out of classifyclusters

class1 = zeros(1, size(clusterParams,1));
class1(find(clusterParams(:,5)>7.5)) = 1; % porpoise
possPorp = (clusterParams(:,5)>7.5 | clusterParams(:,2)>0.9);
class1(find(clusterParams(:,1)>0.88 & clusterParams(:,7)>9 & possPorp == 0)) = 2; % all dolphins
class1(find(clusterParams(:,1)>0.88 & clusterParams(:,7)>9 & clusterParams(:,6)>1.3 & possPorp == 0)) = 3; % rissos

class2 = zeros(1,size(clusterParams,1));


nClick0 = 50;
nClick1 = 10;
mCorr0 = 0.86;
mCorr1 = 0.99;
b = (nClick0-nClick1)/(mCorr0-mCorr1);
a = nClick1-b*mCorr1;
y= a+clusterParams(:,9)*b;
isDo = clusterParams(:,8)>y;
keep = possPorp | isDo;
keep = keep';
class2 = class1.*keep;
sum(class2>1);

% try system 3 which may work better with the new >0.9 score in the
% correlation. The mean correlatoin itself is no longer useful. 
lnClicks0 = 1;
lnClicks1 = 2.5;
dol0 = .5;
dol1 = 1.0;
b = (lnClicks1-lnClicks0)/(dol1-dol0);
a = lnClicks1-b*dol1;
lnClicks = log10(clusterParams(:,8));
dolCorr = clusterParams(:,1);
y = a+dolCorr*b;
isDo = lnClicks<=y; % less than - we want stuff to the right !


class3 = zeros(1, size(clusterParams,1));
class3(find(clusterParams(:,5)>7.5)) = 1; % porpoise
possPorp = (clusterParams(:,5)>7.5 | clusterParams(:,2)>0.9);
class3(find(isDo & possPorp == 0)) = 2; % all dolphins
class3(find(class3' == 2 & clusterParams(:,6)>1.3 & possPorp == 0)') = 3; % rissos

% keep = possPorp | isDo;
% keep = keep';
% class3 = class1;
% class3(find(keep)) = 1;
% class3 = class3.*keep;

