function [success] = SelectKinectSkeleton(fullpath, vid_file, skeleton_files, output_file)

success = 1;
full_vid_path = join([fullpath,vid_file], filesep);
% Don't have any kinect information, so there's nothing to label
if length(skeleton_files) == 0
    return
end

all_skels = {};
for i = 1:length(skeleton_files)
    path_to_csv = join([fullpath, skeleton_files{i}], filesep);
    [skel_struct] = processKinectFromCSVFile(path_to_csv);
    all_skels{i} = skel_struct;
end

skel_id = '';
max_kinect = length(skel_struct.RAnkle(:, 1));
kinect_frame = 1;
frame_to_plot = 30;
figure('Renderer', 'painters', 'Position', [1 1 1920 1080]), hold on
while (isempty(skel_id))
    % Plot the frame and skels
    try
        v = VideoReader(full_vid_path);
        frame = read(v,frame_to_plot);
        
        tiledlayout(2,1)
        nexttile, imshow(frame)
        h2 = nexttile;
        cla(h2)
        hold on
        for i = 1:length(skeleton_files)
            cur_skel = all_skels{i};
            plotKinectSkelLocal(cur_skel,i, kinect_frame);
        end
%         h1 = axes;
%         set(h2, 'Xdir', 'reverse');
        grid on
        view([0, 90])
        
        %prompt to choose which skel is patient
        prompt = 'Which skeleton is the participant? \nBlue - 1, Green - 2, Red - 3, Cyan - 4, Yellow - 5, Magenta - 6, Black - 7\nEnter 0 if participant is not tracked.\nEnter -1 if participant if you cannot make the determination of whether the participant is tracked.\nEnter nothing to advance the video frame. \nEnter input: ';
        skel_id = input(prompt);
        frame_to_plot = frame_to_plot + 120;
        kinect_frame = mod(kinect_frame + 20, max_kinect) + 1;
    catch % went through all frames
        skel_id = -1;
    end
end
close all
skel_id = skel_id - 1;

if (skel_id < -1) %
    success = 0;
    return
end

% Save the output to a text file for later reading
csvwrite(output_file, skel_id);
end

function [] = plotKinectSkelLocal(cur_skel, i, frame)
colour_list = ['b', 'g', 'r', 'c', 'y', 'm', 'k', 'w'];
colour = colour_list(i);
plotLineKinect3D(cur_skel, 'RAnkle', 'RKnee', colour, frame)
plotLineKinect3D(cur_skel, 'RHip', 'RKnee', colour, frame)
plotLineKinect3D(cur_skel, 'RHip', 'LHip', colour, frame)
plotLineKinect3D(cur_skel, 'LAnkle', 'LKnee', colour, frame)
plotLineKinect3D(cur_skel, 'LHip', 'LKnee', colour, frame)

% text((cur_skel.RHip(frame, 1) + cur_skel.LShoulder(frame, 1)) / 2, ...
%     (cur_skel.RHip(frame, 2) + cur_skel.LShoulder(frame, 2)) / 2, ...
%     num2str(i), 'FontSize',14);

plotLineKinect3D(cur_skel, 'RHip', 'RShoulder', colour, frame)
plotLineKinect3D(cur_skel, 'LHip', 'LShoulder', colour, frame)

plotLineKinect3D(cur_skel, 'RWrist', 'RElbow', colour, frame)
plotLineKinect3D(cur_skel, 'RElbow', 'RShoulder', colour, frame)
plotLineKinect3D(cur_skel, 'RShoulder', 'LShoulder', colour, frame)
plotLineKinect3D(cur_skel, 'LWrist', 'LElbow', colour, frame)
plotLineKinect3D(cur_skel, 'LElbow', 'LShoulder', colour, frame)
end

function [] = plotLineKinect3D(positions, start_joint, end_joint, colour, frame)
plot3([positions.(start_joint)(frame, 1), positions.(end_joint)(frame, 1)], ...
    [positions.(start_joint)(frame, 2), positions.(end_joint)(frame,2)],...
    [positions.(start_joint)(frame, 3), positions.(end_joint)(frame,3)],...
    colour, 'LineWidth', 2)
end

