function subMean = mean_beta_from_contrast_roi(GLM_path, contrast, mask)

% Written by Nick Doren, Zurich Center for Neuroeconomics, Philippe Tobler's group 
% Based on the scripts provided by Dr. Silvia Maier.

% This functions extracts mean beta values in a given contrast for a given participant

% Inputs:
% GLM_path = a string; it defines the full path to SPM.mat file 
% contrast = a string; it defines the name of the contrast of interest
% mask = a string; it defines the full path to the binary mask corresponding to the region of interest

% Outputs:
% subMean = a real number; it defines the mean beta estimates calculated for a given contrast 
% for a given participant extracted from a given region of interest

%% Load GLM for a given participant
GLM_data = dir(fullfile(GLM_path, '**', 'SPM.mat'));
s = load([GLM_data.folder filesep GLM_data.name]); % load the GLM for a given subject

XYZ  = s.SPM.xVol.XYZ;
Z = spm_get_data(mask, XYZ);  

%% Select the list of voxels > 0 in the mask
included_voxels = XYZ(:, Z > 0); clear Z; % takes only the voxels defined by the mask

contrast_file = dir(fullfile(GLM_path, '**', [contrast '.nii'])); % the file will be found automatically by the name
voxels = spm_get_data([contrast_file.folder filesep contrast_file.name], included_voxels);
subMean = nanmean(voxels); % gets a mean of only those voxels that have a value (not defined as NaN)

end