function [] = exportSkelDataToCSV(export_configs, walk_data, patient_skel, smoothed_patient_data)

% Copy to local variables
fps = walk_data.fps;
detector = walk_data.detector;
fixOP = walk_data.fixOP;
real_num_frames = walk_data.num_frames;
timestamps = walk_data.timestamps;
start_frame = walk_data.start_frame;
walk_id = walk_data.walk_id;
patient_id = walk_data.patient_id;

walk_id_for_export = strcat(patient_id, '.', walk_id);

export_base = export_configs.export_base;


% Unify interface even if we don't have clinical scores and demographic
% data
if ~isfield(walk_data, 'clinical_scores')
    walk_data.clinical_scores = [];
end

if ~isfield(walk_data, 'demographic_data')
    walk_data.demographic_data = [];
end


walk_base = fullfile(export_base, patient_id, walk_id, detector);

raw_save_folder = fullfile(export_base, detector, 'raw');
interpolated_save_folder = fullfile(export_base, detector, 'interpolated');

% Make the necessary output folders
folder_paths = [];
if export_configs.save_raw
    folder_paths = [folder_paths, raw_save_folder];
end
if export_configs.save_interpolated
    folder_paths = [folder_paths, interpolated_save_folder];
end

for i = 1:length(folder_paths)
    p = folder_paths(i);
    
    if ~exist(p, 'dir')
        mkdir(p);
    end
end

walk_id_csv = strcat(walk_id_for_export,'.csv');

if ~isempty(walk_data.subwalk)
    walk_id_csv = strcat(walk_id_for_export,'-', walk_data.subwalk, '.csv');
end

% Flatten and save results
if export_configs.save_raw
    % Save raw data
    flattened_data = flattenStructToArray(export_configs, detector, ...
        patient_skel, walk_data.clinical_scores, walk_data.demographic_data, ...
        walk_base, fps, fixOP, real_num_frames, timestamps, start_frame, ...
        walk_data.width, walk_data.height, patient_id, walk_data.is_backward, walk_id);
    raw_save_path = fullfile(raw_save_folder, walk_id_csv);
    writetable(flattened_data,raw_save_path)
    
end

if export_configs.save_interpolated
    
    % Save interpolated data
    flattened_data = flattenStructToArray(export_configs, detector, ...
        smoothed_patient_data, walk_data.clinical_scores, walk_data.demographic_data,...
        walk_base, fps, fixOP, real_num_frames, timestamps, start_frame,...
        walk_data.width, walk_data.height, patient_id, walk_data.is_backward, walk_id);
    interpolated_save_path = fullfile(interpolated_save_folder, walk_id_csv);
    writetable(flattened_data,interpolated_save_path)
end


end


function [flattened_data] = flattenStructToArray(export_configs, detector, ...
          struct_skel, clinical_score, demo_data, walk_base, fps, fixOP, ...
          real_num_frames, timestamps, start_frame, vid_width, vid_height, ...
          patient_id, is_backward, walk_id)

% local fields
normalize_dist = export_configs.normalize_dist;
center_hip = export_configs.center_hip;

% Select the fields to export. We manually select them in case there is
% additional data in the skel_struct that we don't want to necessarily save

norm_type = export_configs.normalization_type;
fields = getSkelFields(export_configs.use_kinect_exports, detector);


if export_configs.use_kinect_exports

    if export_configs.export_2D_kinect
        props = ["_x", "_y"];
    else
        props = ["_x", "_y", "_z"];
    end
    
    
elseif strcmp(detector, 'romp')
    props = ["_x", "_y", "_z"];

else
    props = ["_x", "_y", "_conf"];
end

% fields = fieldnames(struct_skel);
num_timestamps = 0;

all_fieldnames = ["time"];
data = [];
for f = 1:length(fields)
    field = fields{f};
    if strcmp(field, 'skel_id')
        continue;
    end
    num_timestamps = length(struct_skel.(field));
    for p = 1:length(props)
        prop = props(p);
        all_fieldnames = [all_fieldnames, strcat(field, prop)];
    end
    
    joint = struct_skel.(field);
    
    % 2d
    data_coords = 1:2;
    
    % 3D
    if export_configs.use_kinect_exports && ~export_configs.export_2D_kinect
        data_coords = 1:3;
    end
    
    
    joint_data = joint(:, data_coords);
    
    joint_conf = [];
    if ~export_configs.use_kinect_exports
        joint_conf = joint(:,3); % Don't have confidence for Kinect exports
    end
    % Do centering
    if export_configs.center_hip ~= 0
        mean_hip = (struct_skel.LHip(:, data_coords) + struct_skel.RHip(:, data_coords)) / 2;
        joint_data = joint_data - mean_hip + export_configs.center_hip_offset;
    end
    
    % Joint to normalize by
    if export_configs.normalize_dist
        joint_to_norm_by = export_configs.normalization_type;
        
        if strcmp(joint_to_norm_by, "shoulder")
            l_norm_joint = struct_skel.LShoulder(:, data_coords);
            r_norm_joint = struct_skel.RShoulder(:, data_coords);
        elseif strcmp(joint_to_norm_by, "hip")
            l_norm_joint = struct_skel.LHip(:, data_coords);
            r_norm_joint = struct_skel.RHip(:, data_coords);
        else
            % Default to taking the distance between the hip and shoulder
            % center
            l_norm_joint = (struct_skel.LHip(:, data_coords) + struct_skel.RHip(:, data_coords)) / 2;
            r_norm_joint = (struct_skel.LShoulder(:, data_coords) + struct_skel.RShoulder(:, data_coords)) / 2;
        end
        
        % Calculate the normalization distance in each frame
        mean_norm_joint = vecnorm(l_norm_joint - r_norm_joint, 2, 2);
        joint_data = joint_data ./ mean_norm_joint .* export_configs.normalization_upscale_factor;
        
        
    end
    
    
    
    data = [data, joint_data, joint_conf];
    
end

% Calculate the bounding box at each time step (needed for mmskel library)
x_vals = [];
y_vals = [];
z_vals = [];
prop_length = length(props);
for i = 1:length(fields)
    x = data(:, i*prop_length - (prop_length - 1));
    y = data(:, i*prop_length - (prop_length - 2));
    
    x_vals = [x_vals, x];
    y_vals = [y_vals, y];
    
    if (export_configs.use_kinect_exports && ~export_configs.export_2D_kinect) || strcmp(detector, 'romp')
        % 3D kinect
        z = data(:, i*prop_length - (prop_length- 3));
        z_vals = [z_vals, z];
               
        
    end
    
    
end


x_mins = min(x_vals, [], 2);
y_mins = min(y_vals, [], 2);
x_maxs = max(x_vals, [], 2);
y_maxs = max(y_vals, [], 2);

z_mins = [];
z_maxs = [];

if (export_configs.use_kinect_exports && ~export_configs.export_2D_kinect) || strcmp(detector, 'romp')
    % 3D kinect
    z_mins = min(z_vals, [], 2);
    z_maxs = max(z_vals, [], 2);
end

walk = strsplit(walk_base, filesep);
walk_name = walk(end-1) +  "__" +walk(end);



time = linspace(1/fps, 1/fps*num_timestamps-1/fps, num_timestamps)';

if (start_frame > 0)
    time = linspace((start_frame - 1)/fps, 1/fps*num_timestamps-1/fps, num_timestamps)';
end


if (length(timestamps) >= num_timestamps)
    time = timestamps(1:num_timestamps);
end

data = [time, data];

% Add the bounding box to data


if (export_configs.use_kinect_exports && ~export_configs.export_2D_kinect) || strcmp(detector, 'romp')
    % 3D kinect
    all_fieldnames = [all_fieldnames, "x_min", "y_min", "z_min", "x_max", "y_max", "z_max"];
        data = [data, x_mins, y_mins, z_mins, x_maxs, y_maxs, z_maxs];

else
    all_fieldnames = [all_fieldnames, "x_min", "y_min", "x_max", "y_max"];
    data = [data, x_mins, y_mins, x_maxs, y_maxs];
    
end

% Saving clinical scores
if export_configs.save_clinical_scores
    try
        clin_scores= fieldnames(clinical_score);
        for score_i = 1:length(clin_scores)
            score = clin_scores{score_i};
            all_fieldnames = [all_fieldnames, score];
            score_data = clinical_score.(score).* ones(1, num_timestamps);
            data = [data, score_data'];
        end
    catch
%         fprintf("failed to export clinical_scores in exportSkelDataToCSV\n");
    end
end

if export_configs.save_demographics
    try
        clin_scores= fieldnames(demo_data);
        for score_i = 1:length(clin_scores)
            score = clin_scores{score_i};
            all_fieldnames = [all_fieldnames, score];
            score_data = repmat(demo_data.(score), num_timestamps, 1);
            data = [data, score_data];
        end
    catch
%         fprintf("failed to export demo_data in exportSkelDataToCSV\n");
    end
    
end

% TODO: clean this up with struct of things to log 
% Add walkname to table
all_fieldnames = [all_fieldnames, "walk_name"];
walk_name_rep = repmat(walk_name, num_timestamps, 1);
data = [data, walk_name_rep];

% Add FPS to table
all_fieldnames = [all_fieldnames, "fps"];
walk_name_rep = repmat(fps, num_timestamps, 1);
data = [data, walk_name_rep];

% Add global start frame to table
all_fieldnames = [all_fieldnames, "start_frame"];
walk_name_rep = repmat(start_frame, num_timestamps, 1);
data = [data, walk_name_rep];

% Add video dimensions to the table
all_fieldnames = [all_fieldnames, "width"];
walk_name_rep = repmat(vid_width, num_timestamps, 1);
data = [data, walk_name_rep];

all_fieldnames = [all_fieldnames, "height"];
walk_name_rep = repmat(vid_height, num_timestamps, 1);
data = [data, walk_name_rep];

all_fieldnames = [all_fieldnames, "patient_id"];
walk_name_rep = repmat(patient_id, num_timestamps, 1);
data = [data, walk_name_rep];

all_fieldnames = [all_fieldnames, "is_backward"];
walk_name_rep = repmat(is_backward, num_timestamps, 1);
data = [data, walk_name_rep];

all_fieldnames = [all_fieldnames, "walk_id"];
walk_name_rep = repmat(walk_id, num_timestamps, 1);
data = [data, walk_name_rep];

all_fieldnames = [all_fieldnames, "detector"];
walk_name_rep = repmat(detector, num_timestamps, 1);
data = [data, walk_name_rep];

% Make data into a table
all_fieldnames = cellstr(all_fieldnames);
flattened_data = array2table(data);
flattened_data.Properties.VariableNames = all_fieldnames;

end

