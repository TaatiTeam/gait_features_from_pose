function [footfall_locs_final,footfall_locs, start_is_left] = stepDetectionDBSCAN(skel_struct, additional_info, gait_fts_configs)
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

hip_dist = movmean(hip_width(:, 2), 20);

% These have already been filtered
signal_l = LF;
signal_r = RF;

% New DBSCAN work for detection of stance phases

[coeff_l,score,latent,tsquared,explained,mu] = pca(signal_l);
[coeff_r,score,latent,tsquared,explained,mu] = pca(signal_r);
dataInPrincipalComponentSpace_l = signal_l*coeff_l;
dataInPrincipalComponentSpace_r = signal_r*coeff_r;


shoulder_width = vecnorm(skel_struct.LShoulder(:, 1:2) - skel_struct.RShoulder(:, 1:2), 2, 2);
to_cluster_l= dataInPrincipalComponentSpace_l(:, 1);
to_cluster_r= dataInPrincipalComponentSpace_r(:, 1);
times = skel_struct.time;


% labels_l = dbscan_st_dynamic(to_cluster_l, times, shoulder_width, eps_spatial, eps_temporal, min_pts);
% labels_r = dbscan_st_dynamic(to_cluster_r, times, shoulder_width, eps_spatial, eps_temporal, min_pts);
labels_l = dbscan_st_dynamic2D(signal_l, times, shoulder_width, eps_spatial, eps_temporal, min_pts);
labels_r = dbscan_st_dynamic2D(signal_r, times, shoulder_width, eps_spatial, eps_temporal, min_pts);

% if show_plots
%     figure, hold on, plot(to_cluster_l), plot(labels_l*50, '*')
%     figure, hold on, plot(to_cluster_r), plot(labels_r*50, '*')
%
% end
%     figure, hold on, plot(signal_l), plot(labels_l*50, '*')
%     figure, hold on, plot(signal_r), plot(labels_r*50, '*')

% Convert the clusters into a struct of stance phases
[stance_struct_l, locsl] = clustersToStance(signal_l, times, labels_l, 'l', strel_size);
[stance_struct_r, locsr] = clustersToStance(signal_r, times, labels_r, 'r', strel_size);

% Visualize clusters
if show_plots
    figure, hold on
    plot(times, signal_l, 'LineWidth', 4)
    
    [len, dims] = size(signal_l);
    for i = 1:length(stance_struct_l)
        cur_stance = stance_struct_l(i);
        ts = (cur_stance.first:cur_stance.last) / additional_info.fps;
        mean_pt = ones(dims, length(ts))' .* cur_stance.mean_position;
        plot(ts, mean_pt, 'k*')
        
        
    end
    
    if dims == 1
        legend('x', 'stances')
    elseif dims == 2
        legend('x', 'y', 'stances')
    elseif dims == 3
        legend('x', 'y', 'z', 'stances')
    end
    
    xlabel('Time (seconds)')
    ylabel('Joint Position in Camera Space (pixel)')
    title("Left Ankle Position and Stances Detected using ST-DBSCAN")
    
    figure, hold on
    plot(times, signal_r, 'LineWidth', 4)
    for i = 1:length(stance_struct_r)
        cur_stance = stance_struct_r(i);
        ts = (cur_stance.first:cur_stance.last) / additional_info.fps;
        
        mean_pt = ones(dims, length(ts))' .* cur_stance.mean_position;
        plot(ts, mean_pt, 'k*')
    end
    
    if dims == 1
        legend('x', 'stances')
    elseif dims == 2
        legend('x', 'y', 'stances')
    elseif dims == 3
        legend('x', 'y', 'z', 'stances')
    end
    
    xlabel('Time (seconds)')
    ylabel('Joint Position in Camera Space (pixel)')
    title("Right Ankle Position and Stances Detected using ST-DBSCAN")
    
    
    % Combined plot
%     figure, hold on
    figure_hand = figure;
    figure_hand.Position = [100 100 1920 1080];
    hold on,
    plot(times, signal_l(:, 1), 'LineWidth', 7)
    plot(times, signal_r(:, 1), 'LineWidth', 7)
    
    [len, dims] = size(signal_l);
    for i = 1:length(stance_struct_l)
        cur_stance = stance_struct_l(i);
        ts = (cur_stance.first - 1:cur_stance.last - 1) / additional_info.fps;
        mean_pt = ones(dims, length(ts))' .* cur_stance.mean_position(1);
        
        signal_pl = signal_l((cur_stance.first:cur_stance.last));
        
        %         plot(ts, mean_pt, 'k*')
        plot(ts, signal_pl,'k', 'LineWidth', 8)
        
    end
    
    for i = 1:length(stance_struct_r)
        cur_stance = stance_struct_r(i);
        ts = (cur_stance.first - 1:cur_stance.last - 1) / additional_info.fps;
        signal_pr = signal_r((cur_stance.first:cur_stance.last));
        mean_pt = ones(dims, length(ts))' .* cur_stance.mean_position(1);
        %         plot(ts, mean_pt, 'k*')
        plot(ts, signal_pr, 'k', 'LineWidth', 8)
    end
    
    if dims == 1
        legend('x', 'Stances', 'FontSize', 24, 'Location', 'northwest')
    elseif dims == 2
        legend('Left x Position', 'Right x Position', 'Stances', 'FontSize', 24, 'Location', 'northwest')
    elseif dims == 3
        legend('x', 'y', 'z', 'Stances', 'FontSize', 24, 'Location', 'northwest')
    end
    
    axis_tick_fs = 24;
    axis_label_fs = 24;
    xlabel('Time (seconds)', 'FontSize', axis_label_fs);
    ylabel('Joint Position in Camera Space (pixels)', 'FontSize', axis_label_fs);
    title("Horizontal Ankle Position and Stances Detected using ST-DBSCAN", 'FontSize', 36);
    axis_handley1 = get(gca,'YTickLabel');
    set(gca,'YTickLabel',axis_handley1,'FontName','Times','fontsize',axis_tick_fs);
    axis_handle = get(gca,'XTickLabel');
    set(gca,'XTickLabel',axis_handle,'FontName','Times','fontsize',axis_tick_fs);
    grid on
    
    % Plot with patch
    % ==============================================================================
    % Combined plot
%     figure, hold on
    figure_hand = figure;
    figure_hand.Position = [100 100 1920 960];
    hold on,
    plot(times, signal_l(:, 1), 'LineWidth', 7)
    plot(times, signal_r(:, 1), 'LineWidth', 7)
    
    [len, dims] = size(signal_l);
    for i = 1:length(stance_struct_l)
        cur_stance = stance_struct_l(i);
        ts = (cur_stance.first - 1:cur_stance.last - 1) / additional_info.fps;
        mean_pt = ones(dims, length(ts))' .* cur_stance.mean_position(1);
        
        signal_pl = signal_l((cur_stance.first:cur_stance.last));
        
        %         plot(ts, mean_pt, 'k*')
%         plot(ts, signal_pl,'k', 'LineWidth', 8)
        
        min_ts = (cur_stance.first - 1) / additional_info.fps;
        max_ts = (cur_stance.last - 1) / additional_info.fps;
        
        min_val = min(signal_pl) - 5;
        max_val = max(signal_pl) + 5;
        
        x = [min_ts max_ts max_ts min_ts ];
        y = [min_val min_val max_val max_val];
        v1 = [min_ts, min_val; max_ts, min_val;
             max_ts, max_val; min_ts, max_val];
        f1 = [1, 2, 3, 4];
        patch('Faces',f1,'Vertices',v1,'FaceColor','red','FaceAlpha',.25, 'EdgeColor', 'none');
        
    end
    
    for i = 1:length(stance_struct_r)
        cur_stance = stance_struct_r(i);
        ts = (cur_stance.first - 1:cur_stance.last - 1) / additional_info.fps;
        signal_pr = signal_r((cur_stance.first:cur_stance.last));
        mean_pt = ones(dims, length(ts))' .* cur_stance.mean_position(1);
        %         plot(ts, mean_pt, 'k*')
%         plot(ts, signal_pr, 'k', 'LineWidth', 8)
        
        
        min_ts = (cur_stance.first - 1) / additional_info.fps;
        max_ts = (cur_stance.last - 1) / additional_info.fps;
        
        min_val = min(signal_pr) - 5;
        max_val = max(signal_pr) + 5;
        
        x = [min_ts max_ts max_ts min_ts ];
        y = [min_val min_val max_val max_val];
        v1 = [min_ts, min_val; max_ts, min_val;
             max_ts, max_val; min_ts, max_val];
        f1 = [1, 2, 3, 4];
        p_ref = patch('Faces',f1,'Vertices',v1,'FaceColor','red','FaceAlpha',.25, 'EdgeColor', 'none');
    end
    
    if dims == 1
        legend('x', 'Stances', 'FontSize', 24, 'Location', 'northwest')
    elseif dims == 2
        legend('Left x Position', 'Right x Position', 'Stances', 'FontSize', 24, 'Location', 'northwest')
    elseif dims == 3
        legend('x', 'y', 'z', 'Stances', 'FontSize', 24, 'Location', 'northwest')
    end
    
    axis_tick_fs = 24;
    axis_label_fs = 24;
    xlabel('Time (seconds)', 'FontSize', axis_label_fs);
    ylabel('Joint Position in Camera Space (pixels)', 'FontSize', axis_label_fs);
    title("Horizontal Ankle Position and Stances Detected using ST-DBSCAN", 'FontSize', 40);
    axis_handley1 = get(gca,'YTickLabel');
    set(gca,'YTickLabel',axis_handley1,'FontName','Times','fontsize',axis_tick_fs);
    axis_handle = get(gca,'XTickLabel');
    set(gca,'XTickLabel',axis_handle,'FontName','Times','fontsize',axis_tick_fs);
    grid on
    
end
close all


if length(stance_struct_l) > 0
    stance_struct(1:length(stance_struct_l), 1) = stance_struct_l;
end
if length(stance_struct_r) > 0
    stance_struct(1:length(stance_struct_r), 2) = stance_struct_r;
end

if ~exist('stance_struct', 'var')
    stance_struct = NaN;
end


% Bounds checking
locsl(locsl < 1) = [];
locsr(locsr < 1) = [];
locsl(locsl > num_timesteps) = [];
locsr(locsr > num_timesteps) = [];

[footfall_locs_final,footfall_locs, start_is_left] = longestContinuousWalk_v2(locsl,locsr, num_timesteps);
try
    footfall_locs_final = footfall_locs_final(drop_first_n + 1:end);
catch
end

end