function smoothing(runs, scanFiles, prefix)
%% README
% Written by Nick Doren, Zurich Center for Neuroeconomics.

% This function increases sensitivity by reducing thermal noise

% Last update: 18.05.2021

%% INPUTS
% runs = an integer, e.g. 4. It defines the number of runs (i.e. EPI to smooth) performed during the task
% scanFiles = a cell array. It defines the whole path to as well as the name of the image(s) to be smoothed
% prefix = a structure whose field 'smooth' defines the prefix to be put at the beginning of the smoothed image. E.g. prefix.smooth = 's';

k = 1; % only one job will be performed

spm_jobman('initcfg');

for r = 1:runs
    matlabbatch{k}.spm.spatial.smooth.data{r,1} = scanFiles{r};
end

matlabbatch{k}.spm.spatial.smooth.fwhm = [4 4 4]; % apply as little smoothing as possible to later run FSL Randomise 
matlabbatch{k}.spm.spatial.smooth.dtype = 0;
matlabbatch{k}.spm.spatial.smooth.im = 0;
matlabbatch{k}.spm.spatial.smooth.prefix = prefix.smooth;

spm_jobman('run', matlabbatch)
end