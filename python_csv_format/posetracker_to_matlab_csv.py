# posetracker_to_matlab_csv.py
""" 
This file is intended to serve as an example for how output files from pose-estimation
libraries can be reformatted for use with the Matlab. This reformat was originally performed
because the Matlab utilities were inconsistent in their parsing of the json and/or pkl
files output by the pose-estimation libraries used by our group. 
This file is intended to be modified to account for the file structure of your data and 
the any custom data output files that you may have generated in the process of pose-estimation.
"""

import os
import json
import glob

def formattedDictToList(formatted_data):
    # Now format the data to the output string format
    largest_frame_num = max(formatted_data.keys())
    # Set up the output format
    output_list = [str(i + 1) + "_" for i in range(largest_frame_num+1)]    

    for frame_num, frame_data in formatted_data.items():
        frame_data_formatted = ";".join([",".join(person_data) for person_data in frame_data])
        output_list[frame_num] += frame_data_formatted

    return output_list


def detectron_to_csv(json_file):
    with open(json_file, 'r') as f:
        data = json.load(f)

    # convert keys to ints
    formatted_data_temp = {int(key): data[key] for key in data.keys()}

    formatted_data = {}
    # flatten the sublists and convert to strings
    for key, val in formatted_data_temp.items():
        flat_data = []
        for person_data in val:
            flat_person = [str(item) for sublist in person_data for item in sublist]
            flat_data.append(flat_person)
        formatted_data[key] = flat_data
    return formattedDictToList(formatted_data)


def openposeJSON_to_csv(input_folder):
    ''' This function converts the json files into a single CSV file that
    will be parsed by Matlab'''

    all_files = os.listdir(input_folder)
    json_files = [f for f in all_files if '_keypoints.json' in f]

    # Determine the largest frame number, this handles the case
    # when there are missing frames in the middle where we cannot rely on 
    # a consecutive sequence of frame numbers
    largest_frame_num = 0

    for f in json_files:
        name_parts = f.split('_')
        frame_num = int(name_parts[-2])
        if frame_num > largest_frame_num:
            largest_frame_num = frame_num

    # Set up the output format
    output_list = [str(i + 1) + "_" for i in range(largest_frame_num+1)]

    for f in json_files:
        # print(f)
        name_parts = f.split('_')
        frame_num = int(name_parts[-2])
        with open(os.path.join(input_folder, f)) as json_file:
            data = json.load(json_file)
            frame_data = ''
            for person in data['people']:
                person_data = person['pose_keypoints_2d']
                # Convert to string so we can join and write to file
                person_data = [str(position) for position in person_data] 
                person_data = ",".join(person_data)
                if len(frame_data) > 0:
                    person_data = ";" + person_data
                frame_data += person_data

            output_list[frame_num] += frame_data

    return output_list


def alphaposeJSON_to_csv(json_file):
    ''' This function converts the json files into a single CSV file that
    will be parsed by Matlab'''

    # Determine the largest frame number, this handles the case
    # when there are missing frames in the middle where we cannot rely on 
    # a consecutive sequence of frame numbers
    with open(json_file, 'r') as f:
        data = json.load(f)

    # Reformat the JSON so that we have one key per image
    formatted_data = {}

    for item in data:
        image_name = item['image_id']

        # Strip this to be the number of the image
        image_name = int(image_name.split('.')[0])

        string_keypoints = [str(i) for i in item['keypoints']]
        if image_name not in formatted_data:
            formatted_data[image_name] = [string_keypoints]
        else:
            formatted_data[image_name].append(string_keypoints)


    return formattedDictToList(formatted_data)


def cleanForMatlab(input_data, det):
    if det == 'alphapose':
        return alphaposeJSON_to_csv(input_data)
    elif det == 'openpose':
        return openposeJSON_to_csv(input_data)
    elif det == 'detectron':
        return detectron_to_csv(input_data)

    raise ValueError("UNKNOWN DETECTOR")


def writecsv(data, outfile):
    with open(outfile, 'w') as f:
        f.write("\n".join(data))


def findInputFiles(input_root, det, OUT_SUBFOLDERS):
    search_string = str(os.path.join(input_root, "**", OUT_SUBFOLDERS[det]))
    search_string = str(os.path.join(input_root, OUT_SUBFOLDERS[det]))
    print(search_string)
    res = glob.glob(search_string, recursive=True)
    return res



if __name__ == '__main__':
    input_root = r".\sample_raw_input"
    output_root = r".\sample_output"
    file_locs_file = 'filelocs.json'

    OUT_SUBFOLDERS = {'openpose': r"*\*\openout", 'alphapose': r"*\*\alphaout\alphapose-results.json", 'detectron': r"*\*\Detectron2_out\detectron_out.json"}      # Reference
    OUTPUT_NAMES = {'openpose': "openpose.csv", 'alphapose': "alphapose-results.csv", 'detectron': 'output_detectron.txt'}        # This is to match what is expected by the MATLAB code
    STRIP_LEVELS = {'openpose': 1, 'alphapose': 2, 'detectron': 2}                                                                # This is to match what is expected by the MATLAB code


    dets_to_process = ['detectron', 'alphapose', 'openpose']
    file_locs = {}
    for det in dets_to_process:
        input_files = findInputFiles(input_root, det, OUT_SUBFOLDERS)
        file_locs[det] = input_files

    for det in dets_to_process:
        print('processing: ', det)
        input_files = file_locs[det]
        num_files = len(input_files)
        i = 0
        for input_file in input_files:
            i += 1
            print(i, "/", num_files)

            # Format the output file
            output_file = input_file.replace(input_root, output_root)
            output_folder = (os.sep).join(output_file.split(os.sep)[:-STRIP_LEVELS[det]])
            output_file = os.path.join(output_folder, OUTPUT_NAMES[det])
            
            if os.path.exists(output_file):
                continue

            os.makedirs(output_folder, exist_ok=True)
            clean_data = cleanForMatlab(input_file, det)
            writecsv(clean_data, output_file)
    