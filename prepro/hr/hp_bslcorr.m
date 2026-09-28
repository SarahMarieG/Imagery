function [hp_corrected] = hp_bslcorr(hp,qrs,stim_on,fs)
    

    hp_bsl = NaN([size(qrs)]);
    hp_corrected = NaN([size(hp)]);
    for tr = 1:length(qrs)
        
        if isnan(qrs{tr,1})
            continue
        end
        qrs_trial = qrs{tr,1};
        prestim_qrs = qrs_trial < repmat(stim_on,size(qrs_trial));
        prestim_qrs_sec = qrs_trial(prestim_qrs)./fs;

        if length(prestim_qrs_sec > 2)
            bsl_beats = prestim_qrs_sec(end-1:end);
        else
            bsl_beats = prestim_qrs_sec(end-1:end);
        end
        
        IBI_bsl = mean(diff(bsl_beats));
        hp_bsl(tr) = IBI_bsl;
        
        hp_corrected(tr,:) = squeeze(hp(tr,:)) - hp_bsl(tr);
    end

end