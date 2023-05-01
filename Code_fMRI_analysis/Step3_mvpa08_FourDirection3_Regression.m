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
cd('spm-mvpa');
pathSPMmvpa = pwd;
cd('glm-1stlevel');
path1LV = pwd;
results1st_subj = dir('sub-*');

ses_names = {'rot_pos90','rot_neg90','mirror'};

for nses = 1:length(ses_names)

    cd(pathSPMmvpa);
    cd(['MVPA_FourDirection_' ses_names{nses}]);
    pathMVPA = pwd;
    mvpa_1st_subj = dir('sub-*');

    cd ..
    mkdir(['GroupLevel_MVPA_FourDirection_' ses_names{nses} '_Regression']); cd(['GroupLevel_MVPA_FourDirection_' ses_names{nses} '_Regression']);
    targetPath = pwd;

    %%
    nscan = 0;
    for nsub = 1:length(mvpa_1st_subj)
        nscan = nscan + 1;
        resFileList{nscan,1} = [mvpa_1st_subj(nsub).folder filesep mvpa_1st_subj(nsub).name filesep 's8wres_accuracy_minus_chance.nii'];
    end
    resFileList(outlier_idx) = [];
    
    performance_eachsub(is_tooExplored_trial) = nan;
    for nsub = 1:length(mvpa_1st_subj)
        nday = 2;
        mean_perf_eachsub(nsub,1) = mean(performance_eachsub(nsub,nday,squeeze(session_typeidx_eachsub(nsub,nday,:)==nses),:),'all',"omitnan");
    end
    mean_perf_eachsub(outlier_idx) = [];

    clear matlabbatch
    matlabbatch{1}.spm.stats.factorial_design.dir = {targetPath};
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.scans = resFileList;
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