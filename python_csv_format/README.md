## Preparing Data for Use with Matlab
Pose-estimation libraries output results in a variety of different formats which can be used by Matlab with varying levels of success.
Therefore, for backwards (and future) compatibility, we have elected to preprocess all output from the pose-estimation libraires and output a consistent format for use witht Matlab code. 
This directly contains raw output we have generated from AlphaPose, Detectron, and OpenPose, as well as a Python script for formatting everything to a consistent format.  
*Please note that you will need to modify this Python file to work with your input data format*

### Data Format Required for Matlab
A flat, plaintext format is required for use with Matlab. 
- This format begins with the frame number (beginning at 1 to match Matlab indexing) followed by an underscore: `_`. 
- Next, the joints are listed in order in the format (`x_coordinate,y_coordinate,confidence`). Subsequent joints are also separated by commas: `,`. The order of the keypoints is defined in `utils/getKeypointOrderInCSV.m` and can vary by detector. If you are adding a new detector, ensure that the order of  the keypoints are changed in this Matlab file as well. 
- If multiple people are detected within a frame, the next person is separated with a semi-colon: `;`. Then the joint positions and confidence scores are provided. Note that the frame number is not repeated. 

```
1_joint1x,joint1y,joint1conf,joint2x,joint2y,joint2conf...;                                                                                                      # One person in frame
2_joint1x,joint1y,joint1conf,joint2x,joint2y,joint2conf...;joint1x_person2,joint1y_person2,joint1conf_person2,joint2x_person2,joint2y_person2,joint2conf_person2 # Two people in frame
3_                         # No people in frame

```

