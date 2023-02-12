% 2020_02s_05 motorlearningtask
%
%
%
%
clear;
clc;

isScreenMirrored = true;

pause(0.1);
Screen('Preference', 'SkipSyncTests', 1 );

% Open up a window on the screen and clear it.
whichScreen = max(Screen('Screens',0));
Screen('Resolution', whichScreen, 800,600);
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseVirtualFramebuffer');
[theWindow,theRect] = PsychImaging('OpenWindow', whichScreen, 0);

% center coordinate
MidX = theRect(RectRight)/2;
MidY = theRect(RectBottom)/2;
 
img=imread('MousePractice2.jpg');
tempsize=size(img);
texture = Screen('MakeTexture', theWindow, img);
texture_MousePrac=texture;
imrect=[0 0 tempsize(2) tempsize(1)];
[smallIm] = CenterRect(imrect, theRect);
smallIm_MousePrac=smallIm; 

% Mirror
if isScreenMirrored
    % Translate origin into the geometric center of text:
    Screen('glTranslate', theWindow, MidX, MidY, 0);

    % Apple a scaling transform which flips the diretion of x-Axis,
    % thereby mirroring the drawn text horizontally:
    Screen('glScale', theWindow, 1, -1, 1);

    % We need to undo the translations...
    Screen('glTranslate', theWindow, -MidX, -MidY, 0);
end

% cursor option
% ShowCursor('Arrow');
HideCursor;

dot_size = 12;

Screen('DrawTexture', theWindow, texture_MousePrac, [], smallIm_MousePrac);

theX = MidX; theY = MidY;
SetMouse(theX,theY,whichScreen);
Screen('DrawDots', theWindow, [theX theY], dot_size, [255 0 0],[0,0],1);

Screen('Flip', theWindow, 0, 1);

[~, ~, k, ~] = KbCheck;
while k(KbName('space')) == 0
    [~, ~, k, ~] = KbCheck;
    [x,y,buttons] = GetMouse(theWindow);
    if (x ~= theX || y ~= theY)
        theX = x; theY = y;
        Screen(theWindow,'FillRect',[0 0 0],theRect);
        Screen('DrawTexture', theWindow, texture_MousePrac, [], smallIm_MousePrac);
        Screen('DrawDots', theWindow, [theX theY], dot_size, [255 0 0],[0,0],1);
        Screen('Flip',theWindow,0,1);
    end
end

Screen(theWindow,'Close');
Screen('CloseAll');
clc;