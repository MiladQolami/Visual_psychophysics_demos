%%%%%%%%%%%%%% Orientation Discrimination under Crowding and interocular suppression %%%%%%%%%%%
% This code was written by Milad Qolami
clc;
clear;
close all;

%% %% Display setup module
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);
screenNumber = max(Screen('Screens'));

PsychImaging( 'PrepareConfiguration'); % First step in starting  pipeline

% normalize the color range ([0, 1] corresponds to [min, max])
PsychImaging( 'AddTask', 'General','NormalizedHighresColorRange' );

PsychImaging( 'AddTask' , 'FinalFormatting','DisplayColorCorrection' , 'SimpleGamma' );
% setup Gamma correction method using simple power  function for all color channels
 
% Display features
screen_distance = 50; % in centimeter
screen_height = 19; % in centimeter
Sscreen_gamma = 2.2; % from monitor calibration
max_luminance = 100; % from monitor calibration


% color settings
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

% open screen window
[window_ptr, window_rect] = PsychImaging('OpenWindow', screenNumber, grey);
[screenXpixels, screenYpixels] = Screen('WindowSize', window_ptr);


monitoor_flip_interval = Screen('GetFlipInterval', window_ptr);
[x_center,y_center] = RectCenter(window_rect)

%% Experiment module

% Experiment parameters

randseed = ClockRandSeed;

% Circles charachtristics
cricle_radius_degree = 2;    % In degree
circle_color = [1 1 1];
num_circle = 3;
num_seq = 10;
num_repeat = 1;
num_trial = num_seq * num_repeat;


% fixation point
fixation_size_degree = .5;
fixation_color = black;
fixation_location = [screenXpixels / 2,screenYpixels / 2];

presentation_window_degree = 20;

% Compute picxel per degree
ppd = pi/180 * screen_distance / screen_height * window_rect(4);     % Pixels per degree

% Convert degree to pixel
fixation_size_pixel = 2 * round(fixation_size_degree * ppd/2);
cricle_radius_pixel = 2 * round(cricle_radius_degree * ppd/2);
presentation_window_pixel = 2 * round(presentation_window_degree * ppd/2);
% Generate location sequences of the circles (10 different seauences)


% Grid setup
num_grids = 10;
grid_size = floor(presentation_window_pixel / num_grids);

% Generate all possible grid locations
[X, Y] = meshgrid(1:num_grids);
gridLocations = [X(:), Y(:)];


all_circle_locations = nan(10,6);


for seq = 1:num_seq

    % Randomly select 3 non-overlapping grids
    rand_grid = randperm(num_grids^2, num_circle);
    select_grid_location = gridLocations(rand_grid, :);

    % Calculate circle locations (center of the selected grids)
    cricle_locations = [(x_center - presentation_window_pixel/2 + select_grid_location(:,1)*grid_size)' ,...
        (y_center - presentation_window_pixel/2 + select_grid_location(:,2)*grid_size)'];
    all_circle_locations(seq,:) = cricle_locations;
end

response_table = nan(num_trial,13);
response_table(:,1) = 1:num_trial; % Trial's index
response_table(:,2:7)= repmat(all_circle_locations,num_repeat,1);


for trial_i =1:10

    cricle_locations_trial_i = [response_table(trial_i,2:4);response_table(trial_i,5:7)];

    % draw fixation point
    Screen('DrawDots', window_ptr, fixation_location, fixation_size_pixel, fixation_color, [], 2);
    Screen('Flip', window_ptr);

    % wait 3 seconds before showing circles
    WaitSecs(2);

    % draw circles one by one with 400 ms gap
    for j = 1:num_circle
        Screen('DrawDots', window_ptr, [response_table(trial_i,1+j);response_table(trial_i,4+j)], cricle_radius_pixel, circle_color, [], 2);
        Screen('Flip', window_ptr);
        WaitSecs(0.4);
    end

    % clear screen
    Screen('FillRect', window_ptr, grey);
    Screen('Flip', window_ptr);

    % play an auditory cue
    frequency = 440;
    duration = 1;
    cue = MakeBeep(frequency, duration);
    Snd('Play', cue);

    % wait for a click
    clicks = 0;
    responseLocations_trial_i = zeros(2, num_circle);
    while clicks < num_circle
        [x,y,buttons] = GetMouse(window_ptr);
        if any(buttons)
            clicks = clicks + 1;
            responseLocations_trial_i(:,clicks) = [x; y];
            WaitSecs(0.2); % small delay to prevent multiple responses at once
        end
    end

    response_table(trial_i,8:13) = [responseLocations_trial_i(1,:), responseLocations_trial_i(2,:)];
% 
%     all_response_locations(trial_i,1:3) = responseLocations_trial_i(1,:);
%     all_response_locations(trial_i,4:6) = responseLocations_trial_i(2,:);
% 
%     % calculate error
%     errors = sqrt(sum((cricle_locations - responseLocations_trial_i).^2));
%     averageError = mean(errors);
end

% % print error to console
% disp(['Average error was ' num2str(averageError) ' pixels.']);

% close screen
Screen('CloseAll');
%% System Reinstatement Module
Priority(0); % restore priority

plot(response_table(1:2,2:4)',response_table(1:2,5:7)','o-')
hold on
plot(response_table(1:2,8:10)',response_table(1:2,11:13)','o-')




% % plot clicking points as a trajectory
% figure;
% for k = 1:10
%     plot(all_response_locations(k,1:3), all_response_locations(k,4:6),'ro-','MarkerFaceColor','r');
%     hold on
% end
% hold on 
% plot(all_circle_locations(:,1:3),all_circle_locations(:,4:6),'o-')
% xlim([0 screenXpixels]);
% ylim([0 screenYpixels]);
% set(gca, 'YDir','reverse');  % Flip the Y-axis so it matches the screen coordinates
% title('Clicking trajectory');
% xlabel('X');
% ylabel('Y');
% grid on;
