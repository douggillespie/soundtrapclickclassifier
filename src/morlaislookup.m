function morlaislookup(dbName)
% check lookup table in database has all we need for morlais
colNames = {'Id', 'Topic', 'DisplayOrder', 'Code', ...
    'ItemText', 'isSelectable', 'FillColour', 'BorderColour', 'Symbol'};
colTypes = {'INTEGER', 'CHAR(50)', 'INTEGER', 'CHAR(12)', ...
    'CHAR(50)', 'BIT', 'CHAR(20)', 'CHAR(20)', 'CHAR(2)'};
symbols = 'osd^vph' % single character symbols.
colours = round([0    0.4470    0.7410
    0.8500    0.3250    0.0980
    0.9290    0.6940    0.1250
    0.4940    0.1840    0.5560
    0.4660    0.6740    0.1880
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840]*255);
spCodes = {'HP', 'RD', 'DO', 'UNK', 'RDcEv', 'RDpEv', 'DcEv', 'DpEv', 'O'};
spNames = {'Harbour Porpoise', 'Rissos Dolphin', 'Dolphin', 'Unknown', ...
    'Rissos dolphin certain', 'Rissos dolphin possible', 'BND/Cd certain', ...
    'BND/CD possible', 'Other'};
tableName = 'Lookup';
con = sqlitedatabase(dbName);
checkTable(con, tableName, true);
for i = 1:numel(colNames)
    checkColumn(con, tableName, colNames{i}, colTypes{i});
end
% need the max id of the table
exec(con, 'DELETE FROM Lookup');
% qStr = 'SELECT max(Id) AS maxId FROM Lookup';
% q = exec(con, qStr);
% q = fetch(q);
% if rows(q) == 1
%     maxId = d.maxId;
% else
   maxId = 0;
% end
for i = 1:numel(spCodes)
    % see if it exists.
    qStr = sprintf('SELECT * FROM %s WHERE TRIM(Code)=''%s''', tableName, spCodes{i});
    q = exec(con, qStr);
    q = fetch(q);
    % if rows(q) > 0
    %     continue;
    % end
    % else insert the row
    maxId = maxId+1;
    data{1} = maxId;
    data{2} = 'OfflineRCEvents';
    data{3} = i*10;
    data{4} = spCodes{i};
    data{5} = spNames{i};
    data{6} = 1;
    colInd = mod(i, size(colours,1))+1;
    data{7} = sprintf('RGB(%d,%d,%d)', colours(colInd,1),colours(colInd,2),colours(colInd,3));
    data{8} = data{7}
    symind = mod(i, length(symbols))+1;
    data{9} = symbols(symind);
    insert(con, tableName, colNames, data)
end
close(con)