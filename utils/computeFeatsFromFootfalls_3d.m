function [out_final] = computeFeatsFromFootfalls_3d(skelT, skel_struct, footfall_locs_final, start_is_left, additional_info)
% This function is adapted from Sina's work (SM_GaitFeatures.m)
if nargin < 5
    fps = 30;
    mult_factor = 1;
else
    fps = additional_info.fps;
    mult_factor = additional_info.mult_factor;
end

out_final = NaN * zeros(1, 22); 

if start_is_left
    rhs = footfall_locs_final(2:2:end);
    lhs = footfall_locs_final(1:2:end);

else
    rhs = footfall_locs_final(1:2:end);
    lhs = footfall_locs_final(2:2:end);
end

%% PART 2: CALCULATING GAIT SPATIOTEMPORAL VARIABLES


%
hs0 = [rhs,lhs]; % pooled right and left heel strike
hs = sort(hs0);  % hs sorted from first to last

if length(hs) <= 2
    return
end
%-------------------------------
% step time
steptime = diff(hs)/fps; % step times
steptime_mean = mean(steptime);

% right and left step times
if length(steptime) > 1
    if hs(1) == rhs(1)
        rsteptime = steptime(2:2:end);
        lsteptime = steptime(1:2:end);
    elseif hs(1) == lhs(1)
        rsteptime = steptime(1:2:end);
        lsteptime = steptime(2:2:end);
    end
else
    rsteptime = steptime;
    lsteptime = steptime;
end
%-----------------------------------
% step length and width
% Guide: 
% ML = x, VT = y, AP = z
rankAPidx = skel_struct.RAnkle(rhs, 3) * mult_factor;
lankAPidx = skel_struct.LAnkle(lhs, 3) * mult_factor;

rankMLidx = skel_struct.RAnkle(rhs, 1) * mult_factor;
lankMLidx = skel_struct.LAnkle(lhs, 1) * mult_factor;

right = [rhs', rankAPidx, rankMLidx];
left = [lhs', lankAPidx, lankMLidx];

rl = [right;left]; % R and L hs together
rlsorted = sortrows(rl); % sorting from first step to last 
stepLengthAndWith = abs(diff(rlsorted)); % colomn 2 is length and 3 is width

% step length 
steplength = stepLengthAndWith(:,2);
steplength_mean = mean(steplength);

% step width 
stepwidth = stepLengthAndWith(:,3);
stepwidth_mean = mean(stepwidth);

% separating right and left step length and width
if length(steptime) > 1
    if hs(1) == rhs(1)
        rsteplength = steplength(2:2:end);
        lsteplength = steplength(1:2:end);
        rstepwidth = stepwidth(2:2:end);
        lstepwidth = stepwidth(1:2:end);
    
    elseif hs(1) == lhs(1)
        rsteplength = steplength(1:2:end);
        lsteplength = steplength(2:2:end);
        rstepwidth = stepwidth(1:2:end);
        lstepwidth = stepwidth(2:2:end);
    end
else
    rsteplength = steplength;
    lsteplength = steplength;
    rstepwidth = stepwidth;
    lstepwidth = stepwidth;
end
%--------------------------------------

% walking speed
try
    sacrAP = skel_struct.MidHip(:, 3) * mult_factor;
catch
    sacrAP = skel_struct.Sacr(:, 3) * mult_factor; % From kinect
end
walkingspeed = abs((sacrAP(end) -sacrAP(1))/(length(sacrAP)/fps));
%---------------------------------------

% cadence (no. of steps per minute)
nsteps = length(hs) - 1; % no of steps is no of heel strikes minue one
ts = length(skel_struct.RAnkle(hs(1):hs(end)))/fps; % time in seconds
cadence = (nsteps/ts)*60; % cadance is steps per minute
%---------------------------------

%% PART 3: CALCULATING GAIT SYMMETRY
% symmetry angle
% Uses: the function symang.m
for i = 1:min(length(rsteptime),length(lsteptime))
    symStepLength0(i) = abs(symang(rsteplength(i),lsteplength(i))); % for step length
    symStepWidth0(i) = abs(symang(rstepwidth(i),lstepwidth(i))); % for step width
    symSteptime0(i) = abs(symang(rsteptime(i),lsteptime(i))); % for step time 
end
symStepLength = mean(symStepLength0);
symStepWidth = mean(symStepWidth0);
symSteptime = mean(symSteptime0);
%--------------------------------------------------------------------------
%% PART 4: CALCULATING GAIT VARIABILITY  
% spatio-temporal
sdSteptime = std(steptime); % standard deviation 
cvSteptime = sdSteptime/mean(steptime); % coefficient of variation

sdSteplength = std(steplength); % standard deviation 
cvSteplength = sdSteplength/mean(steplength); % coefficient of variation

sdStepwidth = std(stepwidth); % standard deviation 
cvStepwidth = sdStepwidth/mean(stepwidth); % coefficient of variation

% sacrum rms in ML direction
try
    sacrML = skel_struct.MidHip(:, 1);
catch
    sacrML = skel_struct.Sacr(:, 1);
end
sdSacrML = std(sacrML); % position
rmsSacrMLvel = rms(diff(sacrML)*fps); % velocity

% sacrum range of motion in ML direction
romSacrML = max(sacrML) - min(sacrML);
%-------------------------------------------------------------------------
%% PART 5: STABILITY MEASURES

% Margin stability in ML direction

%% temporary
clear rleg0 rleg lleg0 lleg
%--------------------------------------------------------------------------
%% leg length
right_leg_length = vecnorm(skel_struct.RHip - skel_struct.RAnkle, 2,2);
left_leg_length = vecnorm(skel_struct.LHip - skel_struct.LAnkle, 2,2);
% right leg length
for i = 1:length(rhs)
    rleg0(i) = right_leg_length(rhs(i));
%     rleg0(i) = sqrt((rhipAP(rhs(i)) - rankAP(rhs(i)))^2 + (rhipML(rhs(i)) - rankML(rhs(i)))^2 + (rhipVT(rhs(i)) - rankVT(rhs(i)))^2);
end
rleg = mean(rleg0);

% lefth leg length
for i = 1:length(lhs)
    lleg0(i) = left_leg_length(lhs(i));
    
    %     lleg0(i) = sqrt((lhipAP(lhs(i)) - lankAP(lhs(i)))^2 + (lhipML(lhs(i)) - lankML(lhs(i)))^2 + (lhipVT(lhs(i)) - lankVT(lhs(i)))^2);
end
lleg = mean(lleg0);

leg = mean([rleg,lleg]); % leg length is the average of R and L leg length

%% XCOM
omega = sqrt(9.81/leg); % omega

vsacrML = diff(sacrML) * fps; % sacrML velocity
vsacrML(end + 1) = vsacrML(end); % increasing its size by one

XCOMML = sacrML + vsacrML/omega; % extrapolated center of mass in ML
%--------------------------------------------------------------------------
%% just plotting
rankML = skel_struct.RAnkle(:, 1);
lankML = skel_struct.LAnkle(:, 1);
t = 1:length(rankML);
% 
% figure
% plot(t,rankML,'r')
% hold on
% plot(t,lankML,'k','LineWidth',2)
% plot(t,XCOMML,'LineWidth',2)
% 
% for ii = 1:length(hs) - 1
%     if ismember(hs(ii),rhs)
%         plot(t(hs(ii):hs(ii+1)), rankML(hs(ii):hs(ii+1)),'g','LineWidth',2);
%     elseif ismember(hs(ii),lhs)
%         plot(t(hs(ii):hs(ii+1)), lankML(hs(ii):hs(ii+1)),'c','LineWidth',2);
%     end
% end
% hold off
% close all
%% margin of stability

% separating right and left steps for XCOM and calculating MOS

rMOS0 =  XCOMML - rankML; % raw right MOS 
lMOS0 =  XCOMML - lankML; % raw left MOS

j = 1;
k = 1;

for i = 1:length(hs) - 1
    if ismember(hs(i),rhs)
       rMOS1 = rMOS0(hs(i):hs(i+1));
       rMOS2 = rMOS1(rMOS1<0); % those valuse that correspond to XCOM is within the BOS (XCOMML > rankML)
       if rMOS2
            rMOS_mean(j) = mean(abs(rMOS2));
            rMOS_min(j) = min(abs(rMOS2));
       else
           rMOS_mean(j) = Inf;
           rMOS_min(j) = Inf;
       end
       j = j + 1;
    elseif ismember(hs(i),lhs)
       lMOS1 = lMOS0(hs(i):hs(i+1));
       lMOS2 = lMOS1(lMOS1>0);   % those valuse that correspond to XCOM is within the BOS (XCOMML < lankML)
       if lMOS2
           lMOS_mean(k) = mean(abs(lMOS2));
           lMOS_min(k) = min(abs(lMOS2));
       else
           lMOS_mean(k) = Inf;
           lMOS_min(k) = Inf;
       end
       k = k + 1;
    end
end

% for i = 1:length(hs) - 1
%     if ismember(hs(i),rhs)
%        rMOS1 = rMOS0(hs(i):hs(i+1));
%        rMOS2 = rMOS1(rMOS1>0); % those valuse that correspond to XCOM is within the BOS (XCOMML > rankML)
%        rMOS_mean(j) = mean(abs(rMOS2));
%        rMOS_min(j) = min(abs(rMOS2));
%        j = j + 1;
%     elseif ismember(hs(i),lhs)
%        lMOS1 = lMOS0(hs(i):hs(i+1));
%        lMOS2 = lMOS1(lMOS1<0);   % those valuse that correspond to XCOM is within the BOS (XCOMML < lankML)
%        lMOS_mean(k) = mean(abs(lMOS2));
%        lMOS_min(k) = min(abs(lMOS2));
%        k = k + 1;
%     end
% end
rMOS_mean_stride = mean(rMOS_mean); % average value over strides
lMOS_mean_stride = mean(lMOS_mean); % average value over strides

rMOS_min_stride = mean(rMOS_min); % average value over strides
lMOS_min_stride = mean(lMOS_min); % average value over strides

% choosing the final value for MOS min and mean
MOS_mean_final_new = min([rMOS_mean,lMOS_mean]); % as the minimum of R and L average values
MOS_min_final_new = min([rMOS_min,lMOS_min]); % as the minimum of R and L average values
[percentTime_new] = MOScalc(XCOMML,lankML,rankML,hs,rhs,lhs); % uses the function MOScalc.m
% percentTime: percent of time that XCOM was out of BOS either in left or
%              right side


%------------------- END OF CALCULATIONS ----------------------------------

num_timesteps_in_traj = size(right_leg_length,1);
skel_id = NaN;
num_steps = length(hs);
%% PART 7: BUILDING THE OUTPUT MATRIX FOR SAVING

out_st = [walkingspeed, cadence, steptime_mean, steplength_mean, stepwidth_mean]; % spatiotemporal

out_stVariability = [cvSteptime, cvSteplength, cvStepwidth, sdSacrML, rmsSacrMLvel, romSacrML]; % spatiotemporal variability

out_symmetry = [symSteptime, symStepLength, symStepWidth]; % symmetry

out_stability = [MOS_mean_final_new, MOS_min_final_new, percentTime_new]; % stability (only in ML direction)

out_details = [num_steps, skel_id, skelT.fps(1),skelT.start_frame(1), num_timesteps_in_traj];

out_final = [out_st, out_stVariability, out_symmetry, out_stability, out_details]; 

% ---------------------- END OF THE CODE ----------------------------------



end
