function Mdl = DiarizeLearning(DyadID, learndir, featuresdir)

% Get all Filenames of Dyad in the Learning Set Directory
list = dir(learndir);
filenames = {list.name}; 
filenames(cellfun(@isempty,regexp(filenames, DyadID, 'match'))) = [];

% Create containers to fill in the relevant features
featurespatient = readtable([featuresdir strrep(filenames{1}, '.txt', '') '_features.txt']);
featurespatient(2:end, :) = []; featurespatient(:,:) = array2table(nan(1, width(featurespatient)));
featurestherapist = readtable([featuresdir strrep(filenames{1}, '.txt', '') '_features.txt']);
featurestherapist(2:end, :) = []; featurestherapist(:,:) = array2table(nan(1, width(featurestherapist)));

% Create Table
for i = 1:1:length(filenames)
    currentFile = readtable([learndir filenames{i}]);
    currentfeatures = readtable([featuresdir strrep(filenames{i}, '.txt', '') '_features.txt']);
    for j = 1:1:height(currentFile)
        if table2array(currentFile(j, 3)) == 1
            newpatient = currentfeatures(currentfeatures.time >= table2array(currentFile(j, 1)) & currentfeatures.time <= table2array(currentFile(j, 2)), :);
            featurespatient = [featurespatient; newpatient];
        elseif table2array(currentFile(j, 3)) == 2
            newtherapist = currentfeatures(currentfeatures.time >= table2array(currentFile(j, 1)) & currentfeatures.time <= table2array(currentFile(j, 2)), :);
            featurestherapist = [featurestherapist; newtherapist];
        end
    end
end

featurespatient = unique(featurespatient);
featurestherapist = unique(featurestherapist);
featurespatient(any(ismissing(featurespatient),2), :) = [];
featurestherapist(any(ismissing(featurestherapist),2), :) = [];

featurespatient.Role = repelem(1, height(featurespatient))';
featurestherapist.Role = repelem(2, height(featurestherapist))';

Features = [featurespatient;featurestherapist];
Features(Features.silence==1, :) = [];
Features(Features.silence_Minus1 == 1, :) = [];
Features(Features.silence_Minus2 == 1, :) = [];
Features.time = [];
Features.silence = []; Features.silence_Minus1 = []; Features.silence_Minus2 = [];
Features.vad = []; Features.vad_Minus1 = []; Features.vad_Minus2 = [];
% Tree Bagger
Mdl = TreeBagger(500,Features,'Role', 'OOBPrediction', 'on', 'OOBPredictorImportance', 'on', 'Method', 'classification');

end