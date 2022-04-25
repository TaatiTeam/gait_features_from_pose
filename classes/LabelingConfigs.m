classdef LabelingConfigs
    % Variables and function associated with labelling walks and joining to
    % trajectories
    % TODO: consider rewritting to use dataset classes, but for now,
    % everything is in one file to allow for easier comparison between
    % configurations/datasets
    
    properties
        % Paths
        input_folder
        output_folder
        split_csv
        
        % Configurations about implementation
        is_vertical = 0
        dataset
        
        save_epart_files = 1
        search_Eparticipant_files = 1
        skip_if_epart_file_exists = 0
        
        %  ============================Advanced usage =====================
        % (if you want to modify temporal joining parameters directly).
        % Modifying the properties here is good for experimenting, but once
        % a good configuration is found, name it and add it to the class
        % permanently (bottom of this file)
        subsequent_frame_skel_closeness_thres
        conf_thres
        closeness_based_on_lower_body     % Should we only consider joints in the lower body (those more important in gait analysis)
        smoothing_window_size
        label_using_3d = 0;
        norm_by_hip = 0;                  % Normalize the distance between subsequent frames by the hip distance (so tighter threshold when person is far away)
    end
    
    % Public methods
    methods
        function obj = LabelingConfigs(dataset, input_data_path, output_data_path)
            % LabelingConfigs Construct an instance of this class
            obj.dataset = dataset;
            obj.input_folder = input_data_path;
            obj.output_folder = output_data_path;
        end
        
        function [walks] = GetWalksList(obj)
            walks = [];
            if strcmp(obj.dataset, "TRI")
                walks = GetSubDirsSecondLevelOnly(obj.input_folder, "AMB");
            elseif strcmp(obj.dataset, "Belmont")
                % TODO
            elseif strcmp(obj.dataset, "PD_Fasano")
                walks = GetSubDirsSecondLevelOnly(obj.input_folder, "PD");
            elseif strcmp(obj.dataset, "Dravet_homevids")
                
                directions = ["vertical", "horizontal"];
                types = ["DV_"];
                for d = 1:length(directions)
                    direct = directions(d);
                    for t = 1:length(types)
                        type = types(t);
                        walks_temp = GetSubDirsSecondLevelOnly(fullfile(obj.input_folder, direct), type);

                        walks_to_append = arrayfun(@(x) fullfile(direct, x),walks_temp);
                        walks = [walks, walks_to_append];
                    end
                end

            end
        end
        
        function [obj] = RefreshJoiningConstants(obj, detector, is_3d)
            % Set the joining constants based on the dataset
            if strcmp(obj.dataset, "TRI")
                obj = obj.setTRIConstants();
            elseif strcmp(obj.dataset, "Belmont")
                obj = obj.setBelmontConstants();
            elseif strcmp(obj.dataset, "PD_Fasano")
                if is_3d
                    obj = obj.setFasanoPDConstants3D();
                else
                    obj = obj.setFasanoPDConstants();
                end
            elseif strcmp(obj.dataset, "Dravet_homevids")
                obj = obj.setDravetHomeVidsConstants();
            end
            
            
            % conf threshold
            obj.conf_thres = getConfThres(detector);
        end
        
        
        
        % TODO: finish this if needed
        function obj = SetJoiningConstants(obj, dataset_name)
            if strcmp(dataset_name, "TRI")
            elseif strcmp(dataset_name, "Belmont")
            end
        end
        
    end % end public methods
    
    % Private methods
    methods (Access = private)
        function [obj] = setTRIConstants(obj)
            %threshold for mean value of diff from one frame to another 
            obj.subsequent_frame_skel_closeness_thres = 30;
            obj.closeness_based_on_lower_body = 1;
            obj.smoothing_window_size = 10;
        end
        
        % OLD
        function [obj] = setTRIConstantsOld(obj)
            %threshold for mean value of diff from one frame to another
            obj.subsequent_frame_skel_closeness_thres = 600;
            obj.closeness_based_on_lower_body = 0;
            obj.smoothing_window_size = 5;
        end
        
        
        function [obj] = setBelmontConstants(obj)
            %threshold for mean value of diff from one frame to another 
            obj.is_vertical = 1;
            obj.subsequent_frame_skel_closeness_thres = 90;
            obj.closeness_based_on_lower_body = 0;
            obj.smoothing_window_size = 10; 
        end
        
        function [obj] = setFasanoPDConstants(obj)
            %threshold for mean value of diff from one frame to another 
            obj.subsequent_frame_skel_closeness_thres = 30;
            obj.closeness_based_on_lower_body = 1;
            obj.smoothing_window_size = 20;
        end
        
        function [obj] = setFasanoPDConstants3D(obj)
            %threshold for mean value of diff from one frame to another
            obj.subsequent_frame_skel_closeness_thres = 0.75;
            obj.closeness_based_on_lower_body = 1;
            obj.smoothing_window_size = 20;
            obj.label_using_3d = 0;
            obj.norm_by_hip = 1;
        end
        
        function [obj] = setDravetHomeVidsConstants(obj)
            %threshold for mean value of diff from one frame to another 
            obj.subsequent_frame_skel_closeness_thres = 30;
            obj.closeness_based_on_lower_body = 1;
            obj.smoothing_window_size = 20;
        end        

    end
    
    
end

