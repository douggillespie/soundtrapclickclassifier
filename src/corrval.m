function c = corrval(f1, f2, b1, b2)
% returns correlation of f1 and f2 between bins b1 and b2
if nargin < 4
    b2 = length(f1);
    if nargin < 3
        b1 = 1;
    end
end
if (b1 > 1 || b2 < length(f1))
    f1 = f1(b1:b2);
    f2 = f2(b1:b2);
end
c = sum(f1.*f2)/(sqrt(sum(f1.^2))*sqrt(sum(f2.^2)));