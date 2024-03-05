function [subs, names] = subfolders(root)
% list sub folders only
dd = dir(root);
isfolder = [dd.isdir];
isup = zeros(1,numel(isfolder));
for i = 1:numel(isup)
    name = dd(i).name;
    isup(i) = strcmp(name,'.') || strcmp(name,'..');
end
subs = dd(~isup & isfolder);
if nargout == 2
    names = cell(numel(subs),1);
    for i = 1:numel(subs)
        names{i} = [subs(i).folder '\' subs(i).name];
    end
end