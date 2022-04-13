function [fields, fields_struct] = getSkelFields(is_kinect, detector)
fields_struct = struct();

if is_kinect
    
    fields = {'Sacr', 'Spine', 'c7', 'Head', 'LShoulder', ...
        'LElbow', 'LWrist', 'LHand', 'RShoulder', 'RElbow', ...
        'RWrist', 'RHand', 'LHip', 'LKnee', 'LAnkle', 'LFoot', ...
        'RHip', 'RKnee', 'RAnkle', 'RFoot', 'SpineShoulder', ...
        'LHandTip', 'LThumb', 'RHandTip', 'RThumb'};
    
    fields_struct.left_joints = {'LShoulder', 'LElbow', 'LWrist', 'LHip', 'LKnee', 'LAnkle'};
    fields_struct.right_joints = {'RShoulder', 'RElbow', 'RWrist', 'RHip', 'RKnee', 'RAnkle'};
    fields_struct.joints_all = {'Shoulder', 'Elbow', 'Wrist', 'Hip', 'Knee', 'Ankle'};
    fields_struct.is_lower_body = [0, 0, 0, 1, 1, 1]; % this cooresponds to the left_joints struct
    
    
else % 2D Detectors
%     fields = {'Nose', 'LEye', 'REye', 'LEar', ...
%         'REar', 'LShoulder', 'RShoulder', 'LElbow', ...
%         'RElbow', 'LWrist', 'RWrist', 'LHip', ...
%         'RHip', 'LKnee', 'RKnee', 'LAnkle', ...
%         'RAnkle'};
%     
    fields = getKeypointOrderInCSV(detector);

    fields_struct.left_joints = {'LShoulder', 'LElbow', 'LWrist', 'LHip', 'LKnee', 'LAnkle'};
    fields_struct.right_joints = {'RShoulder', 'RElbow', 'RWrist', 'RHip', 'RKnee', 'RAnkle'};
    fields_struct.joints_all = {'Shoulder', 'Elbow', 'Wrist', 'Hip', 'Knee', 'Ankle'};
    fields_struct.is_lower_body = [0, 0, 0, 1, 1, 1]; % this cooresponds to the left_joints struct
    
    
%     if strcmp(detector, 'romp')
% 
%     end
%     
end

end

