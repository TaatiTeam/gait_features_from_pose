function [configs] = fixDiscontinuities(configs)

if (~configs.do_discont_check)
    return
end

% Set up empty tables
flip_detail_all_tables = table();
discont_detail_all_tables = table();
all_dets_table = table();
all_dets_combined_table = table();
conf_all_file_summary_table = table();



% alias
dc = configs.discont_configs;

% Set up video plotting
video_plotting_configs = VideoPlottingConfigs();
video_plotting_configs.vertical_flip = 1;

total_walks = 0;
for det = 1:length(configs.detectors)
    detector = configs.detectors{det};
    csvs = dc.GetWalksList(detector);
    total_walks = total_walks + length(csvs);
    
end
table_row = 0;

for det = 1:length(configs.detectors)

    if configs.console_log_level > 0
        fprintf('starting discontiuities for %s: ', detector);
    end
    detector = configs.detectors{det};
    flip_detail_all_tables_detector = table();
    discont_detail_all_tables = table();

    % Find all of the walks in the root folder
    csvs = dc.GetWalksList(detector);
    
    detector_root_out = fullfile(dc.output_folder, detector);
    % Set up output csv's
    flipped_walks_output_file = fullfile(dc.output_folder, "flipped_walks.csv");
    flipped_walks_detailed_output_file = dc.flipped_walks_detailed_output_file; % Used in flip analysis so gets named class member
    flipped_walks_detailed_output_file_detector = fullfile(dc.output_folder, detector +  "_flipped_walks_details.csv");
    discont_detail_all_file = fullfile(dc.output_folder, detector +  "_discountinuity_walks_details.csv");
%     conf_all_file = fullfile(dc.output_folder, "/joint_conf_all" + detector +  ".csv");
    conf_all_file_summary = fullfile(dc.output_folder, "joint_conf_summary.csv");
%     conf_all_file_comb = fullfile(dc.output_folder, "/joint_conf_all_combined_" + detector +  ".csv");
    
    
    
    additional_data.all_confs_by_joint = struct();
    additional_data.all_confs_detector = [];
    
    
%     fields = getSkelFields(configs.is_kinect, detector);
    
    flipped_walks_csv = {};
    flipped_walks_details = {};
    
    for i = 1:length(csvs)
        table_row = table_row + 1;
        if mod(i, 10) == 0 % && configs.console_log_level > 1
            i
        end
        i 
        % Load the file of interest
        csv_file = csvs(i);
        full_file = strcat(csv_file.folder, filesep, csv_file.name);
        T = readtable(full_file);
        
        
        output_csv_base =  fullfile(dc.output_folder, detector, "raw");
        if ~exist(output_csv_base, 'dir')
            mkdir(output_csv_base);
        end
        
        if ~exist(detector_root_out, 'dir') && (dc.export_vids || dc.export_vids_with_flips)
            mkdir(detector_root_out);
        end
        
        
        % Setting up export paths
        vid_name_all = strsplit(csv_file.name, '.');
        vid_name_no_ext = csv_file.name;
        vid_name = strcat(vid_name_no_ext, ".avi");
        vid_path = fullfile(detector_root_out, vid_name);
        vid_path_flipped = fullfile(detector_root_out, strcat(vid_name_no_ext, "_flipped", ".avi"));
        
        
        full_vid_name = strcat(vid_name_all{1}, '.',  vid_name_all{2});

        cur_file_output_csv = strcat(output_csv_base, filesep, vid_name_all{1}, '.',  vid_name_all{2});
        if length(vid_name_all) == 3
            cur_file_output_csv = strcat(cur_file_output_csv, '.', vid_name_all{3});

        end
        
        [skel, additional_data]= table2skel(T, dc.export_conf, configs.is_kinect, additional_data);
        
        
        
        
        vid_configs = struct();
        vid_configs.walk_name = full_vid_name;
        try
        vid_configs.fps = T.fps(1);
        catch
            vid_configs.fps = 30;
        end
        
        vid_configs.fields = getSkelFields(configs.is_kinect, detector);
        
        % This doesn't actually interpolate at this step (only after
        % flipping is done in the next step
        [interpolated_skel, discont_fixed_skel, discontinuity_detail_table] = findDiscontinuitiesAndInterpolate(skel, detector, vid_configs, configs);
        if (isempty(discont_detail_all_tables))
           discont_detail_all_tables = [discont_detail_all_tables; discontinuity_detail_table];
           cell_data = table2cell(discontinuity_detail_table);
           repeated_data = repmat(cell_data, [total_walks - 1, 1]);
           discont_detail_all_tables = [discont_detail_all_tables;repeated_data];
        else
           discont_detail_all_tables(table_row, :) = discontinuity_detail_table;
        end
        writetable(discont_detail_all_tables,discont_detail_all_file);
        

        
        
        % Now fix the flips
        [flips_in_walk, flip_details, flipped_skel, flip_detail_table] = flipAnalysisAuto(discont_fixed_skel, configs, full_vid_name, detector);
        [flips_in_walk2, flip_details2, flipped_skel2, flip_detail_table2] = flipAnalysisAuto(flipped_skel, configs, full_vid_name, detector);
        flip_detail_table_with_detector = [table(string(detector), 'VariableNames', {'detector'}) flip_detail_table];
%         flip_detail_all_tables = [flip_detail_all_tables; flip_detail_table_with_detector];
%         flip_detail_all_tables_detector = [flip_detail_all_tables_detector; flip_detail_table];
        
        if (isempty(flip_detail_all_tables))
           flip_detail_all_tables = [flip_detail_all_tables; flip_detail_table_with_detector];
           cell_data = table2cell(flip_detail_table_with_detector);
           repeated_data = repmat(cell_data, [total_walks- 1, 1]);
           flip_detail_all_tables = [flip_detail_all_tables;repeated_data];
           
           flip_detail_all_tables_detector = [flip_detail_all_tables_detector; flip_detail_table];
           cell_data = table2cell(flip_detail_table);
           repeated_data = repmat(cell_data, [total_walks - 1, 1]);
           flip_detail_all_tables_detector = [flip_detail_all_tables_detector;repeated_data];  
           
        else
           flip_detail_all_tables(table_row, :) = flip_detail_table_with_detector;
           flip_detail_all_tables_detector(table_row, :) = flip_detail_table;        
        end
        
        
        writetable(flip_detail_all_tables,flipped_walks_detailed_output_file);
        writetable(flip_detail_all_tables_detector,flipped_walks_detailed_output_file_detector);
        
        if dc.do_second_pass_after_auto_flip
            flipped_skel_once = flipped_skel;
            [~, discont_fixed_skel2, discontinuity_detail_table] = findDiscontinuitiesAndInterpolate(flipped_skel2, detector, vid_configs, configs, 1);
            flipped_skel = discont_fixed_skel2;
        end
%         figure, subplot(2, 1, 1), hold on, plot(discont_fixed_skel2.LAnkle(:, 1)), plot(discont_fixed_skel2.RAnkle(:, 1)), title("Fixed")
%         subplot(2, 1, 2), hold on, plot(flipped_skel.LAnkle(:, 1)), plot(flipped_skel.RAnkle(:, 1))
%         
% 
%         
        % Export the skeleton now that we've fixed the discontinuities and
        % flips
        T = updateTableWithSkelData(flipped_skel, T,configs.is_kinect, configs.is_3d);
        writetable(T, cur_file_output_csv);
        
        if flips_in_walk
            flipped_walks_csv{end+1} = string(csv_file.name);
            flipped_walks_details{end+1} = flip_details;
            
            flipped_walks_table = cell2table(flipped_walks_csv', 'VariableNames',{'Walk'});
            flipped_walks_details_table = cell2table(flipped_walks_details', 'VariableNames',{'Details'});
            
            % Combine the two tables
            table_to_export = [flipped_walks_table flipped_walks_details_table];
            writetable(table_to_export,flipped_walks_output_file);
            
            % Plot the flipped skel
            if ~exist(vid_path_flipped, 'file')  && dc.export_vids_with_flips
                try
                    input_data.input_skel = flipped_skel;
                    input_data.fps = T.fps(1);
                    input_data.start_frame = T.start_frame(1);
                    input_data.detector = detector;
                    plotSkelVideo(video_plotting_configs, input_data, vid_path_flipped);
                catch
                    fprintf("FAILED to make video for: %s\n", vid_path_flipped);
                end
                
                try
                input_data.input_skel = interpolated_skel;
                input_data.fps = T.fps(1);
                input_data.start_frame = T.start_frame(1);
                input_data.detector = detector;
                plotSkelVideo(video_plotting_configs, input_data, vid_path);
            
                
            catch
                fprintf("FAILED to make video for: %s\n", vid_path);
            end
                
                
            else
                if configs.console_log_level > 2 && dc.export_vids_with_flips
                    fprintf("ALREADY MADE video for: %s\n", vid_path_flipped);
                end
                
            end
        end
        
        % Save the original skel
        if ~exist(vid_path, 'file') && dc.export_vids
            try
                input_data.input_skel = interpolated_skel;
                input_data.fps = T.fps(1);
                input_data.start_frame = T.start_frame(1);
                input_data.detector = detector;
                plotSkelVideo(video_plotting_configs, input_data, vid_path);
                
                
            catch
                fprintf("FAILED to make video for: %s\n", vid_path);
            end
        else
            if configs.console_log_level > 2 && dc.export_vids
                fprintf("ALREADY MADE video for: %s\n", vid_path);
            end
        end
        
        
        if dc.export_plots
            outputfile_origfig = fullfile(detector_root_out, strcat(vid_name_no_ext, "_A_ORIG", ".png"));
            outputfile_flipfig = fullfile(detector_root_out, strcat(vid_name_no_ext, "_B_FLIPPED", ".png"));
            outputfile_flipfig2 = fullfile(detector_root_out, strcat(vid_name_no_ext, "_C_FLIPPED_TWICE", ".png"));
            outputfile_flipfigdiscont = fullfile(detector_root_out, strcat(vid_name_no_ext, "_D_FLIPPED_TWICE_and_2nd_DISCONT", ".png"));
            
            plotXPositions(skel, outputfile_origfig);
            plotXPositions(flipped_skel, outputfile_flipfigdiscont); 
            plotXPositions(flipped_skel2, outputfile_flipfig2);
            plotXPositions(flipped_skel_once, outputfile_flipfig);
        end
        
        
    end % end all walks for this detector
    
    % Summary statistics for this detector
    output_joint_stats = struct();
    stats = fieldnames(additional_data.all_confs_by_joint);
    for s = 1:length(stats)
        stat = stats{s};
        
        data = additional_data.all_confs_by_joint.(stat);
        output_joint_stats.(strcat(stat, "_mean")) = mean(data, 'omitnan');
        output_joint_stats.(strcat(stat, "_10_percentile")) = quantile(data,0.1);
        output_joint_stats.(strcat(stat, "_25_percentile")) = quantile(data,0.25);
        output_joint_stats.(strcat(stat, "_50_percentile")) = quantile(data,0.5);
        output_joint_stats.(strcat(stat, "_75_percentile")) = quantile(data,0.75);
        output_joint_stats.(strcat(stat, "_90_percentile")) = quantile(data,0.9);
    end
    
    
    try
        conf_all_file_summary_table = [conf_all_file_summary_table; table(string(detector), 'VariableNames', {'detector'}), struct2table(output_joint_stats)];
    catch
    end
    writetable(conf_all_file_summary_table,conf_all_file_summary);
    
end
end %end function

