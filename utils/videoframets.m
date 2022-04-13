function ts=videoframets(varargin)
    %VIDEOFRAMETS Find timestamps associated with frames in an mpeg file
    %[v0.1, by David Bulkin, 1/22/2017]
    %
    %   ts = VIDEOFRAMETS(ffmpeg_path,videofile) returns the timestamps (ts) in seconds of 
    %   each video frame in a video file (videofile) using ffmpeg.exe. The location of 
    %   ffmpeg.exe must be specified (ffmpeg_path; i.e. it can not just reside on the 
    %   matlab path).
    %
    %   VIDEOFRAMETS(ffmpeg_path,videofile,ffmpeg_textfile) will store the raw output 
    %   produced by ffmpeg in the text file 'ffmpeg_textfile'
    %
    %   FFMPEG is freely available can be downloaded from: 
    %       <a href="matlab:web('http://ffmpeg.org/')">http://ffmpeg.org/</a>
    %
    %   Tested on Windows, with ffmpeg 2.5.2 and 3.2.2
    %       I think this should work on OSX/UNIX, because the pipe to file commands are
    %       the same, but I haven't tested it.
    %
    %   EXAMPLE:
    %       ffpath='C:\ffmpeg\bin'
    %       vidfile='D:\videos\somevideo.mpeg'
    %       ts=videoframets(ffpath,somevideo);
    %       hist(1./diff(ts),1000);  %this shows a distribution of the actual frame rates
    %       
    %
    %   Notes on why this is useful:
    %     VIDEOFRAMETS attempts to solve an issue with quantitative video analysis. While 
    %   mpeg video is recorded with a fixed framerate, in reality, video frames often 
    %   deviate from this value. [I think this is due to delays in the encoder, for 
    %   instance if the computer recording video is under excessive load, frames will come 
    %   in slower]. If frames often come in a little bit slower than expected (empirical 
    %   framerate < nominal framerate), the problem compounds over the course of a video: 
    %   if a user assumes a fixed framerate the data at the end of the video will be 
    %   greatly mismatched from reality.
    %     This presents a tremendous problem to time locked video analysis. Matlab's 
    %   VideoReader offers a practical solution: VideoReader objects contain a property 
    %   that identifies/sets the current time in the video. This is generally a practical 
    %   solution to the problem (note: when used with the newer .readFrame method rather 
    %   than the older .read method). However, this has some limitations: 
    %       1: It is often useful to know the number of frames and the corresponding 
    %       timestamps at the onset of video analysis (although a rough estimate is 
    %       obtainable using the .FrameRate and .Duration properties of VideoReader, 
    %       typically adequate for initializing variables). 
    %       2: The performance of vision.VideoFileReader is often orders of magnitude 
    %       faster than VideoReader (from personal measurements, speed improvements 
    %       depend on codec), and seems to work more reliably with a wider set of video 
    %       files. However, vision.VideoFileReader offers no strategy for assessing 
    %       frame times. Using VideoReader for timing and vision.VideoFileReader for frame 
    %       data is impractical because it sacrifices the advantages of using the 
    %       vision.VideoFileReader function
    %       3: It may be useful to some users to get timing information only, for instance 
    %       if performing video analysis elsewhere. 
    %
    %     The times of frames are stored in the MPEG file using presentation timestamps 
    %   (PTS; frequently used for alignment of video and auditory streams). While these 
    %   are inaccessible to the high level Matlab coder, the tool ffmpeg readily provides 
    %   their values, and runs pretty quickly (in testing, 50 seconds for a 20 minute 
    %   MPEG file, while VideoReader gets the same information in about 6 minutes).
    %
    %   See also: VideoReader vision.VideoFileReader

%% Check inputs:
p=inputParser;
addRequired(p,'ffm_fp',@(x) validateattributes(x,{'char'},{'nonempty'},'VIDEOFRAMETS','ffmpeg_path',1))
addRequired(p,'vid_fn',@(x) validateattributes(x,{'char'},{'nonempty'},'VIDEOFRAMETS','videofile',2))
addOptional(p,'txt_fn',tempname,@(x) validateattributes(x,{'char'},{'nonempty'},'VIDEOFRAMETS','ffmpeg_textfile',23))
parse(p,varargin{:})

%Further checks (with useful error messages)
% ffm=fullfile(p.Results.ffm_fp,'ffmpeg');
ffm = p.Results.ffm_fp;
if exist(ffm,'file')~=2
    error('Could not find ffmpeg.exe in %s',p.Results.ffm_fp);
end

if exist(p.Results.vid_fn,'file')~=2
    error('Could not find the video file %s',p.Results.vid_fn);
end

%% Call FFMPEG with appropriate flags:
%a few notes on the ffmpeg command:
%       1: It's apparently quicker to have ffmpeg pipe the output to a text file and 
%       have matlab read the text file, rather than to just have matlab read the output
%       from system (that's really surprising to me!). It's actually orders of 
%       magnitude faster (?)
%
%       2: in my tests with ffmpeg, I found that ffmpeg's showinfo surprisingly seems to 
%       put its output into the stderr output (i.e. use 2> rather than >)...this took me
%       FOREVER to figure out!
ffm_line=sprintf('"%s" -i "%s" -f null -vf showinfo - 2>%s',ffm,p.Results.vid_fn,p.Results.txt_fn);
fprintf('Processing %s\n',p.Results.vid_fn);
system(ffm_line);

%% Because output was sent to a file, now it must be read back in...
%There's a challenge with reading the file output: textscan() won't work well with the
%file format, nor will any of the other high level readers. fgetl() is probably the best
%bet, but it's challenging to initialize ts, as it's unclear how many lines the file will
%contain (and non-header lines are allowed to not include timestamp info). My best 
%solution is to run through once to get the number of lines (that contain frame times) in 
%the file, and then run through again to get the actual times:

fid=fopen(p.Results.txt_fn);

%count the number of lines containing frame times (i.e. number of frames)
i=0;
tline=1;
while tline~=-1
    tline=fgetl(fid);
    startloc=strfind(tline,'pts_time:')+numel('pts_time:');
    if ~isempty(startloc)
        i=i+1;
    end
end


ts=nan(i,1);
frewind(fid)
tline=0;i=1;
while tline~=-1
    tline=fgetl(fid);
    startloc=strfind(tline,'pts_time:')+numel('pts_time:');
    if ~isempty(startloc)
        endloc=strfind(tline,' pos:');
        ts(i)=str2double(tline(startloc:endloc));
        i=i+1;
    end
end
fclose(fid);

%% Finally, just delete any temporary files
if ~isempty(p.UsingDefaults)
    delete(p.Results.txt_fn)
end
