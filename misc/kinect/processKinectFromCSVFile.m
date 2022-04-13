function [skel_struct_raw] = processKinectFromCSVFile(path_to_csv)
%% PROGRAM TO CONVERT CSV FILE TO MATLAB FILE (for AMBIENT project)
% Credit: Sina Mehdizadeh with thanks to Elham Dolatabadi, Updated by
% Andrea Sabo 2022-02-03
% Update: 2018-11-07
% Uses: SM_changeFolder.m <--- this should be run first
%-------------------------------------------------
%% ------------------------ !! WARNING !! --------------------------------
% according to Microsoft left/right assignment
% z = AP   x = ML   y = VT

%% PAlT 1: READING FROM CSV FILE

data = readtable(path_to_csv);
d = table2array(data);

% drop the time
d(:, 1) = [];
% filter
[b, a] = butter(4,0.5);
%-----------------------------------------------------
%% PART 2: SEPARATING JOINT DATA
% according to this website by Elham: https://archive.codeplex.com/?p=kinectstleamsaver2

fields = {'Sacr', 'Spine', 'c7', 'Head', 'LShoulder', ...
                 'LElbow', 'LWrist', 'LHand', 'RShoulder', 'RElbow', ...
                 'RWrist', 'RHand', 'LHip', 'LKnee', 'LAnkle', 'LFoot', ...
                 'RHip', 'RKnee', 'RAnkle', 'RFoot', 'SpineShoulder', ...
                 'LHandTip', 'LThumb', 'RHandTip', 'RThumb'};

             
skel_struct = struct();  
skel_struct_raw = struct();
for i = 1:length(fields)
    part_name = fields{i};
    ML_raw = d(:, i*3 - 2);
    VT_raw = d(:, i*3 - 1);
    AP_raw = d(:, i*3);
    
%     ML = filtfilt(b, a, ML_raw);
%     VT =filtfilt(b, a,VT_raw);
%     AP = filtfilt(b, a, AP_raw);
    
    skel_struct_raw.(part_name) = [ML_raw, VT_raw, AP_raw];
%     skel_struct.(part_name) = [ML, VT, AP];
end

end % end function        
