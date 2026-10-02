%% Single trials for parametric modulation (output: ...WaPower_singtrls.mat)
% only difference from below is that we didn't avg over trials before
% wavelet like we do in preprocessing script
% Wavelet PNU groups
cd /Volumes/ELEMENTS/imagery
baseDir = '/Volumes/ELEMENTS/imagery/';
parFolders = dir(fullfile(baseDir, 'par_*/eeg'));
groupNames = {'Neutral_Merged', 'Pleasant_Merged', 'Unpleasant_Merged'};

for p = 1:length(parFolders)
    currentParDir = fullfile(parFolders(p).folder, parFolders(p).name);
    
    for g = 1:length(groupNames)
        matfile = fullfile(currentParDir, [parFolders(p).name, '_', groupNames{g}, '.mat']);
        
        if exist(matfile, 'file')
            fprintf('Analyzing %s: %s\n', parFolders(p).name, groupNames{g});
            load(matfile); % Loads 'temp3d'

            % Wavelet Analysis on single trials
            [WaPower4d] = wavelet_app_mat_singtrials(temp3d, 500, 180, 260, 20);

            fileName = strcat(parFolders(p).name, '_', groupNames{g}, '_WaPower_singtrls.mat');
            fullPath = fullfile(currentParDir, fileName);
            % save(fullPath, 'WaPower4d');

            % Average over frequencies
            % 1. Select sensors [9, 10, 20]
            % 2. Average across dimensions 1 (Sensors), 2 (Time), and 3 (Frequency)
            % 3. 'squeeze' to remove the single dimensions, leaving only the 18 trials
            %WaPower_singtrls = squeeze(mean(WaPower4d([9 10 20], 5500:6500, :, :), [1 2 3]))';
            % save(fullPath, 'WaPower_singtrls');

        end
    end
end



%% identify/interpolate/plot single trial outliers for parametric modulation
clear
cd /Volumes/ELEMENTS/imagery/participants/

filePathsNTR = getfilesinfolders_sarah(pwd, 'par_*/eeg*', '_Neutral_Merged_WaPower_singtrls.mat');
filePathsPLE = getfilesinfolders_sarah(pwd, 'par_*/eeg*', '_Pleasant_Merged_WaPower_singtrls.mat');
filePathsUPL = getfilesinfolders_sarah(pwd, 'par_*/eeg*', 'Unpleasant_Merged_WaPower_singtrls.mat');

time_cols_dir = '/Volumes/ELEMENTS/imagery/fmri/time_cols';

files = dir(time_cols_dir);
% Filter for items that are directories AND are not '.' or '..'
dirFlags = [files.isdir] & ~strcmp({files.name}, '.') & ~strcmp({files.name}, '..');
% Extract just the names into a string array
folderNames = string({files(dirFlags).name})';

%preallocate NaNs for pars with shorter runs (par 4, 5)
num_subs = numel(folderNames);
max_trials = 18;
group_PLE = NaN(max_trials, num_subs);
group_NTR = NaN(max_trials, num_subs);
group_UPL = NaN(max_trials, num_subs);

plesumall = [];
ntrsumall = [];
uplsumall = [];

for sub = 1:num_subs

    % sub_folder = fullfile(time_cols_dir, sprintf('par_%02d', sub));
    sub_folder = fullfile(folderNames(sub));

    PLE = load(filePathsPLE(sub,:));
    NTR = load(filePathsNTR(sub,:));
    UPL = load(filePathsUPL(sub,:));
    % hist(PLE.WaPower_singtrls)

    [PLE_corr, TF_ple] = filloutliers(PLE.WaPower_singtrls, "linear", "median"); 
    [NTR_corr, TF_ntr] = filloutliers(NTR.WaPower_singtrls, "linear", "median"); 
    [UPL_corr, TF_upl] = filloutliers(UPL.WaPower_singtrls, "linear", "median"); 
    % [PLE_corr, TF_ple] = filloutliers(PLE.WaPower_singtrls, "linear", "quartiles", "ThresholdFactor", 1.5);
    % [NTR_corr, TF_ntr] = filloutliers(NTR.WaPower_singtrls, "linear", "quartiles", "ThresholdFactor", 1.5);
    % [UPL_corr, TF_upl] = filloutliers(UPL.WaPower_singtrls, "linear", "quartiles", "ThresholdFactor", 1.5);
   
    %note: afni amplitude modulation does this automatically so no need to
    %do this, but also doesn't hurt
    PLE_centered = PLE_corr - mean(PLE_corr);
    NTR_centered = NTR_corr - mean(NTR_corr);
    UPL_centered = UPL_corr - mean(UPL_corr);

    plesum = sum(TF_ple, 1);
    plesumall = [plesumall plesum];
    
    ntrsum = sum(TF_ntr, 1);
    ntrffsumall = [ntrsumall ntrsum];

    uplsum = sum(TF_upl, 1);
    uplsumall = [uplsumall uplsum];
    

     n_trials = numel(PLE_corr); 
     n_trialsN = numel(NTR_corr);
     n_trialsU = numel(UPL_corr);
    % % Save individual participant files folder;
    % saves by index (make sure only used participants are in path)
    % writematrix(PLE_centered, fullfile(sub_folder, 'alpha4parmod_pleasant_med.txt'));
    % writematrix(NTR_centered, fullfile(sub_folder, 'alpha4parmod_neutral_med.txt'));
    % writematrix(UPL_centered, fullfile(sub_folder, 'alpha4parmod_unpleasant_med.txt'));


    group_PLE(1:n_trials, sub) = PLE_corr(:);
    group_NTR(1:n_trialsN, sub) = NTR_corr(:);
    group_UPL(1:n_trialsU, sub) = UPL_corr(:);
   

    figure;
    % Plot PLE
    subplot(3,1,1);
    plot(PLE.WaPower_singtrls, 'k-o', 'MarkerFaceColor', 'r'); hold on;
    plot(PLE_corr, 'bx', 'MarkerSize', 10, 'LineWidth', 2);
    title(['Sub ' num2str(sub) ' PLE']);

    % Plot NTR
    subplot(3,1,2);
    plot(NTR.WaPower_singtrls, 'k-o', 'MarkerFaceColor', 'r'); hold on;
    plot(NTR_corr, 'bx', 'MarkerSize', 10, 'LineWidth', 2);
    title('NTR');

    % Plot UPL
    subplot(3,1,3);
    plot(UPL.WaPower_singtrls, 'k-o', 'MarkerFaceColor', 'r'); hold on;
    plot(UPL_corr, 'bx', 'MarkerSize', 10, 'LineWidth', 2);
    title('UPL');
    xlabel('Trial Number');

end

% cd /Volumes/ELEMENTS/imagery/
% writematrix(group_PLE, 'group_alpha4parmod_pleasant_med.xlsx');
% writematrix(group_NTR, 'group_alpha4parmod_neutral_med.xlsx');
% writematrix(group_UPL, 'group_alpha4parmod_unpleasant_med.xlsx');

% added trials and participant labels; use for R code avg_alpha_3conds.


%% F Contrasts on the corrected Alpha for parametric modulation

alpha4param_corr = cat(3, group_PLE, group_NTR, group_UPL);
alpha4param_corr_mean = mean(alpha4param_corr, 1, "omitnan");

%MAKE SURE WEIGHTS ARE IN THE CORRECT ORDER: PNU
[Fcontmat,rcontmat,MScont,MScs, dfcs]=contrast_rep(alpha4param_corr_mean,[1 -2 1]); 
pvalue = 1-fcdf(Fcontmat, 1, dfcs)
%occipital sensors: F = 7.55, p = 0.009

figure
plot(squeeze(alpha4param_corr_mean)', 'LineWidth', 3)

