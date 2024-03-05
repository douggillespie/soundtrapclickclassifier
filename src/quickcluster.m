function [groups counts] = quickcluster(similarity, threshold);
% input is a squr ematrix with only the upper diagonal occupied of
% similarity scores between pairs. Threshold is a minimum 
% similarity. Groups are made on any pairs having similarity withing
% threhsold, i.e. if threshold is 0.9 and A is .9 similar to B, C is 0.9
% similar to C, but only 0.8 similar to A, then A,B and C will be assigned
% to the same group. This means that groups can merge !
similarity = similarity >= threshold;
nType = size(similarity, 1);
counts = ones(1,nType);
groups = 1:nType; % start with everything in a different group
nGroups = 1;
for m = 1:nType
    for n = m+1:nType
        if (similarity(m,n)) 
            % is n already in an existing group ?
            nGroup = groups(n);
            mGroup = groups(m);
%             if (nGroup & ~mGroup) 
%                 groups(m) = nGroup;
%             elseif (~nGroup & mGroup)
%                 groups(n) = mGroup;
%             elseif (mGroup & nGroup)
%                 % assign everything in group n to group m
                groups(groups == nGroup) = mGroup;
%             else 
%                 % new group
%                 nGroups = nGroups + 1;

%             end
        end
    end
end
% shrink the values down to a minimum set
uVals = unique(groups);
if numel(uVals) < nType
    counts = zeros(1,numel(uVals));
    for i = 1:numel(uVals)
        same = find(groups == uVals(i));
        groups(same) = i;
        counts(i) = numel(same);
    end
    % Then finally sort it so that the biggest group is first.
    [counts ord] = sort(counts, 'descend');
    oldgroup = groups;
    for i = 1:numel(counts)
        groups(oldgroup == ord(i)) = i;
    end
end

