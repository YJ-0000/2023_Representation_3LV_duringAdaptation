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
cd('glm-1stlevel');
path1LV = pwd;
results1st_subj = dir('sub-*');

cd ..
mkdir('MVPA_TaskContext_CV_posneg90s'); cd('MVPA_TaskContext_CV_posneg90s');
pathMVPA = pwd;

parfor nsub = 1:length(results1st_subj)
    
    cd(pathMVPA);
    mkdir(results1st_subj(nsub).name); cd(results1st_subj(nsub).name);
    targetPath = pwd;
    
    cfg = decoding_defaults;

    % Set the analysis that should be performed (default is 'searchlight')
    cfg.analysis = 'searchlight'; % standard alternatives: 'wholebrain', 'ROI' (pass ROIs in cfg.files.mask, see below)
    cfg.searchlight.radius = 3; % use searchlight of radius 3 (by default in voxels), see more details below

    % Set the output directory where data will be saved, e.g. 'c:\exp\results\buttonpress'
    cfg.results.dir = targetPath;

    % Set the filepath where your SPM.mat and all related betas are, e.g. 'c:\exp\glm\model_button'
    beta_loc = [results1st_subj(nsub).folder filesep results1st_subj(nsub).name];

    % Set the filename of your brain mask (or your ROI masks as cell matrix) 
    % for searchlight or wholebrain e.g. 'c:\exp\glm\model_button\mask.img' OR 
    % for ROI e.g. {'c:\exp\roi\roimaskleft.img', 'c:\exp\roi\roimaskright.img'}
    % You can also use a mask file with multiple masks inside that are
    % separated by different integer values (a "multi-mask")

%     cfg.files.mask = mask_file;

    % Set the label names to the regressor names which you want to use for 
    % decoding, e.g. 'button left' and 'button right'
    % don't remember the names? -> run display_regressor_names(beta_loc)
    % infos on '*' (wildcard) or regexp -> help decoding_describe_data
        labelnames_all = {'erasing_rotation+90_leftward','erasing_rotation+90_rightward','erasing_rotation+90_upward','erasing_rotation+90_downward', ...
                        'erasing_rotation-90_leftward','erasing_rotation-90_rightward','erasing_rotation-90_upward','erasing_rotation-90_downward', ...
                        'erasing_mirror_leftward','erasing_mirror_rightward','erasing_mirror_upward','erasing_mirror_downward'};

    % labelname1  = 
    % labelname2  = 

%     labelnames = {'erasing_Rot90_leftward','erasing_Rot90_rightward','erasing_Rot270_leftward','erasing_Rot270_rightward'};
%     labelnames = {'erasing_Rot90_upward','erasing_Rot90_downward','erasing_Rot270_upward','erasing_Rot270_downward'};
    labelnames = labelnames_all(1:8);

    % labelvalue1 = 1; % value for labelname1
    % labelvalue2 = -1; % value for labelname2
%     labelvalues = [1,1,1,1,2,2,2,2,3,3,3,3];
    labelvalues = [1,1,1,1,-1,-1,-1,-1];

    %% Set additional parameters
    % Set additional parameters manually if you want (see decoding.m or
    % decoding_defaults.m). Below some example parameters that you might want 
    % to use a searchlight with radius 12 mm that is spherical:

    % cfg.searchlight.unit = 'mm';
    % cfg.searchlight.radius = 12; % if you use this, delete the other searchlight radius row at the top!
    % cfg.searchlight.spherical = 1;
    % cfg.verbose = 2; % you want all information to be printed on screen
    % cfg.decoding.train.classification.model_parameters = '-s 0 -t 0 -c 1 -b 0 -q'; 

    % Enable scaling min0max1 (otherwise libsvm can get VERY slow)
    % if you dont need model parameters, and if you use libsvm, use:
    cfg.scale.method = 'min0max1';
    cfg.scale.estimation = 'all'; % scaling across all data is equivalent to no scaling (i.e. will yield the same results), it only changes the data range which allows libsvm to compute faster

    % if you like to change the decoding software (default: libsvm):
    % cfg.decoding.software = 'liblinear'; % for more, see decoding_toolbox\decoding_software\. 
    % Note: cfg.decoding.software and cfg.software are easy to confuse.
    % cfg.decoding.software contains the decoding software (standard: libsvm)
    % cfg.software contains the data reading software (standard: SPM/AFNI)

    % Some other cool stuff
    % Check out 
    %   combine_designs(cfg, cfg2)
    % if you like to combine multiple designs in one cfg.

    %% Decide whether you want to see the searchlight/ROI/... during decoding
    cfg.plot_selected_voxels = 500; % 0: no plotting, 1: every step, 2: every second step, 100: every hundredth step...

    %% Add additional output measures if you like
    % See help decoding_transform_results for possible measures

    % cfg.results.output = {'accuracy_minus_chance', 'AUC'}; % 'accuracy_minus_chance' by default

    % You can also use all methods that start with "transres_", e.g. use
    %   cfg.results.output = {'SVM_pattern'};
    % will use the function transres_SVM_pattern.m to get the pattern from 
    % linear svm weights (see Haufe et al, 2015, Neuroimage)

    %% Nothing needs to be changed below for a standard leave-one-run out cross
    %% validation analysis.

    % The following function extracts all beta names and corresponding run
    % numbers from the SPM.mat
    regressor_names = design_from_spm(beta_loc);

    % Extract all information for the cfg.files structure (labels will be [1 -1] if not changed above)
    cfg = decoding_describe_data(cfg,labelnames,labelvalues,regressor_names,beta_loc);

    cfg.files.chunk = repmat((1:5)', [length(labelnames),1]);

    % This creates the leave-one-run-out cross validation design:
    cfg.design = make_design_cv(cfg); 
    
    temp_mat_train = zeros(40,8);
    temp_mat_test = zeros(40,8);
    %
    temp_mat_train(contains(cfg.files.labelname,'rotation-90_upward'),1) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation+90_upward'),1) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation-90_rightward'),1) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation+90_leftward'),1) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation-90_leftward'),2) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation+90_leftward'),2) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation-90_upward'),2) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation+90_downward'),2) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation-90_rightward'),3) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation+90_rightward'),3) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation-90_downward'),3) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation+90_upward'),3) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation-90_downward'),4) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation+90_downward'),4) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation-90_leftward'),4) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation+90_rightward'),4) = 1;
    %
    temp_mat_test(contains(cfg.files.labelname,'rotation-90_upward'),5) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation+90_upward'),5) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation-90_rightward'),5) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation+90_leftward'),5) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation-90_leftward'),6) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation+90_leftward'),6) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation-90_upward'),6) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation+90_downward'),6) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation-90_rightward'),7) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation+90_rightward'),7) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation-90_downward'),7) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation+90_upward'),7) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation-90_downward'),8) = 1;
    temp_mat_test(contains(cfg.files.labelname,'rotation+90_downward'),8) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation-90_leftward'),8) = 1;
    temp_mat_train(contains(cfg.files.labelname,'rotation+90_rightward'),8) = 1;
    
    %
    temp_mat_train_re = zeros(size(temp_mat_train,1),size(temp_mat_train,2)*5);
    temp_mat_test_re = zeros(size(temp_mat_test,1),size(temp_mat_test,2)*5);
    temp_n = 0;
    for nreg = 1:size(temp_mat_train,2)
        for nrep = 1:5
            temp_n = temp_n + 1;
            temp_mat_train_re(:,temp_n) = temp_mat_train(:,nreg);
            temp_idx = find(temp_mat_train(:,nreg));
            temp_mat_train_re([temp_idx(nrep),temp_idx(5+nrep)],temp_n) = 0;
            temp_idx = find(temp_mat_test(:,nreg));
            temp_mat_test_re([temp_idx(nrep),temp_idx(5+nrep)],temp_n) = 1;
        end
    end
    
    
    cfg.design.train = temp_mat_train_re;
    cfg.design.test = temp_mat_test_re;
    cfg.design.label = repmat(cfg.design.label(:,1),[1,8*5]);
    cfg.design.set = repmat(cfg.design.set(:,1),[1,8*5]);

    % Run decoding
    results = decoding(cfg);
end