   function [output_names] = GetSubDirsSecondLevelOnly(parentDir, folder_prefix)
   if nargin < 2
       folder_prefix = 'AMB';
   end
   
   % Get a list of all files and folders in this folder.
   files    = dir(parentDir);
   ismatch = cellfun(@isempty, regexp({files.name}, char(strcat( folder_prefix, '\d{2}.')), 'match', 'once'));
   names    = {files(find(ismatch)).name};
   % Get a logical vector that tells which is a directory.
   dirFlags = [files(find(ismatch)).isdir] & ~strcmp(names, '.') & ~strcmp(names, '..');
   % Extract only those that are directories.
   subDirsNames = names(dirFlags);
   
   output_names = {};
   
    for i = 1:length(subDirsNames)
        subdir_name = subDirsNames{i};
        if strcmp(folder_prefix, "AMB")
            if ~strcmp("AMB", subdir_name(1:3))
                continue;
            end
        end
        
        files    = dir(fullfile(parentDir, subdir_name));
        names    = {files.name};
        dirFlags = [files.isdir] & ~strcmp(names, '.') & ~strcmp(names, '..');

        subsubDirsNames = names(dirFlags);
        subsubDirsNames = fullfile(subdir_name, subsubDirsNames);
        
        output_names = [output_names, subsubDirsNames];
    end
   
   
   end