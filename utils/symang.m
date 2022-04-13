function sa = symang(x1,x2)
% function to calculate symmetry angle
% Reference: https://doi.org/10.1016/j.gaitpost.2007.08.006

a = 45 - ((atan2(x1,x2))*180)/pi;

if a < 90
    sa = (a / 90) * 100;
elseif a > 90
    sa = ((a - 180) / 90) * 100;
end
end