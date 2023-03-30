%% initialize
clear; clc;

pathCurrent = pwd;
cd ../temp
load('tempFileForAnalysis.mat');

cd(pathBIDS);
cd derivatives
pathDeriv = pwd;

cd(pathDeriv);
cd('rawdata');
pathRaw = pwd;

cd(pathDeriv);
mkdir('behavior');cd('behavior');
pathBehav = pwd;

outlier_idx = 16;

%% load data
cd(pathBIDS);
subdir = dir('sub-*');
subdir = subdir([subdir.isdir]);

cd(pathCurrent);

session_types = {'rotation+90','rotation-90','mirror'};
trial_types = {'rightward', 'upward', 'leftward', 'downward'}; % 0, 90, 180, 270 degree (in polar coordinate)
   
performance_eachsub = zeros(length(subdir),2,15,17); % 4dim: subject * day * session * trial
session_typeidx_eachsub = zeros(length(subdir),2,15); % 3dim: subject * day * session 
directionidx_eachsub = zeros(length(subdir),2,15,17); % 4dim: subject * day * session * trial
for nsub = 1:length(subdir)
    for nday = 1:2
        cd([subdir(nsub).folder filesep subdir(nsub).name]);
        if nday == 1
            cd('ses-01pre'); cd('beh');
        else
            cd('ses-02fmri'); cd('func');
        end
        eventfile = dir('sub*events.tsv');
        eventtable = readtable(eventfile.name,'FileType','text','TreatAsMissing','n/a');
        duration = eventtable.duration(strcmp(eventtable.trial_type,'erasing'));
        numerased_dot = eventtable.number_ErasedDot(strcmp(eventtable.trial_type,'erasing'));
        session_number = eventtable.session_number(strcmp(eventtable.trial_type,'erasing'));
        stimulus_direction = eventtable.stimulus_direction(strcmp(eventtable.trial_type,'erasing'));
        for nses = 1:15
            performance_eachsub(nsub,nday,nses,:) = numerased_dot(session_number==nses) ./ duration(session_number==nses);
            stimulus_direction_ses = stimulus_direction(session_number==nses);
            for ntrial = 1:17
                switch stimulus_direction_ses{ntrial}
                    case trial_types{1}
                        temp_type = 1;
                    case trial_types{2}
                        temp_type = 2;
                    case trial_types{3}
                        temp_type = 3;
                    case trial_types{4}
                        temp_type = 4;
                    otherwise
                        error(['no! >> ' stimulus_direction_ses{ntrial}]);
                end
                directionidx_eachsub(nsub,nday,nses,ntrial) = temp_type;
            end
            session_typeidx_eachsub(nsub,nday,nses) = find(strcmp(session_types,eventtable.session_type{20*(nses-1)+1}));
        end
    end
end

%% trajectory
cd(pathRaw);
cd('ses-01pre');
day1_rawfile = dir('*.mat');
cd ..
cd('ses-02fmri');
day2_rawfile = dir('*.mat');

% outlier_idx = [3,6,12,15,16,17,22];
outlier_idx_temp = [];

see_examplar_mode = false;
if see_examplar_mode; sublist = 9; else; sublist = 1:length(subdir); end %#ok<UNRCH>

is_remove_explored_sub = true;
is_tooExplored_trial = false(length(subdir),2,15,17); % 4dim: subject * day * session * trial
thres = 16 * 7 * 1.5;

cd(pathCurrent);
figure;
for nsub = sublist
%     figure;
    if ~any(nsub == outlier_idx_temp)
        for nday = 1:2
            if nday == 1
                load([day1_rawfile(nsub).folder filesep day1_rawfile(nsub).name]);
                midX = 500;
                midY = 375;
                ratio = 1;
            else
                load([day2_rawfile(nsub).folder filesep day2_rawfile(nsub).name]);
                midX = 400;
                midY = 300;
                ratio = 1;
            end
       
            for ii = 1:3
                if nday == 1
                    subplot(2,3,ii); 
                else
                    subplot(2,3,ii+3); 
                end
                title(session_types{ii});
                xlim([-300,300]); ylim([-300,300]);
                hold on;
                for nses = 1:15
                    if session_typeidx_eachsub(nsub,nday,nses) == ii
                        for ntrial = 1:15
                            points_temp = thePointsAll{nses,ntrial};
                            
                            if is_remove_explored_sub
                                dist_list = sqrt(mean((points_temp - [midX,midY]).^2,2));
                                if any(dist_list > thres)
                                    is_tooExplored_trial(nsub,nday,nses,ntrial) = true;
                                    continue
                                end
                            end
                            
                            switch directionidx_eachsub(nsub,nday,nses,ntrial)
                                case 1
                                    color_char = 'r';
                                case 2
                                    color_char = 'g';
                                case 3
                                    color_char = 'b';
                                case 4
                                    color_char = 'k';
                            end
                            plot(ratio*(points_temp(:,1)-midX),ratio*(midY-points_temp(:,2)),color_char);
                        end
                    end
                end
            end
        end
    end
end

disp(['Total ' num2str(sum(is_tooExplored_trial,'all')) ' trials are excluded, which is ' num2str(100*sum(is_tooExplored_trial,'all')/numel(is_tooExplored_trial),'%.02f') '% of ' num2str(numel(is_tooExplored_trial)) ' trials.']);
num_rot_pos_excluded = sum(is_tooExplored_trial(repmat(session_typeidx_eachsub==1,[1,1,1,17])));
num_rot_neg_excluded = sum(is_tooExplored_trial(repmat(session_typeidx_eachsub==2,[1,1,1,17])));
num_mirror_excluded = sum(is_tooExplored_trial(repmat(session_typeidx_eachsub==3,[1,1,1,17])));
disp(['Number of excluded trial >> rot+90: ', num2str(num_rot_pos_excluded), ', rot-90: ', num2str(num_rot_neg_excluded), ', mirror: ', num2str(num_mirror_excluded)]);
%% performance difference
performance_eachsub_temp = performance_eachsub;
performance_eachsub_temp(is_tooExplored_trial) = nan;
mean_perf_eachsub = zeros(length(subdir),3,2); % 3dim: subject * session_type * day 
std_perf_eachsub = zeros(length(subdir),3,2); % 3dim: subject * session_type * day 
for ntype = 1:3
    for nsub = 1:length(subdir)
        for nday = 1:2
            mean_perf_eachsub(nsub,ntype,nday) = mean(performance_eachsub_temp(nsub,nday,squeeze(session_typeidx_eachsub(nsub,nday,:)==ntype),:),'all',"omitnan");
            std_perf_eachsub(nsub,ntype,nday) = std(performance_eachsub_temp(nsub,nday,squeeze(session_typeidx_eachsub(nsub,nday,:)==ntype),:),0,'all',"omitnan");
        end
    end
end
temp = mean_perf_eachsub;
temp(outlier_idx,:,:) = [];

figure; 
b = bar(squeeze(mean(temp,1)));
hold on
% Calculate the number of groups and number of bars in each group
[~,ngroups,nbars] = size(temp);
% Get the x coordinate of the bars
x = nan(nbars, ngroups);
for ii = 1:nbars
    x(ii,:) = b(ii).XEndPoints;
end
% Plot the errorbars
errorbar(x',squeeze(mean(temp,1)),1.96*squeeze(std(temp,0,1))/sqrt(22),'k','linestyle','none');
hold off;

%% save data
cd(pathBehav); 
save beh_results performance_eachsub session_typeidx_eachsub directionidx_eachsub is_tooExplored_trial
cd(pathCurrent);