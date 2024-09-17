function [ ] = extract_info_glm_investment_II(subject_id)
%This function serves to extract the onset and duration of each screen of interest in the Investment task as specified in GLM-INVESTMENT-I. Where relevant we also extract the values shown on screen (for the pmods).
%This function extracts for a single participant (based on subject_id)
%these set of values for each trial in each of the runs of the Investment Task.
%The values that are extracted are based on GLM-INVESTMENT-II (see the pre-registration
%and companion document for more information).
%This function reads the trial information and timing information of each run separately
%and combines these into a structure called glm_data. This structure is saved separately for each run.

% Written by Alexandra Bagaini, Centre for Cognitive and Decision Sciences, Faculty of Psychology, University of Basel

%%%% INPUT %%%%
% subject_id = a string, e.g. '00001'. It defines the main ID of the participant used over all the three parts of the study

%%%% OUTPUT %%%%%
% glm_data = a structure 

% Overview of glm_data for runs in which AVG_RET is shown FIRST OR SECOND (no distinction between conditions):

% glm_data.avg_ret.onset =  onset of AVG_RET screen
% glm_data.avg_ret.duration  =  duration of AVG_RET screen
% glm_data.avg_ret.val  =  value shown on AVG_RET screen

% glm_data.vol.onset = onset of VOL screen
% glm_data.vol.duration = duration of VOL screen
% glm_data.vol.val = value shown on VOL screen

% glm_data.choice.onset = onset of choice screen
% glm_data.choice.duration = duration of choice screen
% glm_data.choice.val = EMPTY


%%%%Adjust%%%%%
% Folder location and file names where required!
% e.g., lines 44-46

% LAST MODIFIED: 16.06.2021 by Alexandra Bagaini
% Modification: edited description + renamed output var

% LAST MODIFIED 07.06.2021 by Nick Sidorenko,Zurich Center for Neuroeconomics, Philippe Tobler's group 
% Modification: definition of paths to the trial and value info

%% MAIN SAVING LOCATIONS
trial_info_folder = '';  % main location of Investment Task trial information folder (i.e., files containing information on the values shown on screen)
behaviour_folder = ''; % main location of Investment Task choices/timing information folder  (i.e., files containing the onsets of each screen; choices not analysed here)
outcome_folder =  ['' subject_id];%  folder to save roi analysis data
if ~exist(outcome_folder, 'dir'); mkdir(outcome_folder); end

%% CREATE DATASET FOR ROI ANALYSIS


for currRun = 1 : 4 % four runs in total
    
    % empty structures
    avg_ret = struct();
    vol = struct();
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
    
    %type of trial;
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
        
        avg_ret.onset = timing_information.timing.display_a_start_times.';
        avg_ret.duration = timing_information.timing.isi_a_start_times.' - timing_information.timing.display_a_start_times.';
        avg_ret.val = value_information.investment_information.mean_return.';
        
        
        vol.onset = timing_information.timing.display_b_start_times.';
        vol.duration = timing_information.timing.isi_b_start_times.' - timing_information.timing.display_b_start_times.';
        vol.val = value_information.investment_information.volatility.';
        
        
        choice.onset = timing_information.timing.choice_start_times.';
        choice.duration = timing_information.timing.iti_start_times.' - timing_information.timing.choice_start_times.'; % or % timing_information.timing.choice_screen_duration
        choice.val = []; % not of interest
        
        
    else   % Condition B = AVG_RET presented second / VOL presented first
        
        vol.onset = timing_information.timing.display_a_start_times.';
        vol.duration = timing_information.timing.isi_a_start_times.' - timing_information.timing.display_a_start_times.';
        vol.val = value_information.investment_information.volatility.';
        
        
        avg_ret.onset = timing_information.timing.display_b_start_times.';
        avg_ret.duration = timing_information.timing.isi_b_start_times.' - timing_information.timing.display_b_start_times.';
        avg_ret.val = value_information.investment_information.mean_return.';
        
        
        choice.onset = timing_information.timing.choice_start_times.';
        choice.duration = timing_information.timing.iti_start_times.' - timing_information.timing.choice_start_times.'; % or % timing_information.timing.choice_screen_duration
        choice.val = []; % not of interest
        
        
    end % Condition A or B
    
    glm_data.avg_ret = avg_ret;
    glm_data.vol = vol;
    glm_data.choice = choice;
    
    % save output
    outputname = sprintf('GLM_INVESTMENT_II_sub_%s_run_%d.mat',subject_id,currRun);  % output file name
    save([outcome_folder filesep outputname], 'glm_data')
    
    
end % for loop run

end





