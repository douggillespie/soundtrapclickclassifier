% call the clusterclicks function for all 15 datasets. 
% intvals = [10 30]
% counts = [2 10 5];

intvals = 10;
counts = 1;
deployment = 1;

% set up this loop to go through your data, however your data are arranged.
% For my set, I had two parameters defining a dataset, a deployment number
% and a station number. Anyone else using this will need to replace this
% function to get a database name and a binary folder whichever way they
% need to. 
for deployment = 3
for ii = 1:numel(intvals)
    for ic = 1:numel(counts)
        for i = [0:14]
            [dbName, binFolder] = morlaisfolders(deployment, i);
            outFolder = strrep(binFolder, 'binary', '_MatlabClusters');
            clusterclicks(binFolder, outFolder, intvals(ii), counts(ic), 0.9);
        end
    end
end
end