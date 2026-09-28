% EEG_OPTIONS - eeglab option script 
%
% Note: DO NOT EDIT, instead use POP_EDITOPTIONS or the menu
%       /File/Maximize memory in EEGLAB gui

% STUDY and file options (set the first checkbox if you intend to work with studies)
option_storedisk = 0 ; % If set, keep at most one dataset in memory. This allows processing hundreds of datasets within studies.
option_savetwofiles = 0 ; % If set, save not one but two files for each dataset (header and data). No longer set by default as of 2021.
option_parallel = 0 ; % If set, use the parallel toolbox when processing multiple datasets (beta)
% ICA options 
option_computeica = 1 ; % If set, precompute ICA activations. This requires more RAM but allows faster plotting of component activations.
% Folder options
option_rememberfolder = 1 ; % If set, when browsing to open a new dataset assume the folder/directory of the previous dataset.
% EEGLAB connectivity and support
option_showadvanced = 1 ; % If set, show advanced options (close and reopen this GUI to effect changes)
option_boundary99 = 0 ; % If set, use type "-99" for boundary events when processing numerical event types (ERPLAB compatibility)
option_allmenus = 0 ; % If set, show all menu items from previous EEGLAB versions. You must restart EEGLAB for this to take effect.
option_checkversion = 1 ; % If set, check for new version of EEGLAB and EEGLAB extensions at startup.
option_cachesize = 500 ; % Size of cache in Mbytes for EEGLAB STUDY cache in RAM.
