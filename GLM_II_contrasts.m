function GLM_II_contrasts(GLM_path, outcome, risk, change_names)

%% README
% Written by Nick Doren, Zurich Center for Neuroeconomics, Philippe Tobler's group 
% Based on the scripts written by Dr. Silvia Maier.

% This function calculates the contrast to extract the BOLD signal associated with neural sensitivity to outcome and risk
% This function creates contrast maps and thresholded t-maps
% This function runs the contrast calculation based on the GLM-INVESTMENT-II

% Input argument:
% GLM_path = a string; defines the path to the folder where lives the SPM.mat file.
% outcome = a integer; defines whether the contrast for neural sensitivity to outcome should be run. 1 = yes, 0 = no
% risk = a integer; defines whether the contrast for neural sensitivity to risk should be run. 1 = yes, 0 = no
% change_names = a integer; defines whether the contrast maps should be renamed. 1 = yes, 0 = no

% Last update: 16.06.2021

spm_matrix = load([GLM_path filesep 'SPM.mat']);

m = 1; con = 0;
matlabbatch{m}.spm.stats.con.spmmat = {[GLM_path filesep 'SPM.mat']};

%% Create a contrast for neural sensitivity to outcome
if outcome
    con = con + 1;
    % Contrast definition
    contrasts = zeros(1, length(spm_matrix.SPM.xX.name)); % initial vector is a null vector
    for c = 1:length(contrasts)
        temp = spm_matrix.SPM.xX.name(c);
        if contains(temp{1}, 'avg_retxpmod_avg_ret^1') 
            contrasts(c) = 1; % only the pmod on the onset avrgret_first should be 1
        end
    end

    matlabbatch{m}.spm.stats.con.consess{con}.tcon.name = 'Outcome_sensitivity_pmod';
    matlabbatch{m}.spm.stats.con.consess{con}.tcon.convec = contrasts;
    matlabbatch{m}.spm.stats.con.consess{con}.tcon.sessrep = 'none';  % don't replicate over sessions (replsc) if using create_cons function b/c already done
end

%% Create a contrast for neural sensitivity to risk
if risk
    con = con + 1;
    % Contrast definition
    contrasts = zeros(1, length(spm_matrix.SPM.xX.name)); % initial vector is a null vector
    for c = 1:length(contrasts)
        temp = spm_matrix.SPM.xX.name(c);
        if contains(temp{1}, 'volxpmod_vol^1')
            contrasts(c) = 1; % only the pmod on the onset vol_first should be 1
        end
    end

    matlabbatch{m}.spm.stats.con.consess{con}.tcon.name = 'Risk_sensitivity_pmod';
    matlabbatch{m}.spm.stats.con.consess{con}.tcon.convec = contrasts;
    matlabbatch{m}.spm.stats.con.consess{con}.tcon.sessrep = 'none';  % don't replicate over sessions (replsc) if using create_cons function b/c already done
end

spm_jobman('run', matlabbatch) % execute job and create con.nii files

%% Change the names of the created files
if change_names
    % Both outcome and risk contrasts were run
    if outcome && risk
        copyfile([GLM_path filesep 'con_0001.nii'], [GLM_path filesep 'con_outcome.nii']);
        copyfile([GLM_path filesep 'con_0002.nii'], [GLM_path filesep 'con_risk.nii']);
        copyfile([GLM_path filesep 'spmT_0001.nii'], [GLM_path filesep 'spmT_outcome.nii']);
        copyfile([GLM_path filesep 'spmT_0002.nii'], [GLM_path filesep 'spmT_risk.nii']);
    end
    
   % Only outcome contrast was run 
   if outcome && ~risk
        copyfile([GLM_path filesep 'con_0001.nii'], [GLM_path filesep 'con_outcome.nii']);
        copyfile([GLM_path filesep 'spmT_0001.nii'], [GLM_path filesep 'spmT_outcome.nii']);
   end

   % Only risk contrast was run 
   if ~outcome && risk
        copyfile([GLM_path filesep 'con_0001.nii'], [GLM_path filesep 'con_risk.nii']);
        copyfile([GLM_path filesep 'spmT_0001.nii'], [GLM_path filesep 'spmT_risk.nii']);
   end

end

end