% classify all clusters in all databases. This probably needs a fair amount
% of work to loop through data more sensibly since it's currently quite
% dependent on how data from a particular monitoring project have been
% organised. 
sets = 0:14
stationCount = zeros(1,numel(sets));
for deployment = 1
    for i = 1:numel(sets)
        [dbName, ~, matName] = morlaisfolders(deployment, sets(i));
        calTable = getcalibration(deployment, sets(1));
        cal = calTable.HighGain;
        classifyandwrite(dbName, matName, cal);
        break
    end
end
