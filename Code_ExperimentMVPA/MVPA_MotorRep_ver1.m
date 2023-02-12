%% Notes
% 2023/02/11 MVPA for Motor representations in motor adaptation

%% Initialize
clear; clc;
currentPath = pwd;

%% Whether MRI or not
isMRI = false;

%% open window 

% Check if Psychtoolbox is properly installed:
AssertOpenGL;

% to avoid sinc problem
Screen('Preference', 'SkipSyncTests', 1);

% Open up a window on the screen and clear it.
whichScreen = max(Screen('Screens',0));
Screen('Resolution', whichScreen, 800,600); % for resoultion
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseVirtualFramebuffer');
[theWindow,theRect] = PsychImaging('OpenWindow', whichScreen, 0);

% cursor option
HideCursor;

% center coordinate
MidX = theRect(RectRight)/2;
MidY = theRect(RectBottom)/2;


%% Screen mirror
if ~isMRI
    % Translate origin into the geometric center of text:
    Screen('glTranslate', theWindow, MidX, MidY, 0);

    % Apple a scaling transform which flips the diretion of x-Axis,
    % thereby mirroring the drawn text horizontally:
    Screen('glScale', theWindow, 1, -1, 1);

    % We need to undo the translations...
    Screen('glTranslate', theWindow, -MidX, -MidY, 0);
end
%% set variables

numRepSession = 5;

sessionTypes = {'Rot90', 'Rot270', 'Mirror'};
sessionIdx = 1:length(sessionTypes);

sessionIdxList =  repmat(sessionIdx, [1, numRepSession]);
sessionIdxList = sessionIdxList(randperm(length(sessionIdxList)));
% sessionTypeList = repmat(sessionTypes, [1, numRepSession]);
% sessionTypeList = sessionTypeList(randperm(length(sessionTypeList)));

isTestSession = [1,0,1];

numSessions = length(sessionIdxList);                    % 총 세션 횟수

numScanRuns = [1,2,1];                    % fMRI scan run 횟수 / 각 세션

numTotalRun = sum(numScanRuns,'all');

% numObjRepPerRun = 5;                % 한 run 내에서 object/grasp 반복되는 횟수

trialT = 4;                         % Erasing 수행 시간
nullT = trialT;                     % null trial 시간

readyT = 2;                       % 각 trial 전, 준비 시간 (어떤 grasp 수행 제시)
readyAfterT = 0;                    % 준비 후, grasp 전 fixation 시간

iti = 6;                            % inter-trial interval 
jitterITI = 0;                      % jitter for ITI

restRunT = 20;                      % fMRI run 사이 쉬는 시간(s)
restSessionT = 5 * 60;              % 세션 사이 쉬는 시간(s)

instructionT = 8;                   % instruction 한 장당 보여주는 시간

runInitialAddT = 10;
sessionEndAddT = 10;

interSessionT = 10; 

dotSize = 12;                   % 포인터 사이즈
width = 16;                     % 기본 네모 사이즈

lineLength = 7;                  % 지워야 하는 라인 길이

% image list for the instructions
instFolder = 'Image/Instructions';
cd(currentPath); cd(instFolder); instFolder = pwd;
cd(currentPath);

% for saving results
resultsFolder = 'Results';

% Button
buttonChar = '1!'; 

cd(currentPath);

%% instruction preperation

cd(instFolder);

dirInst = dir;
instList = {dirInst(3:end).name};

for ii = 1:length(instList)
    img=imread(instList{ii});
    tempsize=size(img);
    texture = Screen('MakeTexture', theWindow, img); %#ok<NASGU>
    eval("texture"+instList{ii}(1:end-4)+"=texture;");
    imrect=[0 0 tempsize(2) tempsize(1)];
    [rect] = CenterRect(imrect, theRect); %#ok<NASGU>
    eval("rect"+instList{ii}(1:end-4)+"=rect;");
end

clear rect imrect texture img imgList;

%% rotation preparation
cd(currentPath);
load('randpoint.mat');
rotTestDegrees = [90,180,270]; % (degree)
randPoints1 = 30*[point2(:,1), -point2(:,2)] +[MidX-200, MidY+50];
randPoints = randPoints1;


rotRadian = -pi*90/180;
matRot90pos = [cos(rotRadian),sin(rotRadian);-sin(rotRadian),cos(rotRadian)];
rotRadian = -pi*(-90)/180;
matRot90neg = [cos(rotRadian),sin(rotRadian);-sin(rotRadian),cos(rotRadian)];
matMirror = [-1, 0; 0, 1];

rotMatList = {matRot90pos, matRot90neg, matMirror};
%% Stimuli preparation
rotLineDegrees = [0, 90, 180, 270]; % (degree)
pointsDirection = cell(1,4);
% erasing righward
pointsTemp = zeros(lineLength, 2);
for npoint = 1:lineLength
    pointsTemp(npoint,:) = [MidX + (npoint * width), MidY];
end
pointsDirection{1} = pointsTemp;

% erasing upward
pointsTemp = zeros(lineLength, 2);
for npoint = 1:lineLength
    pointsTemp(npoint,:) = [MidX, MidY - (npoint * width)];
end
pointsDirection{2} = pointsTemp;

% erasing leftward
pointsTemp = zeros(lineLength, 2);
for npoint = 1:lineLength
    pointsTemp(npoint,:) = [MidX - (npoint * width), MidY];
end
pointsDirection{3} = pointsTemp;

% erasing downward
pointsTemp = zeros(lineLength, 2);
for npoint = 1:lineLength
    pointsTemp(npoint,:) = [MidX, MidY + (npoint * width)];
end
pointsDirection{4} = pointsTemp;

%% Set the task order
Screen('DrawTexture', theWindow, textureInitialize, [], rectInitialize);
Screen('TextSize', theWindow, 20);
Screen('DrawText', theWindow, '00%',MidX,MidY+50, [255,255,255]);
Screen('Flip',theWindow);

disp(' ');
disp('>>> Setting the stimulus order: type 1 index 1 continuous-carryover sequence');
tic;
cd(currentPath);
load('OptTest_length3_1.mat');
minCritOrder3 = minCrit2Order;
load('OptTest_length4_1.mat');
minCritOrder4 = minCrit2Order;
load('OptTest_length5_3.mat');
minCritOrder5 = minCritOrder;

taskOrder = cell(1,length(sessionIdxList));

nAccumRun = 0;
isNull = 0;
for nses = 1:numSessions
    nAccumRun = nAccumRun + 1;
    disp(['Permutating ... Session #' num2str(nses)]);
    lineDegrees = rotLineDegrees; 
    nullIndex = length(rotLineDegrees)+1;

    eval(['minCritOrder = minCritOrder' num2str(length(lineDegrees)+isNull) ';']);

    tempLabel = randperm((length(lineDegrees)+isNull))';
    while tempLabel(1) == nullIndex
        tempLabel = randperm((length(lineDegrees)+isNull))';
    end
    taskOrder{nses} = tempLabel(minCritOrder);
end
disp('Done! - Setting the stimulus order');
toc
% pause(1);

%% Experiment Ready
Screen('DrawTexture', theWindow, textureBeforeStart, [], rectBeforeStart);
Screen('Flip',theWindow);

% wait for MRI start signal
syncSignal = 's';
nextKey = 'space';

% Scan start
[~, ~, k, ~] = KbCheck;
while k(KbName(syncSignal)) == 0
    [~, k, ~] = KbWait;
end
startTimeScanning = clock;
pause(2);

if ~exist(resultsFolder, 'dir'); mkdir(resultsFolder); end
cd(resultsFolder);
resultFileName = sprintf('MVPA_MotorRep_%d%02d%02d%s%02d%02d', round(startTimeScanning(1)), round(startTimeScanning(2)), round(startTimeScanning(3)), '_', round(startTimeScanning(4)), round(startTimeScanning(5)));
eval(['save ',resultFileName, ' startTimeScanning taskOrder lineDegrees']);
cd(currentPath);

for nses = 1:numSessions
    timeStartRun{nses} = zeros([1,6]);                                                  %#ok<SAGROW> % save start time of each session: dim1 - nses
    timeEndRun{nses} = zeros([1,6]);                                                    %#ok<SAGROW> % save end time of each session: dim1 - nses
    timeReadyPresent{nses} = zeros([size(taskOrder{nses},1),6]);                        %#ok<SAGROW> % save ready stimulus present time: dim1 - nses, dim2 - ntrial
    timeTrialStart{nses} = zeros([size(taskOrder{nses},1),6]);                          %#ok<SAGROW> % save trial start time: dim1 - nses, dim2 - ntrial
    durationTrial{nses} = zeros([size(taskOrder{nses},1),1]);                           %#ok<SAGROW> % save erasing duration: dim1 - nses, dim2 - ntrial
    checkstateTrial{nses} = zeros([size(taskOrder{nses},1),1]);                         %#ok<SAGROW> % save how many points the sub erased: dim1 - nses, dim2 - ntrial
end
thePointsAll = cell(numSessions, length(taskOrder{1}));
theTimesAll = cell(numSessions, length(taskOrder{1}));
theChecksAll = cell(numSessions, length(taskOrder{1}));
%% Experiment
disp(' ');
disp('>>> Task Start!');
numAccumRun = 0;
for nses = 1:numSessions
    Screen('DrawTexture', theWindow, textureFixation, [], rectFixation);
    Screen('Flip', theWindow); tic;
    pause(runInitialAddT);
    
    eval("textureSessionInst = " + "textureSessionInst_" + num2str(sessionTypes{sessionIdxList(nses)}) + ";");
    eval("rectSessionInst = " + "rectSessionInst_" + num2str(sessionTypes{sessionIdxList(nses)}) + ";");
    Screen('DrawTexture', theWindow, textureSessionInst, [], rectSessionInst);
    Screen('Flip',theWindow);
    pause(instructionT);
    
    numAccumRun = numAccumRun + 1;
    
    Screen('DrawTexture', theWindow, textureFixation, [], rectFixation);
    Screen('Flip', theWindow); tic;
    disp(['>> Session #' num2str(nses)]);
    timeStartRun{nses}= clock; tic;

    numRealErasingTrial = 0;
    numRealErasingTrial_Total = sum(taskOrder{nses}<=length(lineDegrees),'all');
    for ntrial = 1:length(taskOrder{nses})
        idxRot = taskOrder{nses}(ntrial);

        lineDegrees = rotLineDegrees;

        jitter = jitterITI*rand-(jitterITI/2);
%         if idxRot <= length(lineDegrees)
%             eval("textureReady = " + "textureDegree_" + num2str(lineDegrees(idxRot)) + ";");
%             eval("rectReady = " + "rectDegree_" + num2str(lineDegrees(idxRot)) + ";");
%             Screen('DrawTexture', theWindow, textureReady, [], rectReady);
%         else
%             Screen('DrawTexture', theWindow, textureDegree_Null, [], rectDegree_Null);
%         end

        pause(iti+jitter-toc);

%         Screen('Flip',theWindow); % display ready
        tic;
        timeReadyPresent{nses}(ntrial,:) = clock;
        Screen(theWindow,'FillRect',[0 0 0],theRect);
        if idxRot <= length(lineDegrees)
            numRealErasingTrial = numRealErasingTrial + 1;
            
            % Checkpoint variable
            checkstate=1;
            erasePoints = pointsDirection{idxRot};
%             practiceArrow = '→';
%             arrowPosition = [MidX-30, MidY-100];
            spoint(1) = MidX;
            spoint(2) = MidY;

            for ii=checkstate:size(erasePoints,1)
                Screen(theWindow,'FillRect',255,[erasePoints(ii,1)-width/2,erasePoints(ii,2)-width/2,erasePoints(ii,1)+width/2,erasePoints(ii,2)+width/2]);
            end
%                 Screen(theWindow,'DrawText',practiceArrow,arrowPosition(1),arrowPosition(2),255);

            % Set mouse to start point
            SetMouse(spoint(1),spoint(2),whichScreen);
            theX= spoint(1);
            theY= spoint(2);

            Screen('DrawDots', theWindow, [theX theY], dotSize, [255 0 0],[0,0],1);
            
            % Trial progress
            Screen('TextSize', theWindow, 48);
            process=strcat(num2str(numRealErasingTrial),'/',num2str(numRealErasingTrial_Total));
            Screen(theWindow,'DrawText',process,50,50,255);
            
            % checking action duration time
            tic;
            thePoints=[theX theY];
            theTimes=toc;
            theChecks=checkstate;
        else
            checkstate = 0;
            Screen('DrawTexture', theWindow, textureFixation, [], rectFixation);
        end
%         pause(readyT-toc);

        % Draw screen
        Screen('Flip', theWindow);
        tic;
        timeTrialStart{nses}(ntrial,:) = clock;
        % rotate x coordinate

        if idxRot <= length(lineDegrees)
            matRot = rotMatList{sessionIdxList(nses)};

            % Loop and track the mouse, drawing the contour
            while checkstate <= size(erasePoints,1) && toc <= trialT
                for ii=checkstate:size(erasePoints,1)
                    Screen(theWindow,'FillRect',255,[erasePoints(ii,1)-width/2,erasePoints(ii,2)-width/2,erasePoints(ii,1)+width/2,erasePoints(ii,2)+width/2]);
                end

                % get mouse
                [x,y,buttons] = GetMouse(theWindow);

                newCoord = matRot*[x-spoint(1);y-spoint(2)] + spoint';

                % mouse trace
                if (newCoord(1) ~= theX || newCoord(2) ~= theY)
                    % Trial progress
                    Screen('TextSize', theWindow, 48);
                    process=strcat(num2str(numRealErasingTrial),'/',num2str(numRealErasingTrial_Total));
                    Screen(theWindow,'DrawText',process,50,50,255);
                    
                    theX = newCoord(1); theY = newCoord(2);
                    Screen('DrawDots', theWindow, newCoord', dotSize, [255 0 0],[0,0],1);
                    Screen('Flip',theWindow);
                    thePoints = [thePoints ; newCoord(1) newCoord(2)]; %#ok<AGROW>
                    theTimes = [theTimes ; toc]; %#ok<AGROW>
                    theChecks= [theChecks ; checkstate]; %#ok<AGROW>
                end
                % drawing null
%                     Screen(theWindow,'FillRect',[0 0 0],theRect);

%                     Screen(theWindow,'DrawText',practiceArrow,arrowPosition(1),arrowPosition(2),255);
                if newCoord(1) >= erasePoints(checkstate,1)-width/2 && newCoord(1) <= erasePoints(checkstate,1)+width/2 && newCoord(2) <= erasePoints(checkstate,2)+width/2 && newCoord(2) >= erasePoints(checkstate,2)-width/2
                    checkstate = checkstate + 1;
                end
            end
        else
            pause(nullT-toc);
        end

        % save performance
        durationTrial{nses}(ntrial) = toc;
        checkstateTrial{nses}(ntrial) = checkstate - 1;
        
        thePointsAll{nses,ntrial} = thePoints;
        theTimesAll{nses,ntrial} = theTimes; 
        theChecksAll{nses,ntrial} = theChecks; 
        
        % Fixation
        Screen(theWindow,'FillRect',[0 0 0],theRect);
        Screen('DrawTexture', theWindow, textureFixation, [], rectFixation);
        Screen('Flip', theWindow); 
        
        if trialT > toc
            pause(trialT-toc);
        end
        
        tic;

        clear spoint;

    end
    
    jitter = jitterITI*rand-(jitterITI/2);
    pause(iti+jitter-toc);

    pause(sessionEndAddT);
    
    aveDuration = mean(durationTrial{nses});
    aveRatio = mean(checkstateTrial{nses})/lineLength;
    
    % score screen
    Screen(theWindow,'FillRect',[0 0 0],theRect);
    Screen(theWindow,'TextSize',48);
    Screen('DrawTexture', theWindow, textureScoreScreen, [], rectScoreScreen);
    
    Screen(theWindow,'DrawText',strcat(num2str(aveDuration,'%.02f'),' s'),MidX+120,MidY-20,255);
    Screen(theWindow,'DrawText',strcat(num2str(floor(aveRatio*100)),' %'),MidX+120,MidY+60,255);
    Screen('Flip',theWindow);
    pause(4);
    
    if nses < numSessions
        Screen('DrawTexture', theWindow, textureAfterRun, [], rectAfterRun);
        Screen('TextSize', theWindow, 35);
        if nses < 10; numoratorText = [' ' num2str(nses) ' ']; else; numoratorText = num2str(nses); end
        if numSessions < 10; denominatorText = [' ' num2str(numSessions)]; else; denominatorText = num2str(numSessions); end
        Screen(theWindow,'DrawText',[numoratorText '/' denominatorText], MidX-160,MidY-89,[255,255,255]);
    else
        Screen('DrawTexture', theWindow, textureEndExperiment, [], rectEndExperiment);
    end
    Screen('Flip', theWindow); 
    timeEndRun{nses} = clock;
    tic;
    tempTime = timeEndRun{nses} - timeStartRun{nses};
    tempTime = 3600*tempTime(4) + 60 * tempTime(5) + tempTime(6);
    disp(['... it took ' num2str(tempTime, '%.5f') 's for Session #' num2str(nses)]);

    cd(resultsFolder);
    resultFileName = sprintf('MVPA_MotorRep_%d%02d%02d%s%02d%02d', round(startTimeScanning(1)), round(startTimeScanning(2)), round(startTimeScanning(3)), '_', round(startTimeScanning(4)), round(startTimeScanning(5)));
    eval(['save ',resultFileName, ' startTimeScanning timeStartRun timeEndRun timeReadyPresent timeTrialStart durationTrial checkstateTrial taskOrder sessionIdx* sessionTypes thePointsAll theTimesAll theChecksAll rotLineDegrees pointsDirection']);
    cd(currentPath);
    
    pause(instructionT-toc);
end
%% close
% pause(instructionT-toc);

% close window
Screen(theWindow,'Close');
Screen('CloseAll');