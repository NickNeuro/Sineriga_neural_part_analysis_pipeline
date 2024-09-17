function GLM_INVESTMENT_I(subID, bids_subID, gen_path, mri_data_path, GLM_path)

%% README
% Written by Nick Doren, Zurich Center for Neuroeconomics, Philippe Tobler's group 
% Based on the scripts provided by Dr. Silvia Maier.

% This function creates a GLM to assess neural sensitivity to outcome and risk during the Investment task
% The created GLM corresponds to the GLM-INVESTMENT_I, whose description may be found in the pre-registration and the companion document

% Last update: 16.06.2021

%% INPUT
% subID = a string, e.g. '00001'. It defines the main ID of the participant used over all the three parts of the study
% bids_subID = a string, e.g. 'sub-00111'. It defines the new ID, which was given to the images during their conversion into BIDS format
% beh_data_path = a string. It defines the whole path to the folder with behavioral data
% mri_data_path = a string. It defines the whole path to the folder with EPI
% Note that the script automatically finds the required images even in subfolders, so you can just provide a path to a common folder containing subfolders for all participants
% GLM_path = a string. It defines the whole path to the folder where the GLM-associated files will be stored


%% Arguments for Investment task
runs = 4; % there were a total of 4 runs in the task
scan_inf = dir(fullfile(mri_data_path, '**', [bids_subID '*run-1_bold.nii.gz'])); % all the EPI images have the same dimensions => we take the first one to get the number of scans
scan_inf = [scan_inf.folder filesep scan_inf.name];
gunzip(scan_inf); % spm_vol doesn't work with .gz files
scan_inf = spm_vol(scan_inf(1:end-3)); % get the info from the unzipped file
param.n_scans = length(scan_inf); % the number of scans per image => all the runs have the same number of images (211 in the Monetary task)
param.TR = 2.293; % repetition time (TR) in seconds

%% Create onsents based on the raw behavioral data
extract_info_glm_investment_I(subID);

%% GLM preparation
names = {'avg_ret_first', 'vol_second', 'vol_first', 'avg_ret_second', 'choice'};
onsets = cell(1,5);
durations = cell(1,5);
pmod_name = {'pmod_avg_ret_first', 'pmod_vol_second', 'pmod_vol_first', 'pmod_avg_ret_second'};
pmod_value = cell(1,4);
stick_regressor = []; % will flag volumes considered as motion outliers
R = []; % will be filled out with the nuisance regressors

%% Build up the design matrix
counter = 0; % will be used to concatanate onsets
for r = 1:runs 
    dataset = dir(fullfile(gen_path, '**', ['GLM_INVESTMENT_I_sub_' subID '_run_' num2str(r) '.mat'])); % information about the timing and values for the pmods
    dataset = load([dataset.folder filesep dataset.name]);
    %% Onsets
    % We build up all the 4 runs in the same model. Given that the onsets have 0 s a starting point
    % for each new run, we need to modify onsets as if it was acquired in one single run. We do this
    % by adding counter*param.n_scans*param.TR to each onset's time
    onsets{1} = cat(1, onsets{1}, dataset.glm_data.avg_ret_first.onset + counter*param.n_scans*param.TR); % average return on investment of the volatile asset on trials when it's seen first
    onsets{2} = cat(1, onsets{2}, dataset.glm_data.vol_second.onset + counter*param.n_scans*param.TR); % volatility of the volatile asset on trials when it's seen second
    onsets{3} = cat(1, onsets{3}, dataset.glm_data.vol_first.onset + counter*param.n_scans*param.TR); % volatility of the volatile asset on trials when it's seen first
    onsets{4} = cat(1, onsets{4}, dataset.glm_data.avg_ret_second.onset + counter*param.n_scans*param.TR); % average return on investment on trials when it's seen second
    onsets{5} = cat(1, onsets{5}, dataset.glm_data.choice.onset + counter*param.n_scans*param.TR); % choice + safe asset screen for all trials
    counter = counter + 1;
    
    %% Durations
    durations{1} = cat(1, durations{1}, dataset.glm_data.avg_ret_first.duration);
    durations{2} = cat(1, durations{2}, dataset.glm_data.vol_second.duration);
    durations{3} = cat(1, durations{3}, dataset.glm_data.vol_first.duration);
    durations{4} = cat(1, durations{4}, dataset.glm_data.avg_ret_second.duration); 
    durations{5} = cat(1, durations{5}, dataset.glm_data.choice.duration); % reaction time

    %% Parametric modulators
    pmod_value{1} = cat(1, pmod_value{1}, dataset.glm_data.avg_ret_first.val'); % value of the average return on investment 
    pmod_value{2} = cat(1, pmod_value{2}, dataset.glm_data.vol_second.val'); % value of the average return on investment 
    pmod_value{3} = cat(1, pmod_value{3}, dataset.glm_data.vol_first.val'); % value of the volatility
    pmod_value{4} = cat(1, pmod_value{4}, dataset.glm_data.avg_ret_second.val'); % value of the volatility

    %% Physiological and movement regressors
    % fmriprep confounds file
    confounds = dir(fullfile(mri_data_path, '**', [bids_subID '*run-' num2str(r) '_desc-confounds_timeseries.tsv']));
    copyfile([confounds.folder filesep confounds.name], [confounds.folder filesep confounds.name(1:end-3) 'txt']); % original confounds file is in .tsv format
    confounds = readtable([confounds.folder filesep confounds.name(1:end-3) 'txt']); % readtable doesn't work with .tsv => we need a conversion into .txt   
    
    % Extract movement regressors
    mov_reg = table2array(confounds(:,find(strcmp(confounds.Properties.VariableNames, {'trans_x'}))));
    mov_reg = [mov_reg((1:param.n_scans),:), table2array(confounds(:,find(strcmp(confounds.Properties.VariableNames, {'trans_y'}))))];
    mov_reg = [mov_reg((1:param.n_scans),:), table2array(confounds(:,find(strcmp(confounds.Properties.VariableNames, {'trans_z'}))))];
    mov_reg = [mov_reg((1:param.n_scans),:), table2array(confounds(:,find(strcmp(confounds.Properties.VariableNames, {'rot_x'}))))];
    mov_reg = [mov_reg((1:param.n_scans),:), table2array(confounds(:,find(strcmp(confounds.Properties.VariableNames, {'rot_y'}))))];
    mov_reg = [mov_reg((1:param.n_scans),:), table2array(confounds(:,find(strcmp(confounds.Properties.VariableNames, {'rot_z'}))))];

    % Stick regressor to flag volumes identified as motion outliers by fmriprep
    stick_regressor_temp = sum(table2array(confounds(:,find(contains(confounds.Properties.VariableNames, 'motion_outlier')))),2);
    stick_regressor = [stick_regressor; stick_regressor_temp(1:param.n_scans)];
    
    % Make physio and motion nuisance regressor (multiple regressor) files output of retroicor
     physio_temp = dir(fullfile(mri_data_path, '**', bids_subID, '**', ['fc_multiple_regressors_run_', num2str(r), '.txt']));
     physio = importdata([physio_temp.folder filesep physio_temp.name]);
            
     % Put together physio and movement regressors
     mov_reg = [physio((1:param.n_scans),:), mov_reg(1:param.n_scans,:)];
     
     % Increment the whole table of nuisance regressors by the current run                          
     R = [R; mov_reg];
     
     % Store the nuisance regressors as a separate file
     save([physio_temp.folder filesep 'physio_movement_regressors.mat'], 'R'); 
        
end

%% Add stick regressor
if any(stick_regressor)
    R = [R, stick_regressor];
    save([physio_temp.folder filesep 'physio_movement_regressors.mat'], 'R'); 
end

%% Matlabbatch setting
m = 1;
for c = 1:5
    matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).name = names{c};
    matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).onset = onsets{c};
    matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).duration = durations{c};
    matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).tmod = 0;
    matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).orth = 0;
    if strcmp(names{c}, 'avg_ret_first')
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.name = pmod_name{1};
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.param = pmod_value{1};
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.poly = 1;
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).orth = 1;
   elseif strcmp(names{c}, 'vol_second')
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.name = pmod_name{2};
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.param = pmod_value{2};
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.poly = 1;
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).orth = 1;
    elseif strcmp(names{c}, 'vol_first')
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.name = pmod_name{3};
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.param = pmod_value{3};
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.poly = 1;
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).orth = 1;
    elseif strcmp(names{c}, 'avg_ret_second')
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.name = pmod_name{4};
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.param = pmod_value{4};
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod.poly = 1;
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).orth = 1;
    else
        matlabbatch{m}.spm.stats.fmri_spec.sess.cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {});              
    end
end 

% Pass the scan files
scans = cellstr('');
for r = 1:runs
    % Scan file
    scanFiles{r} = dir(fullfile(mri_data_path, '**', ['s' bids_subID '*run-' num2str(r) '_space-MNI152NLin2009cAsym_desc-preproc_bold.nii'])); % we take smoothed images (starting with prefix 's')
    scans_temp = strcat([scanFiles{r}.folder filesep],cellstr(spm_select('ExtList', scanFiles{r}.folder, scanFiles{r}.name,inf)));
    scans = cat(1, scans, scans_temp);
end 
scans = scans(2:end,:); % remove the empty cell at the beginning
matlabbatch{m}.spm.stats.fmri_spec.sess.scans = scans;

% Load physio
reg_file = [physio_temp.folder filesep 'physio_movement_regressors.mat'];
matlabbatch{m}.spm.stats.fmri_spec.sess.multi_reg = {reg_file};

% There are no additional regressors
matlabbatch{m}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
matlabbatch{m}.spm.stats.fmri_spec.sess.hpf = 128;

% General parameters / SPM defaults for first level model
matlabbatch{m}.spm.stats.fmri_spec.dir = {GLM_path}; % path for the GLM output
matlabbatch{m}.spm.stats.fmri_spec.timing.RT = param.TR; % time repetition
matlabbatch{m}.spm.stats.fmri_spec.timing.fmri_t = 16;
matlabbatch{m}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
matlabbatch{m}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{m}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{m}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{m}.spm.stats.fmri_spec.volt = 1;
matlabbatch{m}.spm.stats.fmri_spec.global = 'None';
matlabbatch{m}.spm.stats.fmri_spec.mthresh = 0.8; % masking threshold. Everything below this value won't be considered
% Run within explicit mask of skull-striped brain:
matlabbatch{m}.spm.stats.fmri_spec.mask = {''}; % whole path to the binary mask of the whole brain (the binary mask has values of 0 or 1 => it will pass the 0.8 threshold)
matlabbatch{m}.spm.stats.fmri_spec.cvi = 'AR(1)'; % autocorrelation matrix
    
m = m + 1;
    
spm_jobman('initcfg');
    
matlabbatch{m}.spm.stats.fmri_est.spmmat = {[GLM_path filesep 'SPM.mat']};
matlabbatch{m}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{m}.spm.stats.fmri_est.method.Classical = 1; % use Restricted Maximum Likelihood (REML) method

spm_jobman('run', matlabbatch)
clear matlabbatch

end