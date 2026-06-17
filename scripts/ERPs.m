%% 1. Define Paths and Find Participant Folders
clear
base_path = '/Volumes/ELEMENTS/imagery/participants/';

% 1. Use wildcard to find all participant folders
participant_folders = dir(fullfile(base_path, 'par_*'));
num_participants = length(participant_folders);
fprintf('Found %d participant folders.\n', num_participants);

num_channels = 31; 
num_sp = 251;
% Pre-allocate a 3D matrix: [Channels x Timepoints x Participants]
GM_ERP_Neu = zeros(num_channels, num_sp, num_participants);
GM_ERP_Pl = zeros(num_channels, num_sp, num_participants);
GM_ERP_Un = zeros(num_channels, num_sp, num_participants);

for p = 1:num_participants
    current_par = participant_folders(p).name;
    string_path = fullfile(base_path, current_par, 'eeg');
    
    % 2. Use native MATLAB 'dir' to find each specific file directly
    file_neu = dir(fullfile(string_path, '*Neutral_Merged.mat'));
    file_pl  = dir(fullfile(string_path, '*Pleasant_Merged.mat'));
    file_un  = dir(fullfile(string_path, '*Unpleasant_Merged.mat'));
    
  if isempty(file_neu) || isempty(file_pl) || isempty(file_un)
        warning('Skipping %s: One or more condition files are missing in %s', current_par, string_path);
        continue;
    end

    % 4. Construct the absolute file paths
    path_neu = fullfile(string_path, file_neu(1).name);
    path_pl  = fullfile(string_path, file_pl(1).name);
    path_un  = fullfile(string_path, file_un(1).name);
    
    fprintf('Loading files for %s...\n', current_par);
    
    data_neu = load(path_neu);
    data_pl  = load(path_pl);
    data_un  = load(path_un);

    Neu = data_neu.temp3d;
    Pl  = data_pl.temp3d;
    Un  = data_un.temp3d;

    Neu_ERP = mean(Neu(:, 501:751,:), 3);
    Pl_ERP = mean(Pl(:, 501:751,:), 3);
    Un_ERP = mean(Un(:, 501:751,:), 3);

    GM_ERP_Neu(:, :, p) = Neu_ERP;
    GM_ERP_Pl(:, :, p) = Pl_ERP;
    GM_ERP_Un(:, :, p) = Un_ERP;
end

%% 4. Calculate the Average Across All Participants
% Mean over the 3rd dimension (Participants)
ERP_Pl = mean(GM_ERP_Pl, 3);
ERP_Neu = mean(GM_ERP_Neu, 3);
ERP_Un = mean(GM_ERP_Un, 3);

%% Plot
plot(ERP_Pl(20, :));
hold on
plot(ERP_Neu(20, :));
plot(ERP_Un(20, :));