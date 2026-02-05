% RECORDsafetysou
%publisher.send('R');
%str2num(char(publisher.recv()'))

%CALIBRATE
%publisher.send('C');
%str2num(char(publisher.recv()'))

% Initial clearing/remove any old runs
close all;
clear
sca

% Set up some defaults: graphics, harmonize PC/Mac keyboards, clamp color 0:1 range
PsychDefaultSetup(2);
% If it crashes with sync error, ideally resopen tart MATLAB. If still problems,
% change this to 1, but not ideal
Screen('Preference', 'SkipSyncTests', 1);
%Screen('Preference', 'VisualDebugLevel', 6);
% vram_settings_on = sum(...
%     [1, 1, 1, 0, 0,  0,  0,  1,   1] .* ...
%     [1, 2, 4, 8, 16, 32, 64, 128, 256] ...
%     );
%Screen('Preference', 'ConserveVRAM', vram_settings_on); % kPsychUseBeampositionQueryWorkaround

%% STUFF YOU CAN CHANGE AS NEEDED

% expDefaults = dictionary('eyetracking', 1, 'trialDebug', 0, 'doRand', 1, ...
%     'useKeys', 1, 'getScreen', 0, ...
%     'dotTime', 10, 'endtime', 10);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       VARIABLES TO CHANGE                       %
%
% Use the eye tracker
% SHOULD BE 1, COMMENTED OUT BECAUSE IT GETS DEFINED LOWER NOW
% AND OPENS PUPIL CAPTURE AS NEEDED.
%use_eyetracker = 1;

% Display trial number in upper left for debugging
% SHOULD BE 0
trialDebug = 0;

% Randomize order of trial timings, 3 orders
% SHOULD BE 1
doRand = 1;

% Skip button presses, OFF for testing only
% SHOULD BE 1
useKeys = 1;

% Set screen Number
% 0 = across all screens
% 1 = mirrored screens
% 2 = right screen
% SHOULD BE 1 IN CURRENT DESIGN
screenNum = 1;
%screenNum = 0;

% Take screenshot
% SHOULD BE 0
getScreen = 0;

% Run windowed.
% SHOULD BE []
% screenSize = [0 0 3840 2160] .* 0.75;
screenSize = [];

% Fixed timings, ms
dotTime = 10; % DEFAULT 10
endTime = 10; % DEFAULT 10
vol = 0.25; % DEFAULT 0.25

% Testing for eye tracker crash/freeze
% Maybe keep on 1 for now?
crashtest = 1;

 % Log Command Window for error messages etc.
debugLogging = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

if crashtest == 1
    % Alt: just error
    if ~contains(softwareRunning, et_executable)
        warning('Pupil Capture does not appear to be running. Continuing will completely freeze the system.');
        warning('Hit Ctrl+C now to quit, start Pupil Capture, calibrate and start recording.');
        null = input('');
        sca
        return
    else
        use_eyetracker = 1;
    end

else
    if contains(softwareRunning, et_executable)
        et_check = input(['\nPupil Capture appears to be running. Make sure you have run CALIBRATION and are RECORDING.\n\n', ...
            'Type Y if you want to continue\nQ (or anything else) to quit and run calibration.\n\n'], 's');
        if ~any(strcmpi(et_check, ["y", "yes"]))
            use_eyetracker = 0;
            return
        else
            use_eyetracker = 1;
        end
    else
        et_check = input(['\nPupil Capture does not appear to be running. This program will freeze dramatically if not running.\n\n', ...
            'Type Y if you want to attempt to RUN it (you will still need to calibrate and record).\n', ...
            'Type N if you want to continue to run in DEBUG mode.\n', ...
            'Type Q (or anything else) to quit.\n\n'], 's');
        if any(strcmpi(et_check, ["y", "yes"]))
            if exist(et_path + et_executable, 'file')
                % Run program, & == focus on MATLAB
                [status, cmdout] = system(et_path + et_executable + " &");
                use_eyetracker = 1;
            else
                error(['Pupil-Labs eye tracking software may not be installed or is not in C:\ Install or change path variables:', ...
                    '"et_path", "et_executable" if running experiment.']);
            end
        elseif any(strcmpi(et_check, ["n", "no"]))
            use_eyetracker = 0;
        else
            return
        end

    end
end

% if contains(softwareRunning, et_executable)
%     use_eyetracker = 1;
% else
%     use_eyetracker = 0;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    CHANGE NEXT LINE TO FORCE "FAKE" EYETRACKER  %
%          MAKE SURE YOU WANT TO DO THIS          %
%manual_eyetracker = 0
%          1 makes it run without freezing        %
%              but doesn't record timestamps      %
%          0 makes it detect eyetracker           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Trial info
if ~use_eyetracker
    fprintf('\n');
    warning('*********************************************************');
    warning('MATLAB has detected that the eyetracking software is not running.');
    warning('Or you have chosen to test the experiment without it.')
    warning('Eye tracker timestamps will not be saved and data will not be useable.')
    warning('Ctrl+C now to quit and run the software first, or see instructions');
    warning('in Psychtoolbox Window');
    warning('*********************************************************');
    fprintf('\n');

    % warning('This MATLAB program is not being run in experiment mode.');
    % warning('Eye tracking timing information will not be recorded even');
    % warning('if the eye tracker is running and recording.');
    % warning('Change eyetracking variable to 1 if running an actual');
    % warning('experiment. This will be on or near line 27 above.');

else
    fprintf('\n');
    warning('***************************************************************************');
    warning('MATLAB has detected that the eyetracking software, %s is running.', et_executable);
    warning('This does not mean that it is recording or calibrated.');
    warning('Ctrl+C now to quit if you need to do so.');
    warning('***************************************************************************');
    fprintf('\n');

    % warning('Eye tracker mode is ON. Device must be CONNECTED and Pupil Capture RUNNING.');
    % warning('Hit Ctrl+C now if you don''t want to run a session or MATLAB will freeze.');
    % fprintf('\n');
    % warning('If it does freeze, you will need to Alt+Tab and attempt to close both the');
    % warning('MATLAB and Psychtoolbox windows, possibly multiple times. You can also try');
    % warning('to Ctrl+Alt+Del or Ctrl+Shift+Esc to close them in Task Manager. This will');
    % warning('potentially take multiple tries and minutes until MATLAB decides it has');
    % warning('crashed and you can force quit it. Reopen MATLAB and make sure that Pupil');
    % warning('Capture is running and recording.');
end

% File paths, change as needed, or rename your folders to match.
% These are relative paths, so individual folders should be in same
% directory as this file.
%
% These are adaptive: e.g. removing sounds will decrease the number of
% trials, adding sounds will increase.

addpath('threat_audio');
addpath('safety_audio');
addpath('trial_runs');

% Trials built upon contents of these folders
stimThreatAudio = fullfile(pwd, 'threat_audio');
stimSafetyAudio = fullfile(pwd, 'safety_audio');

load('new_run.mat');
%load('run_short.mat')
nBlocks = size(who('runTrials*'),1); %3;
nRuns = size(runTrials1, 1);

% Assign BLOCKS in random order
if doRand
    blockOrder = randperm(nBlocks);
else
    blockOrder = [1 2 3];
end

blocks = cell(1, nBlocks);
for i = 1:nBlocks
    blocks{i} = eval(strcat('runTrials', num2str(blockOrder(i))));
end

% % Assign THREATS in random order
% if doRand
%     threatOrder = randperm(3);
% else
%     threatOrder = [1 2 3];
% end
% runConds = cellstr(repmat({"baseline", "threat_alone", "threat_together"}, nRuns, 1));
% for ii = 1:nBlocks
%     blocks{ii}(:,4) = runConds(1, threatOrder(ii));
% end

% Colors, change as preferred
bkgd = [0.5 0.5 0.5];
dotColor = [0 0 0];
crossColor = [0 0 0];
fixColor = dotColor;

% On EMM300 PC, + O X are about 3cm
dotShape = '.'; % Always on, setting it to this ignores the rest
crossShape = '+';
fixShape = dotShape;

% Display stuff
dotSize = 10; % Always on, setting it to this ignores the rest
crossSize = 10;
fixSize = dotSize;

% Keyboard
KbName('UnifyKeyNames');
quitKey = KbName('Escape');
triggerKey = KbName('space');

%% Experiment Setup - runs before trials
expName = 'Arousal_new'; %Anything, affects filename

%Todo: FOR CONVENIENCE, REMOVE THIS LATER
commandwindow;
fprintf(newline);

subjID = input('Enter Subject Number/ID: ', 's');

% Prompt threat order
correctOrder = 0;
% Only allow one of 6 combos
while ~correctOrder
    threatOrder = input(['Enter trial condition order in format like: 123, 312. Where:\n',...
        '   1) Water alone\n   2) Threat alone\n   3) Threat together\n', ...
        'e.g. 213 == [threat_alone, water_alone, threat_together] in order.\n\n'],'s');
    correctOrder = any(strcmp({'123', '132', '213', '231', '312', '321'}, threatOrder));
end
% Convert to 1x3 double
threatOrder = [str2double(threatOrder(1)), str2double(threatOrder(2)), str2double(threatOrder(3))];

% Fill blocks with text in order chosen
runConds = cellstr(repmat({"baseline", "threat_alone", "threat_together"}, nRuns, 1));
for ii = 1:nBlocks
    blocks{ii}(:,4) = runConds(1, threatOrder(ii));
end

datecode = datestr(now,'yyyy-mm-dd_HHMM');
matFilename = strcat(datecode, '_', subjID, '_', expName, '_conds-', ...
    [num2str(threatOrder(1)), num2str(threatOrder(2)), num2str(threatOrder(3))], '_rand-', ...
    [num2str(blockOrder(1)), num2str(blockOrder(2)), num2str(blockOrder(3))]);
matFilename = fullfile(pwd, 'Results', matFilename);

% Actual times

% trialTimes = zeros(nTrials, 4);
% waitTimes = zeros(nTrials, 4);
% threatTimes = zeros(nTrials, 4);
dotTimes = zeros(nBlocks, 4);
waitTimes = zeros(nBlocks * nRuns, 4);
endTimes = zeros(nBlocks, 4);
t = [];
trialStart = [];
expStart = [];

%--------------------------------------------
%             Initiate PTB
%--------------------------------------------
% Check for PTB3

% Uncomment if experiment doesn't run.
% Consider video issues/potential upgrades if uncommenting is necessary.
% Linux OS seems to work best here.
% Screen('Preference','SkipSyncTests',1);
% Screen('Preference','SuppressAllWarnings',1);

% Find & set up display screen
screens = Screen('Screens');
% if debug == 1
%screenNum = max(screens);

% else
%    screenNum = 0; %Always use one monitor with actual experiments
% end

% Keyboard stuff, allow only ESC and SPACE
keys = zeros(1,256);
keys(quitKey) = 1;
%keys(triggerKey) = 1;
KbQueueCreate([], keys) % For now, only Quit key
KbQueueStart;

% Debug screen calcs, change as needed
[absScreenX, absScreenY] = Screen('WindowSize', screenNum);
debugScreenRatio = 0.6; %Quarter of your screen

if debugLogging
        diary log_Arousal.txt
end

if isempty(screenSize)
    [win, rect] = PsychImaging('OpenWindow', screenNum, bkgd);
else
    [win, rect] = PsychImaging('OpenWindow', screenNum, bkgd, screenSize);
end
%Screen('FillRect', win, bkgd)
HideCursor;

% Allow antialiasing, transparency, etc.
Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Timing information
fps = Screen('FrameRate', win);
ifi = Screen('GetFlipInterval', win);
% These never change, so define ahead of time
dotFrames = round(dotTime / ifi);
endFrames = round(endTime / ifi);

% Specific font choice mainly for equal-width characters for fixation
Screen('TextFont', win, 'Courier New');
Screen('TextSize', win, 80);

%% Audio setup and build matrix

% Start up PTB for psychudio input
InitializePsychSound;

% Open the  audio device, with default mode [] (==Only playback)
pahandle = PsychPortAudio('Open', [], [], [], [], 2); % Freq is different now, don't specify

% Create array with audio files
audioFormat = '*.wav'; %Change if mp4 etc
threatAudioFilesStruct = dir(fullfile(stimThreatAudio, audioFormat));
safetyAudioFilesStruct  = dir(fullfile(stimSafetyAudio, audioFormat));

% Get # sounds
nThreatSounds = length(threatAudioFilesStruct);
nSafetySounds = length(safetyAudioFilesStruct);

% Load sounds in order
%threatRows = find(strcmp(runTrials.RealThreats, 'RealThreatSound')) % Find rows containing sounds
%threatRows = [2 3]' % UNCOMMENT IF YOU WANT FIXED AUDIO TRIALS

PsychPortAudio('Volume', pahandle, vol);

%audioFilenames = {threatAudioFilesStruct(1).name, threatAudioFilesStruct(2).name, ...
%    safetyAudioFilesStruct(1).name, safetyAudioFilesStruct(2).name};
threatFilenames = {threatAudioFilesStruct(1).name, threatAudioFilesStruct(2).name, threatAudioFilesStruct(3).name};
safetyFilenames = {safetyAudioFilesStruct(1).name, safetyAudioFilesStruct(2).name, safetyAudioFilesStruct(3).name};
threatSounds = cell(2,3);
safetySounds = cell(2,3);
for sf = 1:nBlocks
    audioData1 = [];
    audioData2 = [];
    freq1=[];
    freq2=[];
    aft = threatFilenames{sf};
    [audioData1, freq1] = audioread(aft); % Load data corresponding to audio power @ freq
    threatSounds{1,sf} = audioData1';
    threatSounds{2,sf} = freq1;

    afs = safetyFilenames{sf};
    [audioData2, freq2] = audioread(afs); % Load data corresponding to audio power @ freq
    safetySounds{1,sf} = audioData2';
    threatSounds{2,sf} = freq2;
end
%threat 190217, 190217,    190212!
%safety 190217, 190217,    192007!

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

%% Intro screen. Add instructions???

% Pause at beginning for keypress, integrate MRI?
topPriorityLevel = MaxPriority(win);

%% Experiment

% Waiting for trigger screen
% fixShape = dotFixShape;
% fixColor = dotFixColor;
% fixSize = dotFixSize;
if use_eyetracker
    exp_instr = ['Eye tracker is detected ON\n\nMake sure you are CALIBRATED and RECORDING.\n' ...
        'If not sure, hit ESCAPE multiple\n' ...
        'times and it will quit now\nor on the next trial.\n'...
        '\nPress SPACEBAR start.'];
else
    exp_instr = ['Eye tracker is OFF and will not\n' ...
        'send time stamps.\n' ...
        'If you want to run experiment,\n' ...
        'Hit ESCAPE multiple times and\n' ...
        'the program will quit.\n' ...
        '\nPress SPACEBAR to start.'];
end

% baseline_instr{1} = ['For the next few minutes, we will be getting a baseline for your heart rate\n', ...
%     'skin response, and eye tracking measures – we want to know what your baseline measures\n', ...
%     'on these are, before you start any of the experiments.'];
% baseline_instr{2} = ['Please put your chin on the chinrest while I read you this set of instructions.'];
% baseline_instr{3} = ['Please place your non-dominant palm face down on the edge of the table\n', ...
%     'and get comfortable. It can help to rest your arms on the arm rests and put both feet flat\n', ...
%     'on the ground. Try to keep your hand with the equipment as still as possible, but don’t feel like\n', ...
%     'you have to be a statue. Now please hold this ball [give them the ball]. Hold it in a way that\n', ...
%     'feels comfortable to you.'];
baseline_instr = 'Condition BASELINE. Any key to start';
%water_instr = 'Read water/alone instructions. Any key to start';
threat_alone_instr = 'Condition: Threat/ALONE. Any key to start';
threat_together_instr = 'Condition: Threat/TOGETHER. Any key to start';

DrawFormattedText(win, exp_instr, 'center', rect(4) * 1/4);
drawFix_simple(win, fixShape, fixSize, fixColor);
Screen('Flip', win);

WaitSecs(0.2);
if useKeys; KbWait; end
% if useKeys
%     while 1
%         [~, ~, firstRelease, ~, ~] = KbQueueCheck; % Get keypress
%         if KbName(firstRelease) == triggerKey
%             break
%         elseif KbName(firstRelease) == quitKey
%             % Quit if ESC pressed on previous trial
%             Priority(0);
%             KbQueueStop
%             sca
%             return
%             break
%         end
%     end
% end
WaitSecs(0.2);

% Start experiment
%try
fprintf('\n\n\n'); %Add white space
fprintf('**********EXPERIMENT START**********')
fprintf('\n\n\n'); %Add white space
Priority(topPriorityLevel);
drawFix_simple(win, fixShape, fixSize, fixColor);
vbl = Screen('Flip', win);

expStart = vbl;
if use_eyetracker
    publisher.send('t'); % Request time from eye tracker
    expStart_pl = publisher.recv(); % Get time value
    expStart_pl = str2num(char(expStart_pl')); % Convert to readable
end

iterator = 1;

for bb = 1:nBlocks
    DrawFormattedText(win, eval(cell2mat(strcat(blocks{bb}.ThreatType(1), '_instr'))), ...
        'center', rect(4) * 1/4);
    Screen('Flip', win);
    
    if useKeys; KbWait; end
    
    % if useKeys
    %     responded = 0;
    %     while ~responded
    %         [~, firstPress, ~, ~, ~] = KbQueueCheck; % Get keypress
    %         if strcmpi(KbName(firstPress), triggerKey)
    %             % Skip out if pressed
    %             responded = 1;
    %         elseif strcmpi(KbName(firstPress), quitKey)
    %             % Quit if ESC pressed on previous trial
    %             responded = 1;
    %             Priority(0);
    %             KbQueueStop
    %             sca
    %             return
    %         end
    %     end
    % end


    if KbQueueCheck
        Priority(0);
        KbQueueStop
        sca
        return
    end
    warning('Stopped after.');
    % Request experiment quit. If pressed during a trial, will trigger on
    % the start of the next trial.
    
    trialStart = Screen('Flip', win);
    if use_eyetracker
        publisher.send('t'); % Request time from eye tracker
        trialStart_pl = publisher.recv(); % Get time value
        trialStart_pl = str2num(char(trialStart_pl')); % Convert to readable
    end

    fprintf('*************** Block = %d ***************\n', bb);
    %fprintf('Stimulus = %s\n\n', num2str(i));

    % 1: DOT PROMPT
    fixColor = dotColor;
    fixShape = dotShape;
    fixSize = dotSize;

    % Draw black dot
    if trialDebug; DrawFormattedText(win, sprintf('Block = %d', bb), 10, 100, [1 1 1]); end
    drawFix_simple(win, fixShape, fixSize, fixColor);
    t = Screen('Flip', win); % Run whenever, this creates time lock
    
    if getScreen
        im = Screen('GetImage', win);
        imwrite(im, 'dot.png');
    end
    if use_eyetracker
        publisher.send('t'); % Request time from eye tracker
        pl1 = publisher.recv(); % Get time value
        pl1 = str2num(char(pl1')); % Convert to readable
    end

    % Wait for fixFrames time
    fprintf('Dot requested = %2.4f / ', dotTime);
    if trialDebug; DrawFormattedText(win, sprintf('Trial = %d', i), 10, 100, [1 1 1]); end
    drawFix_simple(win, fixShape, fixSize, fixColor);
    vbl = Screen('Flip', win, t + (dotFrames - 0.5) * ifi); % Flip after time

    if use_eyetracker
        publisher.send('t'); % Request time from eye tracker
        pl2 = publisher.recv(); % Get time value
        pl2 = str2num(char(pl2')); % Convert to readable
    end
    fprintf('Actual = %2.4f\n', vbl - t);
    dotTimes(bb, 1) = vbl - t;
    dotTimes(bb, 2) = vbl - expStart;
    if use_eyetracker
        dotTimes(bb, 3) = pl1;
        dotTimes(bb, 4) = pl2;
    end

    % Start trial block
    for i = 1:nRuns
        % Quit if ESC pressed on previous trial
        %[~, firstPress, ~, ~, ~] = KbQueueCheck; % Get keypress
        if KbQueueCheck
            %if strcmpi(KbName(firstPress), quitKey)
                Priority(0)
                KbQueueStop
                sca
            %end
            %return
        end
        iterator = ((bb - 1) * nRuns) + i; % Tracks all trials

        % 2: WAIT CUE
        % if strcmp(runTrials{i,1}, 'Threat')
        %     fixColor = threatFixColor;
        %     fixShape = threatFixShape;
        %     fixSize = threatFixSize;
        % elseif strcmp(runTrials{i,1}, 'Safety')
        %     fixColor = safetyFixColor;
        %     fixShape = safetyFixShape;
        %     fixSize = safetyFixSize;
        % end
        fixColor = crossColor;
        fixShape = crossShape;
        fixSize = crossSize;

        % Draw threat X or O
        if trialDebug; DrawFormattedText(win, sprintf('Trial = %d', i), 10, 100, [1 1 1]); end
        drawFix_simple(win, fixShape, fixSize, fixColor);
        t = Screen('Flip', win);
        if getScreen
            im = Screen('GetImage', win);
            imwrite(im, 'cross.png');
        end
        if use_eyetracker
            publisher.send('t'); % Request time from eye tracker
            pl1 = publisher.recv(); % Get time value
            pl1 = str2num(char(pl1')); % Convert to readable
        end
        waitTime = cell2mat(blocks{bb}.Wait(i));
        waitFrames = round(waitTime / ifi);
        fprintf('*** Block %d Trial %d ***\n', bb, i);

        if trialDebug; DrawFormattedText(win, sprintf('Trial = %d', i), 10, 100, [1 1 1]); end
        fprintf('Wait requested = %2.4f / ', waitTime);
        drawFix_simple(win, fixShape, fixSize, fixColor);
        vbl = Screen('Flip', win, t + (waitFrames - 0.5) * ifi);
        if use_eyetracker
            publisher.send('t'); % Request time from eye tracker
            pl2 = publisher.recv(); % Get time value
            pl2 = str2num(char(pl2')); % Convert to readable
        end
        fprintf('Actual = %2.4f\n', vbl - t);
        waitTimes(iterator, 1) = vbl - t;
        waitTimes(iterator, 2) = vbl - expStart;
        if use_eyetracker
            waitTimes(iterator, 3) = pl1;
            waitTimes(iterator, 4) = pl2;
        end


        % 4: PLAY AUDIO
        fixShape = crossShape;
        fixColor = crossColor;
        fixSize = crossSize;

        % Start playing audio
        if trialDebug; DrawFormattedText(win, sprintf('Trial = %d', i), 10, 100, [1 1 1]); end
        drawFix_simple(win, fixShape, fixSize, fixColor);
        t = Screen('Flip', win);

        %currCondition = char(runTrials.RealThreats(i));
        currCondition = table2array(blocks{bb}(1, 4)); % All the same so only need first
        currSound = table2array(blocks{bb}(i, 3));
        switch currCondition{1}
            case 'baseline'
                PsychPortAudio('FillBuffer', pahandle, safetySounds{1, currSound});
            case 'threat_alone'
                PsychPortAudio('FillBuffer', pahandle, threatSounds{1, currSound});
            case 'threat_together'
                PsychPortAudio('FillBuffer', pahandle, threatSounds{1, currSound});
                % case 'FEMALE SCREAM'
                %     PsychPortAudio('FillBuffer', pahandle, allSounds{1,1});
                % case 'MALE SCREAM'
                %     PsychPortAudio('FillBuffer', pahandle, allSounds{2,1});
                % case 'WATER 1'
                %     PsychPortAudio('FillBuffer', pahandle, allSounds{1,2});
                % case 'WATER 2'
                %     PsychPortAudio('FillBuffer', pahandle, allSounds{2,2});
        end
        audioStart = PsychPortAudio('Start', pahandle, 1, 0, 1);

        [~, audioLength, ~, t2] = PsychPortAudio('Stop', pahandle, 1);
        if trialDebug; DrawFormattedText(win, sprintf('Trial = %d', i), 10, 100, [1 1 1]); end
        drawFix_simple(win, fixShape, fixSize, fixColor);
        % Flip just for new time stamp, waits until audio is finished
        vbl = Screen('Flip', win); %, win, vbl + (currAntFrames + 0.5) * ifi);
        %Psychtoolbox code
        fprintf('Audio actual = %2.4f\n', audioLength);

    end % Trial block
    % 6: END REST
    fixShape = dotShape;
    fixColor = dotColor;
    fixSize = dotSize;
    %currRestFrames = round(runTrials{i,3} / ifi);

    % Draw dot, rest
    if trialDebug; DrawFormattedText(win, sprintf('Trial = %d', i), 10, 100, [1 1 1]); end
    drawFix_simple(win, fixShape, fixSize, fixColor); %NOTE fix size changed
    t = Screen('Flip', win); % Does the actual fix removal
    if use_eyetracker
        publisher.send('t'); % Request time from eye tracker
        pl1 = publisher.recv(); % Get time value
        pl1 = str2num(char(pl1')); % Convert to readable
    end
    %t = GetSecs;
    fprintf('End requested = %2.4f / ', endTime);
    if trialDebug; DrawFormattedText(win, sprintf('Trial = %d', i), 10, 100, [1 1 1]); end
    drawFix_simple(win, fixShape, fixSize, fixColor);
    vbl = Screen('Flip', win, t + (endFrames + 0.5) * ifi); % No previous draw = just blank screen
    if use_eyetracker
        publisher.send('t'); % Request time from eye tracker
        pl2 = publisher.recv(); % Get time value
        pl2 = str2num(char(pl2')); % Convert to readable
    end
    fprintf('Actual = %2.4f\n', vbl - t);

    endTimes(bb, 1) = vbl - t;
    endTimes(bb, 2) = vbl - expStart;
    if use_eyetracker
        endTimes(bb, 3) = pl1;
        endTimes(bb, 4) = pl2;
    end
    if trialDebug; DrawFormattedText(win, sprintf('Trial = %d', i), 10, 100, [1 1 1]); end
    drawFix_simple(win, fixShape, fixSize, fixColor);
    elapsed = Screen('Flip', win);

    if use_eyetracker
        publisher.send('t'); % Request time
        elapsed_pl = publisher.recv(); % Get time value
        elapsed_pl = str2num(char(elapsed_pl')); % Convert to readable
    end
    fprintf('Total trial length = %2.4f\n\n', elapsed - trialStart);

    blockTimes(bb, 1) = elapsed - trialStart;
    blockTimes(bb, 2) = elapsed - expStart;
    if use_eyetracker
        blockTimes(bb, 3) = trialStart_pl;
        blockTimes(bb, 4) = elapsed_pl;
    end

end % Block end

% catch ME
%     disp(ME)
%     PsychPortAudio('Close', pahandle);
%     sca
%     Priority(0);
%     ShowCursor;
%end

KbQueueStop;
expEnd = GetSecs - expStart;
fprintf('\n\n\n   Experiment elapsed time: %2.4f minutes (%2.4f seconds)\n\n\n', expEnd/60, expEnd);
PsychPortAudio('Close', pahandle);

save('emergency.mat'); % Just in case, will overwrite next time so rename it if needed!

% Save important data, add to struct as needed
dataToSave.Subject = subjID;
%dataToSave.Run = runID;
%dataToSave.Handholding = condName;
dataToSave.Blocks = blocks;
%dataToSave.TrialTimes = blockTimes;
dataToSave.DotTimes = dotTimes;
dataToSave.WaitTimes = waitTimes;
%dataToSave.ThreatTimes = crossTimes;
%dataToSave.AnticipationTimes = antTimes;
%dataToSave.RestTimes = endTimes;
% Save eye tracker experiment time if applicable
% Note: eye tracker saves its own time stamps e.g load folder in Pupil
% Capture, Export, then export_info.csv should have similar format
if use_eyetracker
    dataToSave.PLTimes = [expStart_pl, elapsed_pl, elapsed_pl - expStart_pl];
else
    dataToSave.PLTimes = nan;
end

% Save MAT
save(matFilename, 'dataToSave');
% Save Excel
xlsFilename = strcat(matFilename, '.xlsx');
% Dot times

nTrials = nBlocks * nRuns;
% for bbb = 1:nBlocks
%     condList = [blocks{1}.ThreatType; blocks{2}.ThreatType; blocks{3}.ThreatType]
% end

writecell({'MLDotTime', 'MLDotFromStart', 'PLDotTime', 'PLDotFromStart'}, xlsFilename, ...
    'Range', 'A1:D1', 'Sheet', 'Trials');
writematrix(dotTimes, xlsFilename, 'Range', ['A2:D', num2str(nBlocks+1)], 'Sheet', 'Trials');
% Condition and sound
writecell({'Condition', 'Sound'}, xlsFilename, 'Range', 'E1:F1', 'Sheet', 'Trials')
writecell([blocks{1}.ThreatType; blocks{2}.ThreatType; blocks{3}.ThreatType], xlsFilename, 'Range', ['E2:E', num2str(nTrials+1)], 'Sheet', 'Trials');
writematrix([blocks{1}.Sound; blocks{2}.Sound; blocks{3}.Sound], xlsFilename, 'Range', ['F2:F', num2str(nTrials+1)], 'Sheet', 'Trials');
% Wait times
writecell({'MLWaitTime', 'MLWaitFromStart', 'PLWaitTime', 'PLWaitFromStart'}, xlsFilename, ...
    'Range', 'G1:J1', 'Sheet', 'Trials');
writematrix(waitTimes, xlsFilename, 'Range', ['G2:J', num2str(nTrials+1)], 'Sheet', 'Trials');
% Rest times
writecell({'MLRestTime', 'MLRestFromStart', 'PLRestTime', 'PLRestFromStart'}, xlsFilename, ...
    'Range', 'K1:N1', 'Sheet', 'Trials');
writematrix(endTimes, xlsFilename, 'Range', ['K2:N', num2str(nBlocks+1)], 'Sheet', 'Trials');

% Trial times, separate sheet
%writecell(blocks, xlsFilename, 'Sheet', 'FullTrial');
writecell({'MLTrialTime', 'MLTrialFromStart', 'PLTrialTime', 'PLTrialFromStart'}, xlsFilename, ...
    'Range', 'E1:H1', 'Sheet', 'FullTrial');
writematrix(blockTimes, xlsFilename, 'Range', ['E2:H', num2str(nBlocks+1)], 'Sheet', 'FullTrial');

if use_eyetracker
    writecell({'StartTime','EndTime'}, xlsFilename, 'Range','A1:B1', 'Sheet', 'Summary');
    writematrix(dataToSave.PLTimes, xlsFilename, 'Range','A2:B2', 'Sheet', 'Summary');
end
ShowCursor;
sca
if debugLogging
    diary OFF
end