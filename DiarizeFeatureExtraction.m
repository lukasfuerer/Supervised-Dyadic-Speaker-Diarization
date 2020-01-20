function feat = DiarizeFeatureExtraction(audio, fs, win, step, DyadID, SessionID, vadP1, vadP2, sdWin, intermediatedir)

feat = stFeatureExtraction(audio, fs, win, step);
feat = feat';
feat = array2table(feat);
variablenames = {'ZCR', 'Energy', 'Energy_Entropy', 'Spectral_Centroid_1', 'Spectral_Centroid_2', 'Spectral_Entropy', 'Spectral_Flux', 'Spectral_Rolloff', ...
    'MFCC1', 'MFCC2','MFCC3','MFCC4','MFCC5','MFCC6','MFCC7','MFCC8','MFCC9','MFCC10','MFCC11','MFCC12','MFCC13', 'Harmonic_Ratio', 'F0', ...
    'Chroma_Vector_1', 'Chroma_Vector_2','Chroma_Vector_3','Chroma_Vector_4','Chroma_Vector_5','Chroma_Vector_6','Chroma_Vector_7','Chroma_Vector_8',...
    'Chroma_Vector_9','Chroma_Vector_10','Chroma_Vector_11','Chroma_Vector_12'};
feat.Properties.VariableNames = variablenames;
time = 0:win:(height(feat)-1)*win;
feat.time = time';

% VAD
audiowrite( [intermediatedir DyadID '_' SessionID '.wav'],audio, fs);
vad = apply_vad(intermediatedir, vadP1, vadP2);
delete([intermediatedir '*']);
vadtime = 0:0.01:(0.01*(length(vad)-1));
vadtime = vadtime';
vad = double(vad);

vad = table(vadtime, vad);
vad.Properties.VariableNames = {'time', 'vad'};

timemax = max(vad.time);
vadnew = [];
timenew = [];
for s = 0:0.1:timemax
    timenew = [timenew; s];
    vadcheck = vad.vad(vad.time >= s & vad.time < (s+0.1));
    
    if isempty(vadcheck)
        vadnew = [vadnew; 0];
    elseif range(vadcheck) == 0 && vadcheck(1) == 1
        vadnew = [vadnew; 1];
    elseif range(vadcheck) == 0 && vadcheck(1) == 0
        vadnew = [vadnew; 0];
    elseif range(vadcheck) == 1
        vadnew = [vadnew; 1];
    end
end

vad = table(timenew, vadnew);
vad.Properties.VariableNames = {'time', 'vad'};
feat.time = round(feat.time,1);
vad.time = round(vad.time, 1);
feat = outerjoin(feat, vad, 'LeftKeys', 36, 'RightKeys', 1, 'MergeKeys', true);

% Silence Detection
silence = DiarizeSilenceDetection(audio, fs, sdWin, 0.1);
silence.time = round(silence.time, 1);
feat = outerjoin(feat, silence, 'LeftKeys', 36, 'RightKeys', 1, 'MergeKeys', true);

% HF 500
hf500 = DiarizeHF500(audio, fs);
hf500.time = round(hf500.time, 1);
feat = outerjoin(feat, hf500, 'LeftKeys', 36, 'RightKeys', 1, 'MergeKeys', true);

% Minus 1 and Minus 2
    newvarnames = feat.Properties.VariableNames;
    for j = 1:1:length(newvarnames)
        newvarnames{j} = [newvarnames{j} '_Minus1'];
    end
    
    Minus1 = feat(1:end-1, :);
    nans =  array2table(nan(1, width(Minus1)));
    nans.Properties.VariableNames = feat.Properties.VariableNames;
    Minus1 = [nans; Minus1];
    Minus1.Properties.VariableNames = newvarnames;
    
    newvarnames = feat.Properties.VariableNames;
    for k = 1:1:length(newvarnames)
        newvarnames{k} = [newvarnames{k} '_Minus2'];
    end
    
    Minus2 = feat(1:end-2, :);
    nans =  array2table(nan(2, width(Minus2)));
    nans.Properties.VariableNames = feat.Properties.VariableNames;
    Minus2 = [nans; Minus2];
    Minus2.Properties.VariableNames = newvarnames;
    
    feat = [feat, Minus1, Minus2];
    feat.time_Minus1 = []; feat.time_Minus2 = [];
end



