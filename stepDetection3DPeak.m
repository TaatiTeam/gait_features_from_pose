function [footfall_locs_final,footfall_locs, start_is_left] = stepDetection3DPeak(skel_struct, additional_info, gait_fts_configs, sinas_constants)
% Peak based step detection from Sina
show_plots = 0;
[num_timesteps, ~] = size(skel_struct.RAnkle);
if ~exist('sinas_constants', 'var')
    sinas_constants = 0;
end


% PART 1: FINDING HEEL STRIKES TO SEPARATE STEPs
tuning_factor = 0.05;
if sinas_constants
    tuning_factor = 0.1;
end

rankAP = skel_struct.RAnkle(:,3);
lankAP = skel_struct.LAnkle(:,3);

tempxr = rankAP - lankAP; % right - left
tempxl = lankAP - rankAP; % left - right

% plotting R and L ankle in AP and also their difference to explore data
if show_plots
    figure
    subplot(2,1,1)
    hold on
    plot (rankAP,'r');
    plot (lankAP,'k');
    % now finding R and L heel strikes
    
    subplot(2,1,2)
    hold on
    plot(tempxr,'r'); plot(tempxl,'k');
end
[rhs, ~] = peakdet(tempxr,tuning_factor); % max are R hs using the peakdet function
[lhs, ~] = peakdet(tempxl,tuning_factor); % max are L hs using the peakdet function

% removing the first and last point if they equal to the first and last
% point of the ankle time series
rhs(rhs == 1) = [];
rhs(rhs == num_timesteps) = [];

lhs(lhs == 1) = [];
lhs(lhs == num_timesteps) = [];


% also removing the last steps if sinas_constants
if sinas_constants
    try
        rhs(end) = [];
        lhs(end) = [];
    catch
    end
end
[footfall_locs_final,footfall_locs, start_is_left] = longestContinuousWalk_v2(lhs,rhs, num_timesteps);


end