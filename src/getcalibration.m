function cal = getcalibration(cycle, station)
% get calibrartion data. This function is very focussed
% around some Morlais data and will need to be replaced by anyone using a
% different dataset. 
dbName = 'C:\Users\dg50\OneDrive - University of St Andrews\Turbines\Morlais\WP1\Deployment\MasterDocs\MorlaisSTMasterAll.sqlite3';
con = sqlite(dbName);
qStr = sprintf(['SELECT HighGain, LowGain FROM Calibration INNER JOIN MorlaisWP1_22_23 ON Calibration.Instrument ' ...
    '= MorlaisWP1_22_23.Instrument WHERE MorlaisWP1_22_23.Cycle=%d AND MorlaisWP1_22_23.Station=%d'], ...
    cycle, station);
% q1 = sprintf(['SELECT Instrument FROM MorlaisWP1_22_23 WHERE Cycle=%d AND Station=%d'], ...
%     cycle, station);
% execute(con, qStr);
cal = fetch(con, qStr);
close(con)

