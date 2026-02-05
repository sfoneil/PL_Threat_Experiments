sca
clear

Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);

% Setup, change as needed
debug = 0; % Only for quick baseline
use_eyetracker = 1; % Should be 1 on eye tracker machine, 0 on partner machine. See below for checks that turn this off
getScreen = 0;
background = [0.5 0.5 0.5]; % Gray
debugSmallScreen = []; %[0 0 3840 2160] .* 0.75; % Use small screen for debug. Should be []
debugLogging = 0; % Log Command Window for error messages etc.

if debug
    baselineTime = 1; % 1 minute
else
    baselineTime = 5; % 5 minutes
end
baselineTime = baselineTime * 60; % Convert to seconds

txtInstr = 'Press any key to start.';
%fixColor = [1 1 1];
%fixSymbol = '+';
screenNum = max(Screen('Screens'));
screenNum = 1; % 1 = paired screen, max/2 = side screen

% Fixation cross, new version
fixShape = '+';
fixSize = 10;
fixColor = [0 0 0];

try
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

    % Get subject info
    datecode = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm');
    datecode = string(datecode);
    sid = input('Enter subject ID:   ', 's');

    if debugLogging
        diary log_VigilanceBaseline.txt
    end
    if isempty(debugSmallScreen)        
        win = PsychImaging('OpenWindow', screenNum, background);
    else
        win = PsychImaging('OpenWindow', screenNum, background, debugSmallScreen);
    end
    HideCursor
    % Monitor timing
    ifi = Screen('GetFlipInterval', win);
    baselineFrames = round(baselineTime / ifi);
    Screen('TextSize', win, 80);
    Screen('TextFont', win, 'Courier');

    % Show start
    DrawFormattedText(win, txtInstr, 'center', 'center', [0 0 0]);
    Screen('Flip', win);
    KbWait;

    %DrawFormattedText(win, fixSymbol, 'center', 'center', fixColor);
    drawFix_simple(win, fixShape, fixSize, fixColor);
    baselineStart = Screen('Flip', win); % Get timestamp
    if use_eyetracker
        publisher.send('t'); % Request time from eye tracker
        plStart = publisher.recv(); % Get time value
        plStart = str2num(char(plStart')); % Convert to readable
    end
    %fprintf('baselineStart = %.4f\n', baselineStart);
    %fprintf('plStart = %.4f\n', plStart);

    if getScreen
        im = Screen('GetImage', win);
        imwrite(im, 'vigilance_baseline_cross.png');
    end
    baselineEnd = Screen('Flip', win, baselineStart + (baselineFrames - 0.5) * ifi);
    %fprintf('baselineEnd = %.4f\n', baselineEnd);
    if use_eyetracker
        publisher.send('t'); % Request time from eye tracker
        plEnd = publisher.recv(); % Get time value
        plEnd = str2num(char(plEnd')); % Convert to readable
    end
    fprintf('Elapsed = %.4f\n', baselineEnd - baselineStart);
    ShowCursor;
    sca

    % Save data
    if ~use_eyetracker
        % Not used
        plStart = nan;
        plEnd = nan;
    end

    save(fullfile(pwd, 'Results', sid + "_" + datecode + "_VigilanceBaseline.mat"), ...
        'baselineTime', 'baselineStart', 'baselineEnd', 'plStart', 'plEnd');
    xlsFilename = fullfile(pwd, 'Results', sid + "_" + datecode + "_VigilanceBaseline.xlsx");
    writecell({'RequestedBl', 'MLBlStart','MLBLEnd','PLBlStart', 'PLBlEnd'}, ...
        xlsFilename, ...
        'Range', 'A1:E1');
    writematrix([baselineTime, baselineStart, baselineEnd, plStart, plEnd], xlsFilename, ...
        'Range', 'A2:E2');
    if debugLogging
        diary OFF
    end
catch err
    sca
    save('crashed_vigilancebaseline.mat');
    rethrow(err);
    if debugLogging
        diary OFF
    end
end