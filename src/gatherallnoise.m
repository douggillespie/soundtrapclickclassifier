for depl = 3
    for i = [0:14]
        [dbName, binFolder] = morlaisfolders(depl, i);
        noiseFolder = strrep(binFolder, 'binary', '_MatlabNoise');
        fprintf('%s to %s\n', binFolder, noiseFolder);
        gathernoise(binFolder, noiseFolder, 60);
    end
end