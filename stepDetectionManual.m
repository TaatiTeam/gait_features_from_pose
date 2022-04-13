function [footfall_locs_final,footfall_locs, start_is_left] = stepDetectionManual(skel, additional_info)
manual_labels = table('Size', [0, 2], 'VariableTypes',{'double','double'}, 'VariableNames', {'left', 'right'});

try
    manual_labels = readtable(additional_info.manual_steps);
catch
end

locsl =manual_labels.left - additional_info.start_frame;
locsr =manual_labels.right - additional_info.start_frame;
[num_timesteps, ~] = size(skel.Nose);

locsl(locsl < 1) = [];
locsr(locsr < 1) = [];
locsl(locsl > num_timesteps) = [];
locsr(locsr > num_timesteps) = [];

[footfall_locs_final,footfall_locs, start_is_left] = longestContinuousWalk_v2(locsl,locsr, num_timesteps);
end