% function ThreatVigilance1(subjID, condNum)
%
% if nargin == 0
%     error('Run this function with "ThreatVigilance1(initials, condition)" where condition is an integer 1 to 3.')
% end

clear
close all
sca

PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);

%% User parameters
% Changeable
debug = 0; % Should be 0, 1 sets short trials for testing
use_eyetracker = 1; % Should be 1 for experiment. See below for checks that turn this off
getScreen = 0;
% Screen Number
% 0 = across all screens
% 1 = mirrored screens
% 2 = right screen
%screenNum = max(Screen('Screens'));
screenNum = 1; % 

% Log Command Window for error messages etc.
debugLogging = 0;

% Timings
%baselineTime = 5; % 5 minutes
%baselineTime = baselineTime * 60; % Convert to seconds
fixTime = 1;
sceneTime = 10;
%isiTime = 1; % Need this?fon

% Trial blocks
nBlocks = 3; % Partner, stranger, ball
% nScenes = 15; % Informational: based on files in \ImageSet
nReps = 1;

% Misc
%background = [0 0 0]; % Black
background = [0.5 0.5 0.5]; % Grey

% Fixation cross, new version
fixShape = '+';
fixSize = 10;
%fixColor = [1 1 1]; % White
fixColor = [0 0 0]; % White

%% 
if debug || ~use_eyetracker
    warning('Not run in experiment mode.');
end

% if lsl
%     lib = lsl_loadlib();
%     info = lsl_streaminfo(lib,'PupilLabsT','Gaze',2,120,'cf_float32','');
% end

KbName('UnifyKeyNames');
quitKey = KbName('Escape');

%% User prompts and save file format

% 1
subjID = input('Enter initials or subject ID: ', 's');

% 2
while 1
    imgOrder = input('Image set order (3 digit number, e.g. 123, 231)? ');
    if isempty(imgOrder)
        % Keep empty, prevents it trying to do the next comparison
    elseif any(imgOrder == [123, 132, 213, 231, 312, 321])
        break;
    end
end
imgOrder = num2str(imgOrder);

% 3
conditionOrder = input('Physical condition order (descriptive, e.g. PartnerStrangerBall, PSB)? ', 's');

datecode = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm');
datecode = string(datecode);
%condNum = num2str(condNum);
matFilename = strcat(datecode, '_', subjID, '_', conditionOrder, '_', imgOrder,'_', dbstack().name);
matFilename = fullfile(pwd, 'Results', matFilename);

%% Load Images
imgPath = fullfile(pwd, 'ImageSets', {'Condition 1', 'Condition 2', 'Condition 3'});
addpath(imgPath{:});
imgFmt = '*.jpg'; % Verify

% Creates img, a 3-item struct with filename, image matrices, and image
% count
img = struct();
for ii = 1:3
    imgStruct = dir(strcat(imgPath{ii}, filesep, imgFmt));
    img(ii).names = {imgStruct.name}';
    img(ii).imgMats = cellfun(@imread, img(ii).names, 'UniformOutput', false);
    img(ii).nImages = size(img(ii).imgMats, 1);
end

% Switch order of conditions
% Note: now is a char
switch imgOrder
    case '123'
        % Nothing, keep it
    case '132'
        img = [img(1), img(3), img(2)];
    case '213'
        img = [img(2), img(1), img(3)];
    case '231'
        img = [img(2), img(3), img(1)];
    case '312'
        img = [img(3), img(1), img(2)];
    case '321'
        img = [img(3), img(2), img(1)];
    otherwise
        error('Something is wrong with the trial order (ideally this shouldn''t happen!)');
end

%% Experimental setup

%trials = repmat(imgNames, nBlocks, 1);

% Timing
if debug
    sceneTime = 1; % 1 second each image
    %baselineTime = 1 * 60; % 1 minute at start
    warning('In debug mode with short trials. Turn off for experiment.')
else
    % Defined above
%    sceneTime = 10;
end


% Saved times
nTotalImages = img(1).nImages + img(2).nImages + img(3).nImages;
fixTimes = zeros(nTotalImages,4);
sceneTimes = zeros(nTotalImages,4);
%baselineTimes = zeros(1, 4);





%% Eye tracker check
% Get running programs

% Check if installed (default install location)
et_path = "C:\Program Files (x86)\Pupil-Labs\Pupil v3.5.1\Pupil Capture v3.5.1\";
et_executable = "pupil_capture.exe";

% Path for Powerpoint, testing
%et_path = 'C:\Program Files (x86)\Microsoft Office\root\Office16\POWERPNT.EXE';
%et_executable = 'POWERPNT.EXE' % Test program, remove

% Suppress line numbers in warnings for aesthetics
warning('off', 'backtrace');

% Check running programs
[~, softwareRunning] = system('tasklist');

if ~contains(softwareRunning, et_executable)
    et_check = input(['\nPupil Capture does not appear to be running. This program will freeze dramatically if not running.\n\n', ...
        'Type Y if you want to continue to run in DEBUG mode.\n', ...
        'Type Q (or anything else) to quit so you can open it.\n\n'], 's');
    if ~any(strcmpi(et_check, ["y", "yes"]))
        use_eyetracker = 0;
        return
    else
        use_eyetracker = 0;
    end
end
%% Eye tracking setup
if use_eyetracker
    % Set up paths to Java, this might be already done statically
    JARPATH = 'C:\toolbox\jeromq\target\jeromq-0.6.0-SNAPSHOT.jar';
    javaclasspath(JARPATH);

    % Set up jeromq interface
    import org.zeromq.*
    ctx = ZContext();

    % Set up talking with Pupil Capture, it must be running, and probably
    % recording by this point
    publisher = ctx.createSocket(SocketType.REQ); % REQ socket to talk
    publisher.connect('tcp://127.0.0.1:50020'); % Default IP, shouldn't need to change

    % Start recording, optional
    %publisher.send('R'); % Start recording
    %rtime = publisher.recv(); % == 'O' 'K' if OK
end

%% Start PTB
%if ~debug; HideCursor; end
HideCursor;

if debugLogging
        diary log_VigilanceEyetracking.txt
    end
[win, winRect] = PsychImaging('OpenWindow', screenNum, background);

% Get some info about the setup
% These should be 0, 1 based on our parameters
black = BlackIndex(win);
white = WhiteIndex(win);
gray = (black + white)./2;

% Monitor timing
ifi = Screen('GetFlipInterval', win);
fixFrames = round(fixTime / ifi);
sceneFrames = round(sceneTime / ifi);
%baselineFrames = round(baselineTime / ifi);

% Scaling for images
[xC, yC] = RectCenter(winRect); % Center of monitor
imgSize = size(img(1).imgMats{1});
expRect = winRect(4) / imgSize(1); % Percent to expand image based on max screen height
fullRect = [0 0 imgSize(2) imgSize(1)].*expRect; % Todo fix: the maximum size allowable

texRect = CenterRectOnPointd(fullRect, xC, yC); % Where to actually draw them
% texRect = ScaleRect(texRect, expRect, expRect);

% Text info
textColor = black;
Screen('TextSize', win, 50); % Instructional text. Current version: will not affect fixation size
Screen('TextFont', win, 'Courier');
if use_eyetracker
    txtInstr = 'Eye tracker is ON\nMake sure you are RECORDING\nExperiment Start.\nPush any key to start...';
else
    txtInstr = 'Eye tracker is OFF and will not send time stamps\nExperiment Start.\nPush any key to start...';
end

txtBlock = 'Block end. Press any key to continue...';

% Keyboard stuff
keys = zeros(1,256);
keys(KbName('Escape')) = 1;
KbQueueCreate([], keys) % For now, only Quit key
KbQueueStart;

% Preload image textures
for ii = 1:3
    img(ii).Tex = zeros(1, img(ii).nImages); % Preallocate
    for tex = 1:img(ii).nImages
        img(ii).Tex(tex) = Screen('MakeTexture', win, img(ii).imgMats{tex});
    end
end
topPriorityLevel = MaxPriority(win);
Priority(topPriorityLevel);
trialNum = 0;
DrawFormattedText(win, txtInstr, 'center', 'center', textColor);
Screen('Flip', win);

KbWait;
vbl = Screen('Flip', win);
expStart = vbl;
if use_eyetracker
    publisher.send('t'); % Request time from eye tracker
    expStart_pl = publisher.recv(); % Get time value
    expStart_pl = str2num(char(expStart_pl')); % Convert to readable
end

%% 5 minute baseline
% if eyetracking
%     publisher.send('t'); % Request time from eye tracker
%     pl1 = publisher.recv(); % Get time value
%     pl1 = str2num(char(pl1')); % Convert to readable
% end
% DrawFormattedText(win, fixSymbol, 'center', 'center', fixColor);
% baselineStart = Screen('Flip', win); % Get timestamp
% baselineEnd = Screen('Flip', win, vbl + (baselineFrames - 0.5) * ifi);
% if eyetracking
%     publisher.send('t'); % Request time from eye tracker
%     pl2 = publisher.recv(); % Get time value
%     pl2 = str2num(char(pl2')); % Convert to readable
% end
% baselineTimes(1, 1) = baselineStart - expStart; % Save actual fixation time
% baselineTimes(1, 2) = baselineEnd - baselineStart;
% if eyetracking
%     baselineTimes(1, 3) = pl1;
%     baselineTimes(1, 4) = pl2;
% end

%% Experiment start
for b = 1:nBlocks
    if b ~= 1
        DrawFormattedText(win, txtBlock, 'center', 'center', textColor);
        Screen('Flip', win);
        KbWait;
    end

    for t = 1:img(b).nImages
        trialStart = Screen('Flip', win);
        trialNum = trialNum + 1; % Consecutive trial number

        %DrawFormattedText(win, fixSymbol, 'center', 'center', fixColor);
        drawFix_simple(win, fixShape, fixSize, fixColor);
        vbl = Screen('Flip', win); % Get timestamp
        if getScreen
            im = Screen('GetImage', win);
            imwrite(im, 'vigilance_cross.png');
        end
        if use_eyetracker
            publisher.send('t'); % Request time from eye tracker
            pl1 = publisher.recv(); % Get time value
            pl1 = str2num(char(pl1')); % Convert to readable
        end
        fixEnd = Screen('Flip', win, vbl + (fixFrames - 0.5) * ifi);
        if use_eyetracker
            publisher.send('t'); % Request time from eye tracker
            pl2 = publisher.recv(); % Get time value
            pl2 = str2num(char(pl2')); % Convert to readable
        end
        fixTimes(trialNum, 1) = fixEnd - vbl; % Save actual fixation time
        fixTimes(trialNum, 2) = fixEnd - expStart;
        if use_eyetracker
            fixTimes(trialNum, 3) = pl1;
            fixTimes(trialNum, 4) = pl2;
        end
        %Screen('DrawTexture', win, img(b).Tex(t));
        Screen('DrawTexture', win, img(b).Tex(t), [], texRect);
        %DrawFormattedText(win, fixSymbol, 'center', 'center', fixColor);
        vbl = Screen('Flip', win);
        if use_eyetracker
            publisher.send('t'); % Request time from eye tracker
            pl1 = publisher.recv(); % Get time value
            pl1 = str2num(char(pl1')); % Convert to readable
        end
        sceneEnd = Screen('Flip', win, vbl + (sceneFrames - 0.5) * ifi);
        if use_eyetracker
            publisher.send('t'); % Request time from eye tracker
            pl2 = publisher.recv(); % Get time value
            pl2 = str2num(char(pl2')); % Convert to readable
        end
        sceneTimes(trialNum, 1) = sceneEnd - vbl; % Save actual scene time
        sceneTimes(trialNum, 2) = sceneEnd - expStart;
        if use_eyetracker
            sceneTimes(trialNum, 3) = pl1;
            sceneTimes(trialNum, 4) = pl2;
        end
        elapsed = Screen('Flip', win);
        if use_eyetracker
            publisher.send('t'); % Request time
            elapsed_pl = publisher.recv(); % Get time value
            elapsed_pl = str2num(char(elapsed_pl')); % Convert to readable
        end
        % Quit if ESC
        if KbQueueCheck
            Priority(0)
            KbQueueStop
            sca
            return
        end
    end
end

Priority(0);
ShowCursor;
sca
if debugLogging
    diary OFF
end

if use_eyetracker
    PLTimes = [expStart_pl, elapsed_pl, elapsed_pl - expStart_pl];
else
    PLTimes = nan;
end

% Save MAT
%save(matFilename, 'fixTimes', 'sceneTimes', 'PLTimes', 'baselineTimes');
save(matFilename, 'fixTimes', 'sceneTimes', 'PLTimes'); %, 'baselineTimes');
% Save to Excel
xlsFilename = strcat(matFilename, '.xlsx');
% Scene Times
writecell({'MLImgTime', 'MLImgFromStart', 'PLImgTime', 'PLImgFromStart'}, xlsFilename, ...
    'Range', 'A1:D1');
writematrix(sceneTimes, xlsFilename, 'Range', ['A2:D', num2str(nTotalImages+1)]);
% Fix Times
writecell({'MLFixTime', 'MLFixFromStart','PLFixTime','PLFixFromStart'}, xlsFilename, ...
    'Range', 'E1:H1');
writematrix(fixTimes, xlsFilename, 'Range', ['E2:H', num2str(nTotalImages+1)]);

% Pupil Times
writecell({'PLExpStartStamp', 'PLElapsedStamp', 'PLDuration'}, xlsFilename, ...
    'Range', 'I1:K1');
if use_eyetracker
    writematrix(PLTimes, xlsFilename, 'Range', 'I2:K2');
else
    writecell({'NaN', 'NaN', 'NaN'}, xlsFilename, 'Range', 'I2:K2');
end

% % Baseline times
% writecell({'MLBaselineTime', 'MLBaselineFromStart', 'PLBaselineTime', 'PLBaselineFromStart'}, ...
%     xlsFilename, 'Range', 'L1:O1');
% if eyetracking
%     writematrix(baselineTimes, xlsFilename, 'Range', 'L2:O2');
% else
%     writematrix(baselineTimes(1:2), xlsFilename, 'Range', 'L2:M2');
%     writecell({'NaN', 'NaN'}, xlsFilename, 'Range', 'N2:O2');
% end

% Write out conditions in order on second sheet
imgList = [img(1).names; img(2).names; img(3).names];
writecell(imgList, xlsFilename, 'Sheet', 2)

%end