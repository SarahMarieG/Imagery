function [hp_segments] = hp_rs_segment(hpData,time_insecs_resampled,condition,triggerNames,triggerTimes,newSampleRate,bslLength,trialLength)
%This function segments hp data based on trigger time stamps from .dat file
%Inputs: hpData = 1D vector of heart rate data, 
%triggerTimes = 1D vector of time stamps indicating when onsets of stimulus 
%presentation or fMRI pulses
%triggerNames = 1D vector of time stamps indicating when onsets of stimulus 
%presentation or fMRI pulses
%sampleRate = integer indicating sampling rate in Hz, 
%bslLength = amount of pre-stimulus onset time to include in segment 
%(in seconds), 
%trialLength = amount of post-stimulus onset time to include in segment 
%(in seconds)
    
    id = 'MATLAB:colon:operandsNotRealScalar';
    warning('off',id)
    
    bslLength_samplePts = bslLength*newSampleRate;
    trialLength_samplePts = trialLength*newSampleRate;
    
    if length(condition) == 1
        cond_trigs = (triggerNames == condition);
    elseif length(condition) == 2
        cond_trigs = (triggerNames == condition(1) | triggerNames == condition(2));
    end

    cond_samplePts = triggerTimes(cond_trigs);
    cond_secs = cond_samplePts./newSampleRate;
    
    hp_segments = NaN([sum(cond_trigs),5501]);
    for trig = 1:length(cond_samplePts)
        triggers_secs = cond_secs(trig);
        trigger_diffs = abs(triggers_secs - time_insecs_resampled);
        trigger_rs = find(trigger_diffs == min(trigger_diffs)); 
        if time_insecs_resampled(trigger_rs) < 3 % minimum start point at 3 seconds
            trigger_rs = trigger_rs + 1;
        end
        hp_segments(trig,:) = hpData(trigger_rs-bslLength_samplePts:trigger_rs+trialLength_samplePts);
    end
    
    warning('on',id)

end