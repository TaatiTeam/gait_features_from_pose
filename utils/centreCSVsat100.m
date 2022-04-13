function [] = centreCSVsat100(configs, export_configs, filt_or_raw, reference_gait_fts_file)
fprintf("starting CSV export\n");
% Go through all of the walks
all_walks_source  = configs.clean_trajectory_folder;

ref_t = readtable(reference_gait_fts_file);
% Go through each detector
for d = 1:length(configs.detectors)
    detector = configs.detectors{d};
    
    all_walks_for_det = fullfile(all_walks_source, detector, filt_or_raw);
    walk_csvs = dir(all_walks_for_det + "/*csv");
    
    % Go through all walks
    for i = 1:length(walk_csvs)
        walk_csv = fullfile(walk_csvs(i).folder, walk_csvs(i).name);
        
        % Load walks and manual annotations (if needed)
        skelT = readtable(walk_csv);
        
        start_frame = skelT.start_frame(1);
        fps = skelT.fps(1);
        
        
        [walk_id] = configs.getWalkAndPatientID(walk_csv);

        
        % Filter skel if needed
        export_conf = 1;
        is_kinect = 0;
        patient_skel = table2skel(skelT, export_conf, is_kinect);
        
        % 
        walk_data.fps = skelT.fps(1);
        walk_data.detector = skelT.detector{1};
        walk_data.patient_id = skelT.patient_id{1};
        walk_data.walk_id = walk_id;
        walk_data.fixOP = 0;
        walk_data.num_frames = height(skelT);
        walk_data.timestamps = skelT.time;
        walk_data.start_frame = skelT.start_frame(1);
        walk_data.subwalk = "";
        walk_data.width = skelT.width(1);
        walk_data.height = skelT.height(1);
        walk_data.is_backward = skelT.is_backward(1);
        
        short_walk_id = skelT.walk_id{1};
        
        
        [smoothed_patient_data] = interpolateAndFilterSkelData(patient_skel, walk_data.detector, configs.filter_cutoff_hz, 0, fps, getConfThres(detector), 0);
        smoothed_patient_data.time = skelT.time;
        
        if strcmp(configs.dataset, "PD_Fasano")
            [parts] = strsplit(walk_id, ["-", '.']);
            walk_data.subwalk = parts{end-1};
            walk_data.walk_id  = short_walk_id;
            idx = strcmp(ref_t.vid_name, short_walk_id) & strcmp(ref_t.direction, walk_data.subwalk(1:end-2));
            patient_demo = ref_t(idx, :);
            try
                walk_data.clinical_scores.UPDRS_gait = patient_demo.UPDRS_gait;
                walk_data.clinical_scores.SAS_gait = NaN;
                walk_data.demographic_data.sex = string(patient_demo.gender{1});
                walk_data.demographic_data.age = patient_demo.age;
                walk_data.demographic_data.DBS = patient_demo.DBS;
                walk_data.demographic_data.MEDS = patient_demo.MEDS;
                walk_data.demographic_data.num_steps_zeno = patient_demo.num_steps;
                exportSkelDataToCSV(export_configs, walk_data, patient_skel, smoothed_patient_data);
                
            catch
                i
            end
        else
            exportSkelDataToCSV(export_configs, walk_data, patient_skel, smoothed_patient_data);
        end

    end % end cur walk
end % end detector
end