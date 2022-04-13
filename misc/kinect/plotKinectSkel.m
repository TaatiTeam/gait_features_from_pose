function [] = plotKinectSkel(cur_skel, i, frame)
% Asked to plot outside of the range
if (frame > length(cur_skel.RAnkle(:, 1)))
    return;
end

colour_list = ['b', 'g', 'r', 'c', 'y', 'm', 'k', 'w'];
colour = colour_list(i);
plotLineKinect(cur_skel, 'RAnkle', 'RKnee', colour, frame)
plotLineKinect(cur_skel, 'RHip', 'RKnee', colour, frame)
plotLineKinect(cur_skel, 'RHip', 'LHip', colour, frame)
plotLineKinect(cur_skel, 'LAnkle', 'LKnee', colour, frame)
plotLineKinect(cur_skel, 'LHip', 'LKnee', colour, frame)

text((cur_skel.RHip(frame, 1) + cur_skel.LShoulder(frame, 1)) / 2, ...
    (cur_skel.RHip(frame, 2) + cur_skel.LShoulder(frame, 2)) / 2, ...
    num2str(i), 'FontSize',14);

plotLineKinect(cur_skel, 'RHip', 'RShoulder', colour, frame)
plotLineKinect(cur_skel, 'LHip', 'LShoulder', colour, frame)

plotLineKinect(cur_skel, 'RWrist', 'RElbow', colour, frame)
plotLineKinect(cur_skel, 'RElbow', 'RShoulder', colour, frame)
plotLineKinect(cur_skel, 'RShoulder', 'LShoulder', colour, frame)
plotLineKinect(cur_skel, 'LWrist', 'LElbow', colour, frame)
plotLineKinect(cur_skel, 'LElbow', 'LShoulder', colour, frame)
end

function [] = plotLineKinect(positions, start_joint, end_joint, colour, frame)
plot([positions.(start_joint)(frame, 1), positions.(end_joint)(frame, 1)], ...
    [positions.(start_joint)(frame, 2), positions.(end_joint)(frame,2)], ...
    colour, 'LineWidth', 2)
end
