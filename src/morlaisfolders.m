function [database, binary, clusters, erinDatabase, noise] = morlaisfolders(deployment, dataset)
% return database and folder names for morlais data for different machines
% other projects needing to do something similar should replace this file
% with a function of thier own, with whichever parameters they want to
% process thier data. It's unlikely that returned parameters such as
% 'erinDatabase' will be needed. The key ones to get are the database file,
% the binary folder and the clusters folder. 

% deployment is 1,2 (eventually 3)
% dataset is 0 - 14.
pcName = getenv('computername');
switch pcName
    case 'PC22586'
        % dougs laptop
        root = sprintf('C:\\ProjectData\\Morlais\\WP1a\\Dep%d',deployment); 
        nseRoot = sprintf('D:\\Dep%d', deployment);
%         eRoot = 'C:\ProjectData\Morlais\WP1a\ErinDatabases'; 
        eRoot = sprintf('C:\\ProjectData\\Morlais\\WP1a\\Dep%d\\ErinDatabases',deployment); 
    case 'PC26704'
        % Dougs desktop
        root = sprintf('C:\\ProjectData\\Morlais\\WP1a\\Dep%d',deployment); 
        nseRoot = root;
        eRoot = sprintf('C:\\ProjectData\\Morlais\\WP1a\\Dep%d\\ErinDatabases',deployment); 
end
database = fullfile(root, sprintf('STMORLAIS_WP1a_Dep%d_%02ddatabase.sqlite3', deployment, dataset));
binary = fullfile(nseRoot, sprintf('STMORLAIS_WP1a_Dep%d_%02dbinary', deployment, dataset));
noise = strrep(binary, 'binary', '_MatlabNoise');
clusters = fullfile(nseRoot, sprintf('STMORLAIS_WP1a_Dep%d_%02d_Matlabclusters', deployment, dataset));
erinDatabase = [];%fullfile(eRoot, sprintf('Complete_ERV_STMORLAIS_WP1a_Dep%d_%02ddatabase.sqlite3', deployment, dataset));

erinFolder = fullfile(eRoot, sprintf('MORLAIS_Dep%d_%02d', deployment, dataset));
ed = dirsub(erinFolder, '*.sqlite3');
newest = 0;
newestDate = 0;
for i = 1:numel(ed)
    % datestr(ed(i).date, 31)
    if ed(i).datenum > newestDate
        newest = i;
        newestDate = ed(i).date;
    end
end
if (newest > 0)
    erinDatabase = ed(newest).name;
end
