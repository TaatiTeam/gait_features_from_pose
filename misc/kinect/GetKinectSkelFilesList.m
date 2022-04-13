function [skel_files, vid_file] = GetKinectSkelFilesList(parentDir)
    % Get a list of all files and folders in this folder.
    files    = dir(parentDir);
    ismatch = ~cellfun(@isempty, regexp({files.name}, 'Skeleton_\d{1}.csv', 'match', 'once'));
    skel_files    = {files(find(ismatch)).name};
    ismatch = ~cellfun(@isempty, regexp({files.name}, 'Video.avi', 'match', 'once'));
    vid_file =  {files(find(ismatch)).name};
end