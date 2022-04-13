function [percentTime] = MOScalc(XCOM,lBOS,rBOS, hs, rhs, lhs)
% function to calculate two new measures from marginal stability analysis.
% Mos analysis should be done before using this function
% INPUTS:
% XCOM: time series of extrapolated center of mass in ML direction
% lBOS: time series of ML coordinate of left base of support, e.g. left ankle or left
%       lateral foot marker.
% rBOS: time series of f ML coordinate of right base of support, e.g. right ankle or right
%       lateral foot marker.
% OUTPUTS:
% nCross: number of times XCOM went beyond BOS either in left or right side
% percentTime: percent of time that XCOM was out of BOS either in left or
%              right side

                        % !!! WARNING !!!
% this code is written for AMBIENT project and based on its time series.
% For other time series code might be needed to be revised.
%--------------------------------------------------------------------------
% j = 1;
% nCross = 0;
% for i = 1:length (XCOM) - 1
%     if (XCOM(i) < rBOS(i)) && (XCOM(i+1) > rBOS(i))
%         nCross = nCross + 1;
%         crosspoint(j) = i;
%         j = j + 1;
%     elseif (XCOM(i) > lBOS(i)) && (XCOM(i+1) < lBOS(i))
%         nCross = nCross + 1;
%         crosspoint(j) = i;
%         j = j + 1;
%     end
% end

rBey0 = XCOM - rBOS;
%rBey = length(rBey0(rBey0 < 0));

lBey0 = XCOM - lBOS;
%lBey = length(lBey0(lBey0 > 0));

jj = 1;
kk = 1;
for i = 1:length(hs) - 1
    if ismember(hs(i),rhs)
        rBey1 = rBey0((hs(i):hs(i+1)));
        rBey2 = rBey1(rBey1 < 0);
        rBey_length(jj) = length(rBey2);
    elseif ismember(hs(i),lhs)
        lBey1 = lBey0((hs(i):hs(i+1)));
        lBey2 = lBey1(lBey1 > 0);
        lBey_length(kk) = length(lBey2);
    end
end

if exist('rBey_length')
    rBey_tot = sum(rBey_length);
else
    rBey_tot = 0;
end

if exist('lBey_length')
    lBey_tot = sum(lBey_length);
else
    lBey_tot = 0;
end

percentTime = ((rBey_tot + lBey_tot)*100)/length(XCOM);

% j = 1;
% nCross = 0;
% crosspoint = [];
% for i = 1: length(rBey0) - 1
%     if rBey0(i) > 0 && rBey0(i+1) < 0 
%         nCross = nCross + 1;
%         crosspoint(j) = i+1;
%         j = j + 1;
%     elseif lBey0(i) < 0 && lBey0(i+1) > 0
%         nCross = nCross + 1;
%         crosspoint(j) = i+1;
%         j = j + 1;
%     end
% end
% %%%%
% t = 1:length(XCOM);
% figure
% hold on
% plot(t,XCOM);
% plot(t,rBOS,'r');
% plot(t,lBOS,'k');
% plot(t(1),rBOS(1),'ro');
% plot(t(1),lBOS(1),'ko');
% 
% if ~ isempty(crosspoint)
% plot(t(crosspoint),XCOM(crosspoint),'*k')
% end
% 
% title('XCOM,rBOS,lBOS');
end