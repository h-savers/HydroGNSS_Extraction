%% =========================================================
%  SATELLITE MERGE + VALIDATION REPORT (H1 + H2)
%  FULL UNION MERGE + TXT LOG OUTPUT
%% =========================================================

clear; clc;

basePath=uigetdir('./','Specify the folder with extracted files to merge (can be changed)') ;
OutputFolder = uigetdir('./', 'Specify output folder') ;

[file1,basePath] = uigetfile('./*.mat', 'First file to merge', basePath) ;
file1 = fullfile(basePath, file1);
[file2,basePath] = uigetfile('./*.mat', 'Second file to merge', basePath) ;
file2 = fullfile(basePath, file2);
prompt = {'Output file prefix'};
dlgtitle = 'Output'; definput = {'Merged file.mat'};
answer = inputdlg(prompt,dlgtitle)
NameOutFile=answer{1} ; 
NameOutFile= [char(NameOutFile) '_' char(datetime('now','Format','yy-MM-dd_HH-mm'),'yy-MM-dd_HH-mm') '.mat'] ; 
startIndex= regexp(NameOutFile,'.mat') ; 
reportFile = fullfile(OutputFolder, [extractBefore(NameOutFile,startIndex) '_report.txt']) ;

% OutputFolder='D:\home on Dell NP (gordiani)\HydroGNSS_PhCDE\HydroGNSSCalVal\HydroGNSS_Extract\output' ;
% basePath = 'W:\HydroGNSS_OrbitData\ExtractedData';
% NameOutFile='pippo.mat' ; 
% 
% file1 = fullfile(basePath, 'Extract_Hydr-1_day05-18May_Land_26-05-21_06-07.mat');
% file2 = fullfile(basePath, 'Extract_Hydr-2_day01-19May_Land_26-05-21_00-08.mat');
% reportFile = fullfile(OutputFolder, 'merge_validation_report.txt') ;

%% -----------------------------
% LOAD DATA
%% -----------------------------
S1 = load(file1);
S2 = load(file2);

vars1 = fieldnames(S1);
vars2 = fieldnames(S2);
allVars = unique([vars1; vars2]);

Merged = struct();

%% -----------------------------
% OPEN REPORT FILE
%% -----------------------------
fid = fopen(reportFile, 'w');

fprintf(fid, "SATELLITE MERGE VALIDATION REPORT\n");
fprintf(fid, "=================================\n\n");

fprintf(fid, "H1 file: %s\n", file1);
fprintf(fid, "H2 file: %s\n\n", file2);

fprintf(fid, "H1 variables: %d\n", length(vars1));
fprintf(fid, "H2 variables: %d\n", length(vars2));
fprintf(fid, "Total merged variables: %d\n\n", length(allVars));

fprintf('Merging variables (UNION mode)...\n');

%% -----------------------------
% MERGE LOOP
%% -----------------------------
for i = 1:length(allVars)

    v = allVars{i};

    has1 = isfield(S1, v);
    has2 = isfield(S2, v);

    if has1 && ~has2
        Merged.(v) = S1.(v);
        continue;
    end

    if has2 && ~has1
        Merged.(v) = S2.(v);
        continue;
    end

    A = S1.(v);
    B = S2.(v);

    % -------------------------
    % SPECIAL: SixHourDir
    % -------------------------
    if strcmp(v, 'SixHourDir')
        Merged.(v) = [string(A); string(B)];
        continue;
    end

    % -------------------------
    % SPECIAL: timeUTC
    % -------------------------
    if strcmp(v, 'timeUTC')
        Merged.(v) = [string(A); string(B)];
        continue;
    end

    % -------------------------
    % NUMERIC
    % -------------------------
    if isnumeric(A)

        if ~isequal(size(A,2), size(B,2))
            error(['Shape mismatch: ', v]);
        end

        Merged.(v) = [A; B];
        continue;
    end

    % -------------------------
    % CELL
    % -------------------------
    if iscell(A)
        Merged.(v) = [A; B];
        continue;
    end

    % -------------------------
    % STRING / CHAR
    % -------------------------
    if isstring(A) || ischar(A)
        Merged.(v) = [string(A); string(B)];
        continue;
    end

    % -------------------------
    % FALLBACK
    % -------------------------
    Merged.(v) = A;
end

%% -----------------------------
% REQUIRED VARIABLE CHECK
%% -----------------------------
requiredVars = {'SixHourDir', 'timeUTC', 'Landtypesub'};

fprintf(fid, "\nREQUIRED VARIABLE CHECK:\n");

for i = 1:length(requiredVars)

    v = requiredVars{i};

    if isfield(Merged, v)
        fprintf(fid, "✔ %s\n", v);
        fprintf('✔ %s\n', v);
    else
        fprintf(fid, "❌ %s MISSING\n", v);
        fprintf('❌ %s MISSING\n', v);
    end
end

%% -----------------------------
% SIZE VALIDATION SAMPLE
%% -----------------------------
commonVars = intersect(vars1, vars2);

fprintf(fid, "\nSIZE CHECK (SAMPLE VARIABLES)\n");

for i = 1:min(5, length(commonVars))

    v = commonVars{i};

    if isnumeric(S1.(v))

        h1_size = size(S1.(v),1);
        h2_size = size(S2.(v),1);
        merged_size = size(Merged.(v),1);

        fprintf(fid, "\nVariable: %s\n", v);
        fprintf(fid, "H1: %d\n", h1_size);
        fprintf(fid, "H2: %d\n", h2_size);
        fprintf(fid, "Merged: %d\n", merged_size);
        fprintf(fid, "Expected: %d\n", h1_size + h2_size);

        if merged_size == h1_size + h2_size
            fprintf(fid, "✔ OK\n");
        else
            fprintf(fid, "❌ MISMATCH\n");
        end
    end
end

%% -----------------------------
% SAVE OUTPUT
%% -----------------------------
save(fullfile(OutputFolder, NameOutFile), '-struct', 'Merged', '-v7.3');

fprintf(fid, "\nDONE ✔ FULL MERGE COMPLETE\n");

fclose(fid);

fprintf('\nDONE ✔ Output saved + report generated:\n%s\n', reportFile);