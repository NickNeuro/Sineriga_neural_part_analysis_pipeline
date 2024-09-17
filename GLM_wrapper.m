%% README
% Written by Nick Doren, Zurich Center for Neuroeconomics, Philippe Tobler's group 

% This wrapper helps processing a single participant for Investment task. 
% Note that several participants can processed in a loop using this script

% Before running this script please read README.pdf
% (to make sure that your folders are organized in the right way, your scripts are adjusted to be run on your machine, etc.)

% As a final step before you run this script, please make sure that your SPM-toolbox folder is on the path

% Last update: 16.06.2021

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INVESTMENT TASK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Vectors where the neural indicators will be stored
% For GLM-I
outcome_first = [];
outcome_second = [];
risk_first = [];
risk_second = [];

% For GLM-II
outcome = [];
risk = [];

%% Arguments
subID = {''}; % as defined for the Sinergia project (e.g. {'00001'} or {'00001', '00002'})

for t = 1:length(subID)
    
    % The arguments on the next three line should be replaced by the path on YOUR local machine
    gen_path = ''; % path to the main folder with scripts, behavioral and MRI data
    beh_data_path = [gen_path filesep 'Raw_beh_data']; % path to the raw behavioral data from the scanner session (e.g. InvestTaskTrials_sub_00001_run_1.mat)
    mri_data_path = [gen_path filesep 'Preprocessed_mri_data\']; % path to the preprocessed fMRI data
    bids_id = [mri_data_path filesep 'participants.txt']; % path to the document where particiapnts' project ID are matched with participants' bids ID

    % Extract participant's ID according to bids format
    bids_subID = readtable(bids_id);
    bids_subID = bids_subID.participant_id(find(strcmp(bids_subID.data_id, ['SNS_MRI_FIN_S' subID{t} '_01'])));
    runs = 4; % maximal number of runs in the Investment task

    %% Smoothing
    prefix.smooth = 's';
    for r = 1:runs
        scanFiles_gz{r} = dir(fullfile(mri_data_path, '**', [bids_subID{1} '*run-' num2str(r) '_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz']));
        scanFiles_gz{r} = [scanFiles_gz{r}.folder filesep scanFiles_gz{r}.name];
        gunzip(scanFiles_gz{r}); % fmriprep output is .gz files => one should unzip them for further processing
        scanFiles{r} = dir(fullfile(mri_data_path, '**', [bids_subID{1} '*run-' num2str(r) '_space-MNI152NLin2009cAsym_desc-preproc_bold.nii']));
        scanFiles{r} = [scanFiles{r}.folder filesep scanFiles{r}.name];
    end
    smoothing(runs, scanFiles, prefix); % run smoothing

    %% PhysIO preprocessing
    physio_preprocessing(mri_data_path, bids_subID{1}, runs); % run extraction of nuisance (cardiac and respiratory regressors)

    %% GLM-I
    GLM_path_I = [gen_path filesep '\GLM_I\' subID{t}]; % path to the directory where the GLMs for each participant will be stored
    if ~exist(GLM_path_I, 'dir'); mkdir(GLM_path_I); end
        
    GLM_INVESTMENT_I(subID{t}, bids_subID{1}, gen_path, mri_data_path, GLM_path_I); % build up the GLM-I

    outcome_y_n = 1; risk_y_n = 1; % 1 = run a contrast for the corresponding variable of interest, 0 = run no contrast for the corresponding variable of interest
    change_names = 1; % 1 = you wish change names of created con.nii and spmT.nii files
    GLM_I_contrasts(GLM_path_I, outcome_y_n, risk_y_n, change_names); % run contrasts for neural outcome sensitivity

    %% GLM-II
    GLM_path_II = [gen_path filesep 'GLM_II\' subID{t}]; % path to the directory where the GLMs for each participant will be stored
    if ~exist(GLM_path_II, 'dir'); mkdir(GLM_path_II); end
        
    GLM_INVESTMENT_II(subID{t}, bids_subID{1}, gen_path, mri_data_path, GLM_path_II); % build up the GLM-I

    outcome_y_n = 1; risk_y_n = 1; % 1 = run a contrast for the corresponding variable of interest, 0 = run no contrast for the corresponding variable of interest
    change_names = 1; % 1 = you wish change names of created con.nii and spmT.nii files
    GLM_II_contrasts(GLM_path_II, outcome_y_n, risk_y_n, change_names); % run contrasts for neural outcome sensitivity

    %% Extract betas
    % Define masks
    mask_outcome = [gen_path filesep 'Scripts\bilateral_VS.nii']; % provide a full path to the .nii file of a binary mask
    mask_risk = [gen_path filesep '\Scripts\bilateral_AIns.nii']; % provide a full path to the .nii file of a binary mask
    
    % Extract participant's values for outcome and sensitivity from GLM-I
    outcome_first_subj = mean_beta_from_contrast_roi(GLM_path_I, 'con_outcome_first', mask_outcome);
    outcome_second_subj = mean_beta_from_contrast_roi(GLM_path_I, 'con_outcome_second', mask_outcome);
    risk_first_subj = mean_beta_from_contrast_roi(GLM_path_I, 'con_risk_first', mask_risk);
    risk_second_subj = mean_beta_from_contrast_roi(GLM_path_I, 'con_risk_second', mask_risk);
    
    % Extract participant's values for outcome and sensitivity from GLM-II
    outcome_subj = mean_beta_from_contrast_roi(GLM_path_II, 'con_outcome', mask_outcome);
    risk_subj = mean_beta_from_contrast_roi(GLM_path_II, 'con_risk', mask_risk);

    %% Create a vector of values for neural sensitivity to outcome and risk
    % From GLM-I
    outcome_first = [outcome_first; outcome_first_subj];
    outcome_second = [outcome_second; outcome_second_subj];
    risk_first = [risk_first; risk_first_subj];
    risk_second = [risk_second; risk_second_subj];

    % From GLM-II
    outcome = [outcome; outcome_subj];
    risk = [risk; risk_subj];

end % end of the main for loop

