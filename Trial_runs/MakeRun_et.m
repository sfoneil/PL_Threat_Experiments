clear

% Prompts
sID = input('Enter initials/Subject ID: ','s');
nRuns = input('Enter number of run files to create (1 - X): ','s');
mkdir(sID)
% Change as needed
antTimes = [4 6 8 10];
nRepsPerHalf = 3;

antTimeVect = repmat(antTimes, 1, nRepsPerHalf)';
nTrials = length(antTimeVect) * 2;

% Create half run unsorted vectors
threatCue = [repmat({'Threat'}, nTrials/4, 1); ...
    repmat({'Safety'}, nTrials/4, 1)];
restTimeVect = 14 - antTimeVect;
realThreats = cell(nTrials/2,1);
realThreats(:) = {'SafetySound'}; % Prefill, 2/4 will be overridden
   
%% Loop for each file
for fileNum = 1:str2double(nRuns)

   % Pull two different ant times out, one for each half, without replacement
    antPool = datasample(antTimes, 2, 'Replace', false);
    runTrials = table(); % Fresh table for that run
    % Do each half separately
    for halves = 1:2
        % Randomize anticipation times
        ants = antTimeVect(randperm(length(antTimeVect)));
        % Get indices of each chosen random ant
        antMatchIndices = ants == antPool(halves);
        % Get two random rows to mark
        rowsToMark = datasample(find(antMatchIndices), 2, 'Replace', false)';
        
        % Mark those rows, cue and actual
        threatCue(rowsToMark(1)) = {'Threat'};
        realThreats(rowsToMark(1)) = {'RealThreatSound'};
        threatCue(rowsToMark(2)) = {'Safety'};
        realThreats(rowsToMark(2)) = {'Remove'};
        
        % Mark the rest
        idxRestOfRows = setdiff(1:nTrials/2, rowsToMark);
        realThreats(idxRestOfRows) = {'SafetySound'}; % Mark all the rest safety
        idxFakeThreatVals = datasample(idxRestOfRows, size(idxRestOfRows,2)/2, 'Replace', false);
        idxSafetyVals = setdiff(idxRestOfRows, idxFakeThreatVals);
        threatCue(idxFakeThreatVals) = {'Threat'}; % Mark half the rest threat
        threatCue(idxSafetyVals) = {'Safety'}; % Mark other half safety

        % Create table
        randHalf = table(threatCue, ants, 14-ants, realThreats);
        randHalf.Properties.VariableNames = {'CueType', 'AntTimes', 'RestTimes', 'RealThreats'};
        
        % Now randomize again, keeping columns in same row
        randHalf = randHalf(randperm(height(randHalf)), :);
        
        % Add half to toal
        runTrials = [runTrials; randHalf];
    end
    
    % Save
    fName = strcat(fullfile(pwd, sID, 'run'), string(fileNum), '.mat');

    save(fName, 'runTrials', '-mat');
end

% Just a check, shouldn't happen
% if sum(strcmp(randTrials{1:12,1}, 'Safety')) == 0 || ...
%       sum(strcmp(randTrials{1:12,1}, 'Safety')) == 12
%     warning('Check trial order on run #%d', fileNum)
% end



% % Get two different anticipation times to isolate
% randAntTime = datasample(antTimes, 2, 'Replace', false); % 2 unique values, sample without replacement


%end
% Randomize cues, 12 then 12

%cueType = cueType(randperm(size(cueType,1)));

% Get timings, 4,6,8,10 repeating

% antTimeVect = [Shuffle(halfTimes), Shuffle(halfTimes)]';
% restTimeVect = 14 - antTimeVect;

% Put into first table
%    Trials = table(cueType, antTimeVect, restTimeVect);

% Add in actual adversive
% Prefill
%     realThreats = cell(nTrials,1);
%     realThreats(:) = {'SafetySound'}; % Prefill all trials

%% Now start marking trials
% Mark trials that are threat cue 1 == threat
%     firstHalf = strcmp(Trials{1:nTrials/2, 1},'Threat');
%     secondHalf = strcmp(Trials{nTrials/2+1:end, 1},'Threat');
%
%     % Get two different anticipation times to isolate
%     randAntTime = datasample(antTimes, 2, 'Replace', false); % 2 unique values, sample without replacement
%
%     % Find trials with the random anticipation times
%     firstHalfMatch = Trials{1:nTrials/2, 2} == randAntTime(1);
%     secondHalfMatch = Trials{nTrials/2+1:end, 2} == randAntTime(2);
%
%     % Find two trials that match
%     realThreats{firstHalf(randi(length(firstHalf)))} = 'RealThreatSound';
%     realThreats{secondHalf(randi(length(secondHalf)))} = 'RealThreatSound';
%
%     % Add to table
%     randHalf = addvars(randHalf, realThreats);


%end


