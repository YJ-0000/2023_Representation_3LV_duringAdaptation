%% initialize
clear; clc;

currentPath = pwd;
cd ../temp
load('tempFileForAnalysis.mat');

cd(pathBIDS);
cd derivatives
pathDeriv = pwd;

cd(pathDeriv);
cd('spm-preproc'); % For saving preprocessed file from SPM
pathPrepFile = pwd;
prepSubjFolders = dir('sub*');

cd(pathDeriv);
cd('behavior');
pathBehav = pwd;
load('beh_results.mat');

cd(pathDeriv);
mkdir('spm-bold'); cd('spm-bold');
pathBOLD = pwd;
mkdir('bold-1stlevel'); cd('bold-1stlevel');
path1LV = pwd;
bold_1st_subj = dir('sub-*');

contrast_names = {'rot_pos_90','rot_neg_90','mirror'};

for ncon = 1:length(contrast_names)
    cd(pathBOLD);
    mkdir(['GroupLevel_' contrast_names{ncon} '_regression']); cd(['GroupLevel_' contrast_names{ncon} '_regression']);
    targetPath = pwd;

    %%
    nscan = 0;
    for nsub = 1:length(bold_1st_subj)
        nscan = nscan + 1;
        conFileList{nscan,1} = [bold_1st_subj(nsub).folder filesep bold_1st_subj(nsub).name filesep 'con_' num2str(ncon,'%04d') '.nii'];
    end
    conFileList(outlier_idx) = [];    
    
    performance_eachsub(is_tooExplored_trial) = nan;
    for nsub = 1:length(bold_1st_subj)
        nday = 2;
        mean_perf_eachsub(nsub,1) = mean(performance_eachsub(nsub,nday,squeeze(session_typeidx_eachsub(nsub,nday,:)==1),:),'all',"omitnan") ...
            + mean(performance_eachsub(nsub,nday,squeeze(session_typeidx_eachsub(nsub,nday,:)==2),:),'all',"omitnan");
    end
    mean_perf_eachsub(outlier_idx) = [];

    clear matlabbatch
    matlabbatch{1}.spm.stats.factorial_design.dir = {targetPath};
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.scans = conFileList;
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov.c = mean_perf_eachsub;
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov.cname = 'Session accuracy';
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov.iCC = 1;
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.incint = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {[pathSPM '\tpm\mask_ICV.nii,1']};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'result';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [0 1];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;

    disp('run');
    spm_jobman('run', matlabbatch);
end