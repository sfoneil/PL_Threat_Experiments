% WAITFRAMES version - for accurate timing

%% Impact of social support on neural reactivity to threat

%EXPERIMENTAL FLOW
%1) Start prompt    green .             1s
%2) Cue             1/2 colored X/O     1s
%3) Anticipation    .                   4-10s
%4) Threat/Safety   A/V .               Sound length dependent?
%5) Rest            .                   10-4s
%Repeat 24x
% = 16 s or 20 for sound trials

% Parameters:2
% Multi-slice echoplanar imaging
% Slice planes scanned along rectal gyrus
% 64 axial slices
% Phase encoding from posterior to anterior
% TR = 2000 ms
% TE = 30 ms
% Multiband factor = 2
% Flip angle = 90
% FOV = 224 x 224 mm
% Slice thickness = 2 mm
% Gap = 0.2 mm
% Voxel size = 2 x 2 x 2.2 mm
% Total length = 346 s

% Initial clearing/remove any old runs
close all;
clear
sca

% Set up some defaults: graphics, harmonize PC/Mac keyboards, clamp color 0:1 range
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);

%% STUFF YOU CAN CHANGE AS NEEDED

eyetracking = 1;
%doSAM = 0; % Run it twice at the end.
%manTrigger = 1;

if ~eyetracking
    warning('Not run in experiment mode.');
end

% Fixed timings, ms
fixCueTime = 1; % Colored prompt for next trial
threatCueTime = 1; % Initial threat cue
endCueTime = 1;
vol = 1.0; % Pre-define with test program

% Types of conditions, adding or removing will change available timings.
% Can also double times, e.g. [4 4 6 8] would use:
% 4 = 50% of the time, 6 = 25%, 8 = 25%
nThreats = 2;
%antTimeVect = [4 6 8 10]';
% antTimeVect = [4 4 4 4 4 4 ...
%     6 6 6 6 6 6 ...
%     8 8 8 8 8 8 ...
%     10 10 10 10 10 10]'; % Placeholder for changed frequencies
% restTimeVect = flipud(antTimeVect); % Reverse order == all trials 14s base

% Trial info

% File paths, change as needed, or rename your folders to match.
% These are relative paths, so individual folders should be in same
% directory as this file.
%
% These are adaptive: e.g. removing sounds will decrease the number of
% trials, adding sounds will increase.

addpath('threataudio');
addpath('safetyaudio');
addpath('Trial_runs');

% Trials built upon contents of these folders
stimThreatAudio = fullfile(pwd, 'threataudio');
stimSafetyAudio = fullfile(pwd, 'safetyaudio');

% Colors, change as preferred
bkgd = [128 128 128] + 1;

% All approx 12.8 candelas
promptFixColor = [0 86 0]; %
threatFixColor = [146 0 0] + 1; %RGB 255, 0, 0
safetyFixColor = [0 0 255] + 1; %RGB 0, 0, 255
neutralFixColor = [0 0 0];
restFixColor = [75 75 75];
fixColor = promptFixColor;

neutralFixShape = '.'; % Always on, setting it to this ignores the rest
promptFixShape = 'p'; % Not actually p, but color
endFixShape = 'o'; % Obsolete?
threatFixShape = 'X';
safetyFixShape = 'O';
restFixShape = '+';
fixShape = neutralFixShape;

% Display stuff
fixSize = 10;

% Keyboard
KbName('UnifyKeyNames');
quitKey = KbName('Escape');
triggerKey = KbName('space');

%% Experiment Setup - runs before trials
expName = 'ThreatArousal2'; %Anything, affects filename

%Todo: FOR CONVENIENCE, REMOVE THIS LATER
fprintf(newline);
% d = input('Enter y if you don''t want to use MRI mode or hit enter\n', 's');
% if strcmp(d,''); d = 'n'; end
% if strcmpi(d,'y')
%debug = 1;

% else
%     debug = 0;
% end


%subjInitials = input('Enter Subject Initials: ','s'); %Can remove for anonymizing
subjID = input('Enter Subject Number/ID: ', 's');
% if ~exist(fullfile(pwd, 'Trial_runs', subjID), 'dir')
%     error('Subject file not created yet. Use MakeRun first with the same ID.')
% end
nRuns = size(dir(fullfile(pwd, 'Trial_runs', 'template')), 1)-2;

prompt = sprintf('Enter Run Number (1 - %d): ', nRuns);
runID = input(prompt, 's');

if isempty(runID)
    % Just run a random order
    runID = 'rand';
    antTimeVect = [4 4 4 4 4 4 ...
        6 6 6 6 6 6 ...
        8 8 8 8 8 8 ...
        10 10 10 10 10 10]'; % Placeholder for changed frequencies
    restTimeVect = flipud(antTimeVect); % Reverse order == all trials 14s base
    cueType = [repmat({'Threat'}, nTrials/2, 1); ...
        repmat({'Safety'}, nTrials/2, 1)];
    runTrials = orderedTrials(randperm(size(orderedTrials,1)),:);
else
    % Read runs from a file
    fName = strcat('run', runID, '.mat');
    fPath = fullfile(pwd, 'Trial_runs', 'template');
    load(fullfile(fPath, fName));
    fprintf('Now loading %s...\n', fName);

end
nTrials = size(runTrials,1);

%stimID = input('Choose your condition:\n1: Visual\n2: Auditory\n');
condID = input('Handholding?\n1: Partner\n2: Stranger\n3: Ball\n');
if condID == 1
    condName = 'Partner';
elseif condID == 2
    condName = 'Stranger';
elseif condID == 3
    condName = 'Ball';
else
    error('Condition must be integer 1-3.')
end
datecode = datestr(now,'yyyy-mm-dd_HHMM');
matFilename = strcat(datecode, '_', subjID, '_', runID, '_', condName, '_', expName);
matFilename = fullfile(pwd, 'Results', matFilename);

% Actual times
timePerTrial = 16;
trialOffsets = [];
trialTimes = zeros(nTrials, 4);
fixTimes = zeros(nTrials, 4);
threatTimes = zeros(nTrials, 4);
antTimes = zeros(nTrials, 4);
restTimes = zeros(nTrials, 4);
t = [];

% What they should be
%fixTimes(:,3) = (0:16:16 * (nTrials-1))+1;
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
screenNum = max(screens);

% else
%    screenNum = 0; %Always use one monitor with actual experiments
% end

%if manTrigger
% Keyboard stuff
keys = zeros(1,256);
keys(KbName('Escape')) = 1;
KbQueueCreate([], keys) % For now, only Quit key
KbQueueStart;
%end
% Debug screen calcs, change as needed
[absScreenX, absScreenY] = Screen('WindowSize', screenNum);
debugScreenRatio = 0.6; %Quarter of your screen

% if debug == 1
%     %     [win, rect] = Screen('OpenWindow', screenNum, bkgd, [100 100 ...
%     %         absScreenX * debugScreenRatio, absScreenY * debugScreenRatio]);
%     [win, rect] = Screen('OpenWindow', screenNum, bkgd);
%     ShowCursor;
%
% else
[win, rect] = Screen('OpenWindow', screenNum, bkgd);
HideCursor;
% end

% Allow antialiasing, transparency, etc.
Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Timing information
fps = Screen('FrameRate', win);
ifi = Screen('GetFlipInterval', win);
% These never change, so define ahead of time
fixFrames = round(fixCueTime / ifi);
threatFrames = round(threatCueTime / ifi);
endFrames = round(endCueTime / ifi);

% Specific font choice mainly for equal-width characters for fixation
Screen('TextFont', win, 'Courier New');
Screen('TextSize', win, 80);

%% Audio setup and build matrix

% Start up PTB for PsychPortAudio input
InitializePsychSound;

% Open the  audio device, with default mode [] (==Only playback)
pahandle = PsychPortAudio('Open', [], [], 0, 48000, 2);   % freq (sample rate) should be 48000

% Create array with audio files
audioFormat = '*.wav'; %Change if mp4 etc
threatAudioFilesStruct = dir(fullfile(stimThreatAudio, audioFormat));
safetyAudioFilesStruct  = dir(fullfile(stimSafetyAudio, audioFormat));

% Get # sounds
nThreatSounds = length(threatAudioFilesStruct);
nSafetySounds = length(safetyAudioFilesStruct);

% Load sounds in order
threatRows = find(strcmp(runTrials.RealThreats, 'RealThreatSound')) % Find rows containing sounds
%threatRows = [2 3]' % UNCOMMENT IF YOU WANT FIXED AUDIO TRIALS

PsychPortAudio('Volume', pahandle, vol);

audioFilenames = {threatAudioFilesStruct(1).name, threatAudioFilesStruct(2).name, ...
    safetyAudioFilesStruct(1).name, safetyAudioFilesStruct(2).name};
allSounds = cell(1,4);
for sf = 1:4
    afn = audioFilenames{sf};
    [audioData, freq] = audioread(afn); % Load data corresponding to audio power @ freq
    allSounds{sf} = audioData';
end
allSounds = reshape(allSounds,2,2); % r1c1 and r2c1 are threat!
%afn = threatAudioFilesStruct(1).name;
%[audioData, freq] = audioread(afn); % Load data corresponding to audio power @ freq
%audioData = audioData';

% Should be the same for all
nChannels = size(audioData,1);
nTotalFrames = size(audioData, 2);

% PTB Audio. Can be below
% tSound = cell(1,2);
% sSound = cell(1,2);
% tSound{1} = [audioData(:,:)]; % Double line for stereo
% tSound{2}

%PsychPortAudio('FillBuffer', pahandle, tSound);
%nTrials = 3
%% Eye tracking setup
if eyetracking
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
fixShape = neutralFixShape;
fixColor = neutralFixColor;

% Pause and wait for MRI trigger/keypress
%if manTrigger
if eyetracking
    instr = 'Eye tracker is ON\nMake sure you are RECORDING\nWaiting for any key trigger.';
else
    instr = 'Eye tracker is OFF and will not send time stamps\nWaiting for any key trigger.';
end

%else
%    instr = 'Waiting for MRI trigger';
%end
DrawFormattedText(win, instr, 'center', rect(4) * 1/3);
drawFix(win, fixShape, fixSize, fixColor);
Screen('Flip', win);
KbWait;

% if debug
%     disp('Debug mode - no MRI');
%     KbWait;
% elseif manTrigger
%     disp('Manual trigger - MRI');
%     KbWait;
% else
%     disp('Waiting for MRI trigger');
%     %Datapixx_startingTrigger;
% end

% if ~debug
%     if (nChannels == 1)
%         lrMode = 0;
%     else
%         lrMode = 3;
%     end
% end

% Start experiment
try
    fprintf('\n\n\n'); %Add white space
    fprintf('**********EXPERIMENT START**********')
    fprintf('\n\n\n'); %Add white space
    Priority(topPriorityLevel);
    vbl = Screen('Flip', win);
    expStart = vbl;
    if eyetracking
        publisher.send('t'); % Request time from eye tracker
        expStart_pl = publisher.recv(); % Get time value
        expStart_pl = str2num(char(expStart_pl')); % Convert to readable
    end
    for i = 1:nTrials
        % Request experiment quit. If pressed during a trial, will trigger on
        % the start of the next trial.
        trialStart = Screen('Flip', win);
        if eyetracking
            publisher.send('t'); % Request time from eye tracker
            trialStart_pl = publisher.recv(); % Get time value
            trialStart_pl = str2num(char(trialStart_pl')); % Convert to readable
        end
        if KbQueueCheck
            Priority(0)
            KbQueueStop
            sca
            return
        end

        fprintf('*************** Trial = %d ***************\n', i)
        fprintf('Cue = %s\n', char(runTrials{i,1}));
        fprintf('Stimulus = %s\n\n', char(runTrials{i,4}));

        % 1: TRIAL PROMPT
        fixColor = promptFixColor;
        fixShape = promptFixShape;

        % Draw green dot
        drawFix(win, fixShape, fixSize, fixColor);
        t = Screen('Flip', win); % Run whenever, this creates time lock
        if eyetracking
            publisher.send('t'); % Request time from eye tracker
            pl1 = publisher.recv(); % Get time value
            pl1 = str2num(char(pl1')); % Convert to readable
        end
        % Wait for fixFrames time
        fprintf('Fix requested = %2.4f / ', fixCueTime);
        drawFix(win, fixShape, fixSize, fixColor);

        vbl = Screen('Flip', win, vbl + (fixFrames - 0.5) * ifi); % Flip after time
        if eyetracking
            publisher.send('t'); % Request time from eye tracker
            pl2 = publisher.recv(); % Get time value
            pl2 = str2num(char(pl2')); % Convert to readable
        end
        fprintf('Actual = %2.4f\n', vbl - t);
        fixTimes(i, 1) = vbl - t;
        fixTimes(i, 2) = vbl - expStart;
        if eyetracking
            fixTimes(i, 3) = pl1;
            fixTimes(i, 4) = pl2;
        end
        % 2: THREAT/NO THREAT CUE
        if strcmp(runTrials{i,1}, 'Threat')
            fixColor = threatFixColor;
            fixShape = threatFixShape;
        elseif strcmp(runTrials{i,1}, 'Safety')
            fixColor = safetyFixColor;
            fixShape = safetyFixShape;
        end

        % Draw threat X or O
        drawFix(win, fixShape, fixSize, fixColor);
        t = Screen('Flip', win);
        if eyetracking
            publisher.send('t'); % Request time from eye tracker
            pl1 = publisher.recv(); % Get time value
            pl1 = str2num(char(pl1')); % Convert to readable
        end
        %drawFix(win, fixShape, fixSize, fixColor);
        fprintf('Threat/safety cue requested = %2.4f / ', threatCueTime);
        vbl = Screen('Flip', win, vbl + (threatFrames - 0.5) * ifi);
        if eyetracking
            publisher.send('t'); % Request time from eye tracker
            pl2 = publisher.recv(); % Get time value
            pl2 = str2num(char(pl2')); % Convert to readable
        end
        fprintf('Actual = %2.4f\n', vbl - t);
        threatTimes(i, 1) = vbl - t;
        threatTimes(i, 2) = vbl - expStart;
        if eyetracking
            threatTimes(i, 3) = pl1;
            threatTimes(i, 4) = pl2;
        end

        % 3: ANTICIPATION CUE
        fixShape = neutralFixShape;
        fixColor = neutralFixColor;
        currAntFrames = round(runTrials{i,2} / ifi);

        % Draw dot, anticipation
        drawFix(win, fixShape, fixSize, fixColor);
        t = Screen('Flip', win);
        if eyetracking
            publisher.send('t'); % Request time from eye tracker
            pl1 = publisher.recv(); % Get time value
            pl1 = str2num(char(pl1')); % Convert to readable
        end
        %         im1 = Screen('GetImage', win);
        %         imwrite(im1, 'black.png','PNG');
        fprintf('Anticipation requested = %2.4f / ', runTrials{i,2});
        drawFix(win, fixShape, fixSize, fixColor); % Fixation will flicker if it is removed
        vbl = Screen('Flip', win, vbl + (currAntFrames + 0.5) * ifi);
        if eyetracking
            publisher.send('t'); % Request time from eye tracker
            pl2 = publisher.recv(); % Get time value
            pl2 = str2num(char(pl2')); % Convert to readable
        end
        fprintf('Actual = %2.4f\n', vbl - t);
        antTimes(i, 1) = vbl - t;
        antTimes(i, 2) = vbl - expStart;
        if eyetracking
            antTimes(i, 3) = pl1;
            antTimes(i, 4) = pl2;
        end
        % 4: PLAY THREAT CONDITION, ON TWO TRIALS
        fixShape = neutralFixShape;
        fixColor = neutralFixColor;

        % Start playing audio
        drawFix(win, fixShape, fixSize, fixColor);
        t = Screen('Flip', win);

        currCondition = char(runTrials.RealThreats(i));
        switch currCondition
            case 'FEMALE SCREAM'
                PsychPortAudio('FillBuffer', pahandle, allSounds{1,1});
            case 'MALE SCREAM'
                PsychPortAudio('FillBuffer', pahandle, allSounds{2,1});
            case 'WATER 1'
                PsychPortAudio('FillBuffer', pahandle, allSounds{1,2});
            case 'WATER 2'
                PsychPortAudio('FillBuffer', pahandle, allSounds{2,2});
        end

        %         if any(i == threatRows)
        %             PsychPortAudio('FillBuffer', pahandle, allSounds{1,1});
        %         else
        %             PsychPortAudio('FillBuffer', pahandle, allSounds{1,2});

        %Psychtoolbox code
        audioStart = PsychPortAudio('Start', pahandle, 1, 0, 1);

        %VPIXX: don't use
        %             Datapixx('StartAudioSchedule');
        %             Datapixx('RegWrRd');    % Synchronize Datapixx registers to local register cache
        %

        %             WaitSecs(nTotalFrames./freq); % 4 seconds
        %             while 1
        %                 Datapixx('RegWrRd');   % Update registers for GetAudioStatus
        %                 status = Datapixx('GetAudioStatus');
        %                 if ~status.scheduleRunning
        %                     break;
        %                 end
        %             end

        [~, audioLength, ~, t2] = PsychPortAudio('Stop', pahandle, 1);
        %t2 = GetSecs;
        drawFix(win, fixShape, fixSize, fixColor);
        % Flip just for new time stamp, waits until audio is finished
        vbl = Screen('Flip', win); %, win, vbl + (currAntFrames + 0.5) * ifi);
        %fprintf('Audio actual = %2.4f\n', t2 - t);
        fprintf('Audio actual = %2.4f\n', audioLength);
        %         else
        %             fprintf('No audio.\n')
        %         end

        % 6: REST
        fixShape = restFixShape;
        fixColor = restFixColor;
        currRestFrames = round(runTrials{i,3} / ifi);

        % Draw dot, rest        
        drawFix(win, fixShape, 5, fixColor); %NOTE fix size changed
        t=Screen('Flip', win); % Does the actual fix removal
        if eyetracking
            publisher.send('t'); % Request time from eye tracker
            pl1 = publisher.recv(); % Get time value
            pl1 = str2num(char(pl1')); % Convert to readable
        end
        %t = GetSecs;
        fprintf('Rest requested = %2.4f / ', runTrials{i,3});
        drawFix(win, fixShape, fixSize, fixColor);
        vbl = Screen('Flip', win, vbl + (currRestFrames + 0.5) * ifi); % No previous draw = just blank screen
        if eyetracking
            publisher.send('t'); % Request time from eye tracker
            pl2 = publisher.recv(); % Get time value
            pl2 = str2num(char(pl2')); % Convert to readable
        end
        fprintf('Actual = %2.4f\n', vbl - t);

        restTimes(i, 1) = vbl - t;
        restTimes(i, 2) = vbl - expStart;
        if eyetracking
            restTimes(i, 3) = pl1;
            restTimes(i, 4) = pl2;
        end
        elapsed = Screen('Flip', win);

        if eyetracking
            publisher.send('t'); % Request time
            elapsed_pl = publisher.recv(); % Get time value
            elapsed_pl = str2num(char(elapsed_pl')); % Convert to readable
        end
        fprintf('Total trial length = %2.4f\n\n', elapsed - trialStart);

        trialTimes(i, 1) = elapsed - trialStart;
        trialTimes(i, 2) = elapsed - expStart;
        if eyetracking
            trialTimes(i, 3) = trialStart_pl;
            trialTimes(i, 4) = elapsed_pl;
        end
    end

catch ME
    disp(ME)
    PsychPortAudio('Close', pahandle);
    sca
    Priority(0);
    ShowCursor;
end

KbQueueStop;
expEnd = GetSecs - expStart;
fprintf('\n\n\n   Experiment elapsed time: %2.4f minutes (%2.4f seconds)\n\n\n', expEnd/60, expEnd);
PsychPortAudio('Close', pahandle);



save('emergency.mat'); % Just in case, will overwrite next time so rename it if needed!


% Save important data, add to struct as needed
dataToSave.Subject = subjID;
dataToSave.Run = runID;
dataToSave.Handholding = condName;
dataToSave.Trials = runTrials;
dataToSave.TrialTimes = trialTimes;
dataToSave.FixTimes = fixTimes;
dataToSave.ThreatTimes = threatTimes;
dataToSave.AnticipationTimes = antTimes;
dataToSave.RestTimes = restTimes;
% Save eye tracker experiment time if applicable
% Note: eye tracker saves its own time stamps e.g load folder in Pupil
% Capture, Export, then export_info.csv should have similar format
if eyetracking
    dataToSave.PLTimes = [expStart_pl, elapsed_pl, elapsed_pl - expStart_pl];
else
    dataToSave.PLTimes = nan;
end

% % Run 2 SAM tasks
% if doSAM
%     % if debug
%     iDev = 'kb';
%     % else
%     %     iDev = 'vp';
%     % end
%     try
%         arousalLevel = expSAM('Arousal',[1 0 1], iDev, screenNum);
%         pleasureLevel = expSAM('Pleasure',[0 0 1], iDev, screenNum);
%     catch ME
%         save(matFilename, 'dataToSave');
%         rethrow
%     end
% end
% % Run SAM
% %Datapixx('Close');
% if doSAM
%     dataToSave.ArousalLevel = arousalLevel;
%     dataToSave.PleasureLevel = pleasureLevel;
% end

% Save MAT
save(matFilename, 'dataToSave');
% Save Excel
xlsFilename = strcat(matFilename, '.xlsx');
% Fix times
writecell({'MLFixTime', 'MLFixFromStart', 'PLFixTime', 'PLFixFromStart'}, xlsFilename, ...
    'Range', 'A1:D1', 'Sheet', 'Trials');
writematrix(fixTimes, xlsFilename, 'Range', ['A2:D', num2str(nTrials+1)], 'Sheet', 'Trials');
% Threat times
writecell({'MLThreatTime', 'MLThreatFromStart', 'PLThreatTime', 'PLThreatFromStart'}, xlsFilename, ...
    'Range', 'E1:H1', 'Sheet', 'Trials');
writematrix(threatTimes, xlsFilename, 'Range', ['E2:H', num2str(nTrials+1)], 'Sheet', 'Trials');
% Anticipation times
writecell({'MLAntTime', 'MLAntFromStart', 'PLAntTime', 'PLAntFromStart'}, xlsFilename, ...
    'Range', 'I1:L1', 'Sheet', 'Trials');
writematrix(antTimes, xlsFilename, 'Range', ['I2:L', num2str(nTrials+1)], 'Sheet', 'Trials');
% Rest times
writecell({'MLRestTime', 'MLRestFromStart', 'PLRestTime', 'PLRestFromStart'}, xlsFilename, ...
    'Range', 'M1:P1', 'Sheet', 'Trials');
writematrix(restTimes, xlsFilename, 'Range', ['M2:P', num2str(nTrials+1)], 'Sheet', 'Trials');
% Trial times, separate sheet
writetable(runTrials, xlsFilename, 'Sheet', 'FullTrial');
writecell({'MLTrialTime', 'MLTrialFromStart', 'PLTrialTime', 'PLTrialFromStart'}, xlsFilename, ...
    'Range', 'E1:H1', 'Sheet', 'FullTrial');
writematrix(trialTimes, xlsFilename, 'Range', ['E2:H', num2str(nTrials+1)], 'Sheet', 'FullTrial');
ShowCursor;
sca

% Exactly 2 real threats, 1 of each scream
% Exactly 10 trials where a threat is anticipated but doesn't occur, 5 of each water sounds
% Exactly 12 trials where safety is anticipated and 6 each water sounds

% Average duration of true anticipate == non-anticipate