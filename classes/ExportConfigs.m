classdef ExportConfigs
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        export_base
        normalize_dist
        center_hip
        center_hip_offset = 100; % Only used if center_hip is true
        save_interpolated
        save_raw 
        save_demographics
        save_clinical_scores
        normalization_type = ""
        normalization_upscale_factor = 1000;  % If we don't upscale, we have small values and may lose precision when saving
        
        use_kinect_exports  % Set to kinect fields
        export_2D_kinect    % Kinect fields but only use x and y
        use_romp = 0
    end
    
    methods
        % Constructor
         function obj = ExportConfigs(export_base, is_kinect, is_3d)
            % ExportConfigs Construct an instance of this class
            obj.export_base = export_base;
            
            if is_kinect
                obj = setDefaultKinect(obj);
                if ~is_3d
                    obj.export_2D_kinect = 1;
                end
            elseif is_3d
                obj = setDefault2D(obj);
                obj.use_romp = 1;

            else
                obj = setDefault2D(obj);
            end
         end
        
         
         function [obj] = SetNormalization(obj, normalization_type, center_hip, center_hip_offset)
             obj.normalize_dist = 1;
             obj.normalization_type = normalization_type;
             obj.center_hip = center_hip;
             obj.center_hip_offset = center_hip_offset;
             
             if strcmp(normalization_type, "")
                 obj.normalize_dist = 0;
             end

         end
        
    end % public methods
    
    methods (Access = private)
    
        function obj = setDefault2D(obj)
            obj.normalize_dist = 0;
            obj.center_hip = 0;
            obj.save_interpolated = 1;
            obj.save_raw = 1;
            obj.save_demographics = 1;
            obj.save_clinical_scores = 1;
            obj.normalization_type = "";
            obj.use_kinect_exports = 0;
            obj.export_2D_kinect = 0;
        end
        
        function obj = setDefaultKinect(obj)
            obj.normalize_dist = 0;
            obj.center_hip = 0;
            obj.save_interpolated = 1;
            obj.save_raw = 1;
            obj.save_demographics = 1;
            obj.save_clinical_scores = 1;
            obj.normalization_type = "";
            obj.use_kinect_exports = 1;
            obj.export_2D_kinect = 0;
        end
    end % private methods
end

