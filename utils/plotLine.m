function [] = plotLine(positions, start_joint, end_joint, frame, colour, conf_thres, width, height)
%     conf_thres = 0.0;
if positions.(start_joint)(frame, 3) < conf_thres || positions.(end_joint)(frame, 3) < conf_thres ...
        || isnan(positions.(start_joint)(frame, 3)) || isnan(positions.(end_joint)(frame, 3))
    return;
end

if positions.(start_joint)(frame, 1) > width || positions.(end_joint)(frame, 1) > width || ...
     positions.(start_joint)(frame, 2) > height || positions.(end_joint)(frame, 2) > height
 return
end
    
plot([positions.(start_joint)(frame, 1), positions.(end_joint)(frame, 1)], ...
    [positions.(start_joint)(frame, 2), positions.(end_joint)(frame,2)], ...
    colour, 'LineWidth', 2)
end