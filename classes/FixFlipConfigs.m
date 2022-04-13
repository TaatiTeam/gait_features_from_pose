classdef FixFlipConfigs
   
    properties
        input_folder
        output_folder
        dataset
        input_csv
        output_csv
        
        skip_if_output_file_exists = 1          % Should we skip files that we already have the output for? This
                                                % prevents us from re-fixing files we already fixed before

        % Joints to flip. These should have both Left and Right -
        % DEPRECATED (now load from getKeypointOrderinCSV
        joints = {"Shoulder", "Elbow", "Wrist", "Eye", "Hip", "Knee", "Ankle", "Ear"};
        force_label_all = 0;

    end
    
    methods
        % Constructor
        function obj = FixFlipConfigs(dataset, input_folder,output_folder, input_csv)
            obj.input_folder = input_folder;
            obj.output_folder = output_folder;
            obj.input_csv = input_csv;
            obj.dataset = dataset;
            obj.output_csv = fullfile(output_folder, 'all_flipped_walks_details.csv');
        end
       
    end
end

