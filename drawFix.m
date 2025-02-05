function drawFix(win, fixSymbol, fixSize, fixColor)
%--------------------------------------------
%          Add fixation cross
%--------------------------------------------
Screen('TextSize',win,50);

%Changes appearance/antialiasing etc. Change if issues or slow
%AA requires BlendFunction
dotsType = 1;
mult = 5;
fs = fixSize * mult;
% Draw fixation
%Screen('DrawDots', win, [0 0], fixSize, fixColor,[], dotsType);

%Draw the fixation cross
sz = Screen('Rect', win);
[x, y] = RectCenter(sz);
centerColor = [0 0 0];

switch fixSymbol
    case '+'
        linCoor = [x-fs, x+fs, x, x;
            y, y, y-fs, y+fs];
        Screen('DrawLines', win, linCoor, 5, fixColor);
    case 'X'
        linCoor = [x-fs, x+fs, x-fs x+fs;
            y-fs y+fs y+fs y-fs];
        Screen('DrawLines', win, linCoor, 10, fixColor);
    case 'O'
        Screen('FrameOval', win, fixColor, [x-fs y-fs x+fs y+fs], 10)
    case 'p'
        centerColor = fixColor;
    case ' '
        return
end

% Draw center dot always
Screen('FillOval', win, centerColor, [x-fixSize y-fixSize x+fixSize y+fixSize]);

% fixCoords = [-fixSize, fixSize, 0, 0; ...
%     0, 0, -fixSize, fixSize]; %x; y
% Screen('DrawLines', win, fixCoords, [], fixColor)

% Screen('Flip', win);
% WaitSecs(0.5);
end