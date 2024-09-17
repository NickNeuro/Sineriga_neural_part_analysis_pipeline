function [ ] = extract_info_glm_investment_I(subject_id)
%This function serves to extract the onset and duration of each screen of interest in the Investment task as specified in GLM-INVESTMENT-I. Where relevant we also extract the values shown on screen (for the pmods).
%This function extracts for a single participant (based on subject_id)
%these set of values for each trial in each of the runs of the Investment Task.
%The values that are extracted are based on GLM-INVESTMENT-I (see the pre-registration
%and companion document for more information).
%This function reads the trial information and timing information of each run separately
%and combines these into a structure called glm_data. This structure is saved separately for each run.

% Written by Alexandra Bagaini, Centre for Cognitive and Decision Sciences, Faculty of Psychology, University of Basel

%%%% INPUT %%%%
% subject_id = a string, e.g. '00001'. It defines the main ID of the participant used over all the three parts of the study

%%%% OUTPUT %%%%%
% glm_data = a structure 

% Overview of glm_data for runs in which AVG_RET is shown FIRST (i.e., condition A trials; see the pre-registration
%and companion document for more information):

% glm_data.avg_ret_first.onset =  onset of AVG_RET screen
% glm_data.avg_ret_first.duration  =  duration of AVG_RET screen
% glm_data.avg_ret_first.val  =  value shown on AVG_RET screen

% glm_data.vol_second.onset = onset of VOL screen
% glm_data.vol_second.duration = duration of VOL screen
% glm_data.vol_second.val = value shown on VOL screen

% glm_data.vol_first.onset =  EMPTY
% glm_data.vol_first.duration  =  EMPTY
% glm_data.vol_first.val  =  EMPTY

% glm_data.avg_ret_second.onset = EMPTY
% glm_data.avg_ret_second.duration = EMPTY
% glm_data.avg_ret_second.val = EMPTY

% glm_data.choice.onset = onset of choice screen
% glm_data.choice.duration = duration of choice screen
% glm_data.choice.val = EMPTY


% Overview of glm_data for runs in which AVG_RET is shown SECOND
%(i.e., condition B trials; see the pre-registration and companion document for more information):

% glm_data.avg_ret_first.onset =  EMPTY
% glm_data.avg_ret_first.duration  =  EMPTY
% glm_data.avg_ret_first.val  =  EMPTY


% glm_data.vol_second.onset = EMPTY
% glm_data.vol_second.duration = EMPTY
% glm_data.vol_second.val = EMPTY

% glm_data.vol_first.onset =  onset of VOL screen
% glm_data.vol_first.duration  =  duration of VOL screen
% glm_data.vol_first.val  =  value shown on VOL screen

% glm_data.avg_ret_second.onset = duration of AVG_RET screen
% glm_data.avg_ret_second.duration = onset of AVG_RET screen
% glm_data.avg_ret_second.val = value shown on AVG_RET screen

% glm_data.choice.onset = onset of choice screen
% glm_data.choice.duration = duration of choice screen
% glm_data.choice.val = EMPTY

%%%%Adjustments%%%%%
% Need to add/edit folder locations and file names where required!
% e.g., lines 77-79

% LAST MODIFIED: 16.06.2021 by Alexandra Bagaini
% Modification: edited description + renamed output var

% LAST MODIFIED 07.06.2021 by Nick Sidorenko, Zurich Center for Neuroeconomics, Philippe Tobler's group 
% Modification: definition of paths to the trial and value info

%% MAIN FILE/FOLDER PATHS
trial_info_folder = '';  % main location of Investment Task trial information folder (i.e., files containing information on the values shown on screen)
behaviour_folder = ''; % main location of Investment Task choices/timing information folder  (i.e., files containing the onsets of each screen; choices not analysed here)
outcome_folder =  ['' subject_id];%  folder to save roi analysis data
if ~exist(outcome_folder, 'dir'); mkdir(outcome_folder); end

%% CREATE DATASET FOR ANALYSIS


for currRun = 1 : 4 % four runs in total
    
    % empty structures
    avg_ret_first = struct();
    vol_second = struct();
    vol_first = struct();
    avg_ret_second = struct();
    choice = struct();
    
    beh_inputname = sprintf('InvestTaskChoices_sub_%s_run_%d',subject_id,currRun); % mat file containing choices/timing  (i.e., file containing the onsets of each screen; choices not analysed here)
    trial_inputname = sprintf('InvestTaskTrials_sub_%s_run_%d',subject_id,currRun); % mat file containing trial information (i.e., values shown on screen)
    
    % loading mat files
    timing_information = dir(fullfile(behaviour_folder, '**', [beh_inputname, '.mat'])); % information about the timing and values for the pmods
    timing_information = load([timing_information.folder filesep timing_information.name]);

    value_information = dir(fullfile(trial_info_folder, '**', [trial_inputname, '.mat'])); % information about the timing and values for the pmods
    value_information = load([value_information.folder filesep value_information.name]);
    
    % run_order
    run_order = value_information.investment_information.run_order(1);
    
    % type of trial; 
        %condition A occurs when:
            %run order is 1 and the run number is odd 
            % OR
            %run order is 2 and the run number is even
         %condition B occurs when:
            %run order is 1 and the run number is even 
            % OR
            %run order is 2 and the run number is odd    
            
    condition_a = (run_order == 1 & rem(currRun,2) ~= 0) | (run_order == 2 & rem(currRun,2) == 0);
    
    if condition_a % Condition A = AVG_RET presented first / VOL presented second 
            
            avg_ret_first.onset = timing_information.timing.display_a_start_times.';
            avg_ret_first.duration = timing_information.timing.isi_a_start_times.' - timing_information.timing.display_a_start_times.';
            avg_ret_first.val = value_information.investment_information.mean_return.';
            
            
            vol_second.onset = timing_information.timing.display_b_start_times.';
            vol_second.duration = timing_information.timing.isi_b_start_times.' - timing_information.timing.display_b_start_times.';
            vol_second.val = value_information.investment_information.volatility.';
            
            
            choice.onset = timing_information.timing.choice_start_times.';
            choice.duration = timing_information.timing.iti_start_times.' - timing_information.timing.choice_start_times.'; % or % timing_information.timing.choice_screen_duration
            choice.val = []; % not of interest
            
            % no trials of this type for that run
            
            vol_first.onset = [];
            vol_first.duration = [];
            vol_first.val = [];
            
            
            avg_ret_second.onset = [];
            avg_ret_second.duration = [];
            avg_ret_second.val = [];
            
            
            
        else   % Condition B = AVG_RET presented second / VOL presented first 
            
            vol_first.onset = timing_information.timing.display_a_start_times.';
            vol_first.duration = timing_information.timing.isi_a_start_times.' - timing_information.timing.display_a_start_times.';
            vol_first.val = value_information.investment_information.volatility.';
            
            
            avg_ret_second.onset = timing_information.timing.display_b_start_times.';
            avg_ret_second.duration = timing_information.timing.isi_b_start_times.' - timing_information.timing.display_b_start_times.';
            avg_ret_second.val = value_information.investment_information.mean_return.';
            
            
            choice.onset = timing_information.timing.choice_start_times.';
            choice.duration = timing_information.timing.iti_start_times.' - timing_information.timing.choice_start_times.'; % or % timing_information.timing.choice_screen_duration
            choice.val = []; % not of interest
            
            % no trials of this type for that run
            
            avg_ret_first.onset = [];
            avg_ret_first.duration = [];
            avg_ret_first.val = [];
            
            vol_second.onset = [];
            vol_second.duration = [];
            vol_second.val = [];
    
    end % condition A/B
    
    glm_data.avg_ret_first = avg_ret_first;
    glm_data.vol_first = vol_first;
    glm_data.avg_ret_second = avg_ret_second;
    glm_data.vol_second = vol_second;
    glm_data.choice = choice;
    
    
    % save output
    outputname = sprintf('GLM_INVESTMENT_I_sub_%s_run_%d.mat',subject_id,currRun);  % output file name
    save([outcome_folder filesep outputname], 'glm_data')
    
end % for loop run




end





