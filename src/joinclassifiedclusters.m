function [jclusters, clusterSpecies,clusterStartInds] = joinclassifiedclusters(clusters, clustertypes, maxSep)
% join clusters together that are close in time and of the same type. This
% is similar to joinclusters, but is designed to run AFTER classification

if nargin < 3
    % not that cluster end time not stored, so this is between start of a cluster
    % and last click of preceeding cluster.
    maxSep = 60;
end
secsPerDay = 3600*24;
dayGap = maxSep/secsPerDay;
jclusters(1) = clusters(1);
clusterSpecies = zeros(1,numel(clusters));
clusterStartInds = zeros(1,numel(clusters));
clusterSpecies(1) = clustertypes(1);
jclusters(numel(clusters)) = clusters(1);

nJoin = 0;
% jclusters ia a list of joined together clusters. Initialised with the
% first cluster.
for i = 1:numel(clusters)
    % for each cluster, go back trhough the joined clusters and see if
    % the new cluster matches up with a close existing one. If it does
    % then store the index of the joined cluster in variable 'join'
    % if clusters(i).start > datenum(2022,12,1,20,50,18) 
    %     clustertypes(i)
    % end
    join = 0;
    for j = nJoin:-1:1
        jEnd = jclusters(j).start + jclusters(j).times(end)/secsPerDay;
        if (clustertypes(i) == clusterSpecies(j))
            if (clusters(i).start-jEnd > dayGap)
                % gone too far back, so give up. However, there may be other
                % clusters that started earlier soonly breaking if it's the
                % same type. 
                break;
            else
                join = j;
                break;
            end
        end
    end
    if (join > 0)
        % add the new cluster to the existing joined cluster.
        ni = numel(clusters(i).times);
        nj = numel(jclusters(join).times);
        jclusters(join).aveSpec = (jclusters(join).aveSpec*nj + clusters(i).aveSpec*ni)/(ni+nj);
        tOff = (clusters(i).start-jclusters(join).start)*secsPerDay;
        jclusters(join).times = [jclusters(join).times clusters(i).times+tOff];
        jclusters(join).clickLength50 = [jclusters(join).clickLength50 clusters(i).clickLength50];
        jclusters(join).clickLength80 = [jclusters(join).clickLength80 clusters(i).clickLength80];
        jclusters(join).rms50 = [jclusters(join).rms50 clusters(i).rms50];
        jclusters(join).rms80 = [jclusters(join).rms80 clusters(i).rms80];
        jclusters(join).UID = [jclusters(join).UID clusters(i).UID];
        jclusters(join).noise = [jclusters(join).noise clusters(i).noise];
        jclusters(join).clickNumber = [jclusters(join).clickNumber clusters(i).clickNumber];
        jclusters(join).fileNames = [jclusters(join).fileNames clusters(i).fileNames];
        jclusters(join).clickMillis = [jclusters(join).clickMillis clusters(i).clickMillis];
        jclusters(join).amp02p = [jclusters(join).amp02p clusters(i).amp02p];
        jclusters(join).ampp2p = [jclusters(join).ampp2p clusters(i).ampp2p];
    else
        % make a new cluster in the joined cluster list.
        nJoin = nJoin+1;
        jclusters(nJoin) = clusters(i);
        clusterSpecies(nJoin) = clustertypes(i);
        clusterStartInds(nJoin) = i;
    end

end
jclusters = jclusters(1:nJoin);
clusterSpecies = clusterSpecies(1:nJoin);
clusterStartInds = clusterStartInds(1:nJoin);
