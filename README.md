# Preamble
This repository contains MATLAB code used to calculate gait features from joint trajectories (obtained using human pose-estimation libraries, currently OpenPose, AlphaPose and Detectron). The gait features can be used for downstream analyses, including as input to our ST-GCN models for assessing parkinsonism severity in gait: https://github.com/TaatiTeam/stgcn_parkinsonism_prediction.

# Installation
This project requires MATLAB (tested with R2020b on Windows 10 and Ubuntu 20.04). The following toolboxes are also needed:

```
image_toolbox
signal_toolbox
statistics_toolbox
```

After opening MATLAB, ensure that all subfolders are added to the path (right-click on folder names in Current Folder tab on left of UI, then select "Add to Path -> Selected Folders and Subfolders")

This library is intended to run using MATLAB utilities, but on Ubuntu (and less frequently on Windows), the built-in MATLAB video reading/writing may fail for some video formats. If this happens, you will need to install ffmpeg and add the path to the MATLAB script where marked. 

# Data Preparation
*Note: A future update to this repository will include instructions on how to use this library to process output from 2D pose-estimation libraries (OpenPose, AlphaPose, Detectron) to  create trajectories of joint positions and select the one that corresponds to the participant of interest.*

This release assumes that you have already extracted joint trajectories using a human pose-estimation library and have preprocessed it to create a clean trajectory representing the person of interest. An example of the sample input data format can be found in the `sample_data/FINAL_trajectories` folder. Note that we have provided examples of both raw (uninterpolated and unfiltered) and interpolated versions of the trajectories. It is not necessary to provide both, but you should provide at least one and specify which one to use in `calculate_features_main.m`.


# Calculation of Gait Features
## Sample Data
After installing MATLAB and preparing all joint trajectories into the format specified in `sample_data/FINAL_trajectories`, you should begin by running the `calculate_features_main.m` file.  
This file is the entry point for the library and should run on the sample data in this repository. If there are no errors and everything runs correctly, you should have two new folders in the `sample_data` directory (`gait_features` and `centred_at_100`).

## Custom Dataset
After confirming that everything is working as expected on the sample dataset, you can add additional configurations for your datasets (if needed). 
To add a custom dataset, begin by uncommenting the following line in `calculate_features_main.m`:
```
dataset_name = "CUSTOM"; 
```
*Note: you will also need to make the appropriate changes to getWalkAndPatientID in the PosetrackerConfigs class to specify how your input CSV files are named*


Next, specify the location of the joint trajectories you would like to process. Note that this should be saved in the **`out_path`** variable (not the `in_path` - this will be used in a future update of this library for processing raw output from the pose-estimation libraries)
```
out_path = "sample_data/";   % Change out_path to the input location of your joint trajectories. Note that they should be placed in a subfolder called `FINAL_trajectories`. 
```

Next, specify the name(s) of the pose-estimation libraries you would like to process. Currently only OpenPose, AlphaPose, and Detectron have been used and tested, but you can add additional detectors here if needed. 
```
configs.detectors = {'alphapose', 'openpose', 'detectron'};  % TODO: change this as needed
```

There are three options for the method of heel-strike detection to use when calculating gait features.
- "original": This method labels the heelstrikes at 35% of the peak vertical velocity of the ankles
- "DBSCAN": This method uses spatial-temporal density-based spatial clustering for applications with noise to identify the heelstrikes
- "manual": This method reads in CSV files with the frames of the heelstrikes in each video. CSV files for this method can be generated manually or using this library: https://github.com/andreasabo-ibbme/step_labeller

The heelstrike annotation method(s) can be selected by changing the following statement: 
```
ft_configs = GaitFeatureConfigs(["DBSCAN", "original"], dataset_name); 
```
Note: For consistency with the models trained in the https://github.com/TaatiTeam/stgcn_parkinsonism_prediction project, the 'original' heel-strike annotation method should be used. 

# Exporting data for ST-GCN models
This library also provides functionality for exporting joint trajectories centred at (100, 100) for use in our pretrained ST-GCN models for parkinsonism prediction. The code to do this is provided at the bottom of the `calculate_features_main.m` file:
```
is_kinect = 0;
is_3D = 0;
export_configs = ExportConfigs(fullfile(out_path, 'centred_at_100'), is_kinect, is_3D);
export_configs.center_hip = 1;
reference_file = fullfile(ft_configs.output_root, "alphapose_original.csv");
centreCSVsat100(configs, export_configs, "raw", reference_file); % This will interpolate and filter the raw (alternatively, can just pass in the clean data and these operations are redundant)
```
The included configuration is for raw joint trajectories (this function will also interpolate and filter the data). We use the calculated gait feature file to read in the identifiers of the partipants and their walks to avoid re-parsing video names. If you did not export gait features with AlphaPose and the "original" heelstrike annotation method, change the `reference_file` to a gait feature file that exists. 

# Citation
Please cite our paper if this library helps your research:
```
@article{sabo2020assessment,
  title={Assessment of Parkinsonian gait in older adults with dementia via human pose tracking in video data},
  author={Sabo, Andrea and Mehdizadeh, Sina and Ng, Kimberley-Dale and Iaboni, Andrea and Taati, Babak},
  journal={Journal of neuroengineering and rehabilitation},
  volume={17},
  number={1},
  pages={1--10},
  year={2020},
  publisher={BioMed Central}
}
```  

# Future releases
Currently, this library provides functionality for calculating gait features from pre-formatted and selected joint trajectories. Future releases will provide example code and documentation for processing raw input from pose-estimation library to create joint trajectories and select the one that corresponds to the participant of interest. 