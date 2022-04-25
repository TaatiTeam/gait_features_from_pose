classdef GaitFeatureConfigs
   
    properties
%         footfall_methods = ["manual", "DBSCAN", "original"];         
        footfall_methods = ["DBSCAN"];    % "DBSCAN" works for 2D and 3D. "original" is for 2D data only
        output_root;
        raw_or_filt = 'processed';    % if using preprocessed or filtered data, set this to 'processed' and place .csv files with trajectories in subfolder with same name
        filter_cutoff = 8; % hz, only used if we use raw (non-prefiltered) data
        manual_step_root;
        
        % DBSCAN specific parameters 
        strel_size;
        eps_spatial;
        eps_temporal;
        min_pts;
        drop_first_n = 0;      % How many steps at the beginning to discard. Set this to a small positive number if you have reason to believe the first several steps will be poorly tracked (ie. person is very far away)
        
        dataset;

    end
    
    methods
        % Constructor
        function [obj] = GaitFeatureConfigs(footfall_methods_in, dataset)
            obj.footfall_methods = footfall_methods_in;
            obj.dataset = dataset;
            obj.setConstants(dataset);
        end
        
        
        function [obj] = setOutputRoot(obj, output_dir)
            obj.output_root = output_dir;
            if ~exist(obj.output_root, 'dir')
                mkdir(obj.output_root);
            end
            

            
        end
        
        function obj = setConstants(obj, dataset, detector)
            if nargin < 3
                detector = "unknown"; %Use if there are additional configs for different detectors
            end
            % Set the joining constants based on the dataset
            if strcmp(dataset, "TRI")
                obj = obj.setTRIConstants();
%             elseif strcmp(dataset, "CUSTOM")  %TODO: change this
%                 obj = obj.setCustomConstants();
            elseif strcmp(detector, 'romp')
                    obj = obj.setCustomConstants_romp();              
            else
                error('ERROR: %s is not defined in GaitFeatureConfigs', dataset);
            end
        end
        
       
    end
    
    % Private methods
    methods (Access = private)
        function [obj] = setTRIConstants(obj)
            obj.strel_size = 3;         % threshold for minimum value between stances (anything smaller is combined together)
            obj.eps_spatial = 0.05;     % spatial 'closeness' constant 
            obj.eps_temporal = 0.6;     % temporal 'closeness' constant (seconds)
            obj.min_pts = 10;           % minimum points in cluster
        end

        function [obj] = setCustomConstants(obj)
            obj.strel_size = 3;
            obj.eps_spatial = 0.05;
            obj.eps_temporal = 0.6;
            obj.min_pts = 10;
            obj.drop_first_n = 3;
        end
        
        % Sample config that is different for a dataset/tracker combo
        function [obj] = setCustomConstants_romp(obj)
            obj.strel_size = 3;
            obj.eps_spatial = 0.07;
            obj.eps_temporal = 0.4;
            obj.min_pts = 8;
        end
        


    end
    
    
end

