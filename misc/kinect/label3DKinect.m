close all, clear all, clc


search_folder = "N:\\AMBIENT/Lakeside/extractions_lakeside";
% search_folder = "N:\\AMBIENT/Lakeside/PoseTrackingForMatlab";
subfolders = GetSubDirsSecondLevelOnly(search_folder);
failed_walks_output_file = "N:\\AMBIENT/Lakeside/extractions_lakeside/kinectWalksToXEFLabel3.txt";
all_walks_output_file = "N:\\AMBIENT/Lakeside/extractions_lakeside/all_walks_v3.txt";
failed_walks = [];
all_walks = [];

for s = 1:length(subfolders)
    fullpath = join([search_folder, subfolders{s}], filesep);
    if (str2num(subfolders{s}(end)) < 4)
        continue
    end
    all_walks = [all_walks; fullpath];
    [skeleton_files, vid_file] = GetKinectSkelFilesList(fullpath);
    output_file = join([fullpath, 'skel_label.txt'], filesep);
    output_skel_video = join([fullpath, 'skel_vid.avi'], filesep);
    success = 0;
    fprintf('%d: %s\n', s, fullpath);
    % Skip if we have the output or the video
    if exist(output_file, 'file')
        continue;
    end

    % If we have the video, label from it
    if (~isempty(vid_file) && ~exist(output_skel_video, 'file'))
%         success = 1;
        success = SelectKinectSkeleton(fullpath, vid_file, skeleton_files, output_file);
    end   
    
    % Don't have colour video, generate the skeleton trajectory video
    % for labelling 
    if (isempty(vid_file) || ~success) && ~exist(output_skel_video, 'file')
        makeKinectVideo(fullpath, skeleton_files, output_skel_video)
    end
    
    if ~success
        failed_walks = [failed_walks; fullpath];
        fileID = fopen(failed_walks_output_file,'w');
        fprintf(fileID,'%s\n',failed_walks);
        fclose(fileID);
    end
%     csvwrite(failed_walks_output_file, failed_walks);
    
end
fileID = fopen(all_walks_output_file,'w');
fprintf(fileID,'%s\n',all_walks);
fclose(fileID);

