function physio_preprocessing(mri_data_path, bids_subID, runs)

% Written by Nick Doren, Zurich Center for Neuroeconomics, Philippe Tobler's group 
% Based on code contributions by Micah Edelson and Silvia Maier

% This function creates a batch to run RETROICOR with the TAPAS physIO toolbox
% integrated in SPM12 (6225)

% Inputs:
% mri_data_path = a string; it defines the full path to the MRI data 
%(it may be a general folder with the data of all participants - the script will find the right dataset itself)
% bids_subID = a string; it defines the participant's ID according to the bids format (e.g., bids_subID = 'sub-00111')
% runs = an integer; it defines the number of runs for which extraction of nuisance regressors should be carried out (e.g. runs = 4)

% Last update: 16.06.2021
%% Set paths and parameters

% slice timing: enter number of slices
scanFiles_temp = dir(fullfile(mri_data_path, '**', [bids_subID '*run-1_bold.nii.gz']));
scanFiles = [scanFiles_temp.folder filesep scanFiles_temp.name];
gunzip(scanFiles);
scan_inf = spm_vol(scanFiles(1:end-3));

param.TR = 2.293; %repetition time (TR) in seconds
param.n_dummies = 5; % number of dummies - how many discarded volumes were recorded in the beginning to allow the field to stabilize
param.n_scans = length(scan_inf); % number of volumes that were acquired within the run
param.n_slices = scan_inf(1).dim(3); % how many slices were acquired

OP_folder = dir(fullfile(mri_data_path, '**', [bids_subID '*run-1_desc-confounds_timeseries.tsv']));
OP_folder =[OP_folder.folder filesep 'physio_output/']; % where the output is saved
mkdir(OP_folder);

spm_jobman('initcfg');
for r = 1:runs      
    % path to files with ECG and breathing belt information
    physio_file = dir([scanFiles_temp.folder filesep '*run' num2str(r) '*scanphys*log']); % name of the physio files acquired with the Philips Achieva scanner in the SNS Lab
    physio_file = [physio_file.folder filesep physio_file.name];

    % create matlabbatch
    matlabbatch{r}.spm.tools.physio.save_dir = {OP_folder};
    matlabbatch{r}.spm.tools.physio.log_files.vendor = 'Philips';
    matlabbatch{r}.spm.tools.physio.log_files.cardiac = {physio_file}; % location of the log file for cardiac information
    matlabbatch{r}.spm.tools.physio.log_files.respiration = {physio_file}; % same path for respiration (breathing belt) data
    matlabbatch{r}.spm.tools.physio.log_files.scan_timing = [];
    matlabbatch{r}.spm.tools.physio.log_files.sampling_interval = 0.002; % 2 millisecond time resolution for the acquisition of ECG and breathing data
    matlabbatch{r}.spm.tools.physio.log_files.relative_start_acquisition = 0;
    % below specify the alignment of the scanner data to the log file -
    % "last" means that the physIO toolbox will start looking from
    % the last volume and count back the indicated number of volumes
    % that you acquired; this is our best option because the physIO recording
    % starts already during scanner preparation, before the actual run
    matlabbatch{r}.spm.tools.physio.log_files.align_scan = 'last';
    matlabbatch{r}.spm.tools.physio.scan_timing.sqpar.Nslices = param.n_slices; % how many slices were acquired
    matlabbatch{r}.spm.tools.physio.scan_timing.sqpar.NslicesPerBeat = []; % only for triggered (gated) sequences
    matlabbatch{r}.spm.tools.physio.scan_timing.sqpar.TR = param.TR; % repetition time
    matlabbatch{r}.spm.tools.physio.scan_timing.sqpar.Ndummies = param.n_dummies; % number of dummies - how many discarded volumes were recorded in the beginning to allow the field to stabilize
    matlabbatch{r}.spm.tools.physio.scan_timing.sqpar.Nscans = param.n_scans; % number of volumes that were acquired within the run
    matlabbatch{r}.spm.tools.physio.scan_timing.sqpar.onset_slice = floor(param.n_slices/2); % reference slice - put the same as in the preprocessing (refslice = floor(nr slices/2))
    matlabbatch{r}.spm.tools.physio.scan_timing.sqpar.time_slice_to_slice = []; % time between slices; if empty set as defult to TR/N slices
    matlabbatch{r}.spm.tools.physio.scan_timing.sqpar.Nprep = []; % count preparation pulses before 1 dummy - only fill if you use "first scan"
    matlabbatch{r}.spm.tools.physio.scan_timing.sync.gradient_log.grad_direction = 'y'; % use this gradient direction to detect heartbeat signal
    matlabbatch{r}.spm.tools.physio.scan_timing.sync.gradient_log.zero = 0.4;
    matlabbatch{r}.spm.tools.physio.scan_timing.sync.gradient_log.slice = 0.45;
    matlabbatch{r}.spm.tools.physio.scan_timing.sync.gradient_log.vol = []; % leave [] if unused; set value >= slice, if volume start gradients are higher than slice gradients
    matlabbatch{r}.spm.tools.physio.scan_timing.sync.gradient_log.vol_spacing = []; % leave [] if unused
    matlabbatch{r}.spm.tools.physio.preproc.cardiac.modality = 'ECG';
    matlabbatch{r}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.min = 0.4;
    matlabbatch{r}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.file = 'initial_cpulse_kRpeakfile.mat';
    matlabbatch{r}.spm.tools.physio.preproc.cardiac.posthoc_cpulse_select.off = struct([]); % allows to manually correct missing data (<20 pulses missing)
    matlabbatch{r}.spm.tools.physio.model.type = 'RETROICOR';
    matlabbatch{r}.spm.tools.physio.model.retroicor.yes.order.c = 3;
    matlabbatch{r}.spm.tools.physio.model.retroicor.yes.order.r = 4;
    matlabbatch{r}.spm.tools.physio.model.retroicor.yes.order.cr = 1;
    matlabbatch{r}.spm.tools.physio.model.orthogonalise = 'none';
    % below commented out because we modeled movement separately
    % matlabbatch{r}.spm.tools.physio.model.movement.yes.file_realignment_parameters = {[D_folder,'\rp_sn_*.txt']};
    % matlabbatch{r}.spm.tools.physio.model.movement.yes.outlier_translation_mm = Inf;
    % matlabbatch{r}.spm.tools.physio.model.movement.yes.outlier_rotation_deg = Inf;
    % Extraction of movement regressors
    temp_1 = dir(fullfile(mri_data_path, '**', [bids_subID '*run-' num2str(r) '_desc-confounds_timeseries.tsv']));
    copyfile([temp_1.folder filesep temp_1.name], [temp_1.folder filesep temp_1.name(1:end-3) 'txt'])
    temp_2 = readtable([temp_1.folder filesep temp_1.name(1:end-3) 'txt']);
    temp_3 = [temp_2.trans_x, temp_2.trans_y, temp_2.trans_z, temp_2.rot_x, temp_2.rot_y temp_2.rot_z];
    save([OP_folder filesep 'rp_' num2str(r) '.txt'], 'temp_3', '-ascii'); clear temp_1 temp_2 temp_3;
    %
    matlabbatch{r}.spm.tools.physio.model.input_other_multiple_regressors = {[OP_folder filesep 'rp_' num2str(r) '.txt']};
    matlabbatch{r}.spm.tools.physio.model.output_multiple_regressors = ['fc_multiple_regressors_run_' num2str(r) '.txt'];% output file
    matlabbatch{r}.spm.tools.physio.verbose.level = 2; % verbosity level of figures (can enter 1 (no output) until 3 for intense debugging)
    matlabbatch{r}.spm.tools.physio.verbose.fig_output_file = ['PhysIO_output_level2_run_' num2str(r) '.fig']; % output figure names
    matlabbatch{r}.spm.tools.physio.verbose.use_tabs = false;
end

spm_jobman('run', matlabbatch)

end