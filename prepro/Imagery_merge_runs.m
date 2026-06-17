%Combine EEG Condition trials from A and B runs (Imagery study)
clc 
clear all
addpath('/Volumes/ELEMENTS/imagery/scripts/')

cd '/Volumes/ELEMENTS/Imagery/eeg'

rootDir = '/Volumes/ELEMENTS/imagery/eeg';
parDirs = dir(fullfile(rootDir,'par_*'));

merged_runs = cell(0,2);   % col1 = participant id, col2 = merged 9x3 dataOut

for i = 1:numel(parDirs)
    % if ~parDirs(i).isdir, continue; end
    pdir = fullfile(rootDir, parDirs(i).name);

    % 1) find files (ignore mac invisible ._ files)
    F = dir(fullfile(pdir,'*ALLCONDITIONS*.mat'));
    F = F(~startsWith({F.name}, '._'));
    if isempty(F), continue; end

    % 2) load all parts into a cell array of dataOut
    runs = cell(1,numel(F));
    for k = 1:numel(F)
        S = load(fullfile(F(k).folder, F(k).name));
        if isfield(S,'dataOut'), runs{k} = S.dataOut;
        elseif isfield(S,'allDataOut'), runs{k} = S.allDataOut;
        else, runs{k} = []; end
    end
    runs = runs(~cellfun(@isempty,runs));
    if isempty(runs), continue; end

    % 3) merge by condition label, stack trials
    merged = mergeByCondition(runs);

pid = parDirs(i).name;   % e.g., 'par_01'

% allDataOut is now: [participantID , mergedDataOut]
merged_runs{end+1, 1} = pid;
merged_runs{end,   2} = merged;

    fprintf('Merged %s (%d file(s))\n', parDirs(i).name, numel(runs));
end

fprintf('Loaded %d participants\n', size(merged_runs, 1));

save('Merged_eeg_runs.mat', "merged_runs")