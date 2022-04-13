function [footfall_locs_final,footfall_locs, start_is_left] = stepDetection2DPeak(skel_struct, additional_info, gait_fts_configs)
% This code is a port of Becky's thesis work that calculated the
% heelstrikes as 35% of the peak vertical velocity. 

show_plots = 0;

eps_spatial = gait_fts_configs.eps_spatial;
eps_temporal = gait_fts_configs.eps_temporal;
min_pts = gait_fts_configs.min_pts;
strel_size = gait_fts_configs.strel_size;
drop_first_n = gait_fts_configs.drop_first_n;

LH = skel_struct.LHip(:,1:2);
RH = skel_struct.RHip(:,1:2);
LF = skel_struct.LAnkle(:,1:2);
RF = skel_struct.RAnkle(:,1:2);

if additional_info.is_3d
    LH = skel_struct.LHip;
    RH = skel_struct.RHip;
    LF = skel_struct.LAnkle;
    RF = skel_struct.RAnkle;
end


LH = fillmissing(LH, 'linear', 1);
RH = fillmissing(RH, 'linear', 1);
LF = fillmissing(LF, 'linear', 1);
RF = fillmissing(RF, 'linear', 1);

[num_timesteps, ~] = size(skel_struct.Nose);


try
    hip_width(:,1)= 1:length(LH);
    hip_width(:,2)=smooth(vecnorm(LH - RH, 2, 2));
catch
    hip_width;
end

% Direct copy from Becky's work:

dRFy=diff(RF(:, 2));
dLFy=diff(LF(:, 2));

minpkd=25;
minpkp=2;
[pksdRFy,locsdRFy]=findpeaks(dRFy,'MinPeakDistance',minpkd,'MinPeakProminence',minpkp);
[pksdLFy,locsdLFy]=findpeaks(dLFy,'MinPeakDistance',minpkd,'MinPeakProminence',minpkp);

locsdRFyb=zeros(length(locsdRFy),1);
for i=2:length(locsdRFy)-1
    temp=0.35*pksdRFy(i);
    indx1 = dRFy(locsdRFy(i):locsdRFy(i+1))<=temp;
    idx = find(indx1);
    if isempty(idx)
        idx=0;
    end
    locsdRFyb(i)=(locsdRFy(i)+(idx(1)-1))/additional_info.fps;
end
locsdLFyb=zeros(length(locsdLFy),1);
for i=2:length(locsdLFy)-1
    temp=0.35*pksdLFy(i);
    indx1 = dLFy(locsdLFy(i):locsdLFy(i+1))<=temp;
    idx = find(indx1);
    if isempty(idx)
        idx=0;
    end
    locsdLFyb(i)=(locsdLFy(i)+(idx(1)-1))/additional_info.fps;
end
locsdRFyb(any(locsdRFyb==0,2),:) = [];
locsdLFyb(any(locsdLFyb==0,2),:) = [];
locsr=locsdRFyb.*additional_info.fps;
locsl=locsdLFyb.*additional_info.fps;

% Bounds checking
locsl(locsl < 1) = [];
locsr(locsr < 1) = [];
locsl(locsl > num_timesteps) = [];
locsr(locsr > num_timesteps) = [];

for i = 1:length(locsl)
    locsl(i) = int32(locsl(i));
end
for i = 1:length(locsr)
    locsr(i) = int32(locsr(i));
end

[footfall_locs_final,footfall_locs, start_is_left] = longestContinuousWalk_v2(locsl,locsr, num_timesteps);
try
    footfall_locs_final = footfall_locs_final(drop_first_n + 1:end);
catch
end


end