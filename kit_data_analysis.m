% =========================================================================
% KIT AUTOMOTIVE OBD-II DATASET - ANALYSIS & VISUALIZATION
% Bachelor's Thesis: Application of Artificial Neural Networks
%                    for Vehicle Technical Condition Analysis
%
% Author  : Niks Isacenko
% Advisor : Docent Henrihs Gorskis
%
% Dataset : Automotive OBD-II Dataset
%           Weber, Marc (2023). Karlsruhe Institute of Technology (KIT)
%           https://radar.kit.edu/radar/en/dataset/bCtGxdTklQlfQcAq
%
%
% How to get the dataset:
%   1. Visit: https://radar.kit.edu/radar/en/dataset/bCtGxdTklQlfQcAq
%   2. Click "Download"
%   3. Extract the ZIP - multiple CSV files
%   4. Place ALL CSV files in a subfolder called: kit_data
%   5. Run this script
% =========================================================================

clc; clear; close all;

cd(fileparts(which('kit_data_analysis')));

fprintf('=============================================================\n');
fprintf('  KIT OBD-II DATASET — REAL VEHICLE DATA ANALYSIS\n');
fprintf('  Validating SAE J1979 Thresholds\n');
fprintf('=============================================================\n\n');

% CSV load

data_folder = 'kit_data';

if ~isfolder(data_folder)
    error(['Folder "%s" not found.\n' ...
           'Please create a subfolder called "kit_data" and place\n' ...
           'the KIT dataset CSV files inside it.\n' ...
           'Download from: https://radar.kit.edu/radar/en/dataset/bCtGxdTklQlfQcAq'], ...
           data_folder);
end

csv_files = dir(fullfile(data_folder, '*.csv'));

if isempty(csv_files)
    error('No CSV files found in "%s". Please add KIT dataset files.', data_folder);
end

fprintf('[1/5] Loading %d CSV file(s) from "%s"...\n', length(csv_files), data_folder);

% column names
col_map = struct();
col_map.coolant_temp  = 'Engine coolant temperature';
col_map.manifold_pres = 'Intake manifold absolute pressure';
col_map.rpm           = 'Engine RPM';
col_map.speed         = 'Vehicle speed sensor';
col_map.intake_air    = 'Intake air temperature';
col_map.maf           = 'Air flow rate from mass flow sensor';
col_map.throttle      = 'Absolute throttle position';
col_map.ambient_temp  = 'Ambient air temperature';

all_data = [];
file_labels = {};

for fi = 1:length(csv_files)
    fpath = fullfile(data_folder, csv_files(fi).name);
    try
        T = readtable(fpath, 'VariableNamingRule', 'preserve');

        row = struct();
        fields = fieldnames(col_map);
        found = true;

        for k = 1:length(fields)
            col_name = col_map.(fields{k});
            % Find column 
            matches = contains(T.Properties.VariableNames, ...
                               col_name, 'IgnoreCase', true);
            if any(matches)
                col_idx = find(matches, 1);
                row.(fields{k}) = T{:, col_idx};
            else
                found = false;
                break;
            end
        end

        if found
            % matrix (rows = time steps, cols = parameters)
            n = length(row.coolant_temp);
            block = [row.coolant_temp, row.rpm, row.speed, ...
                     row.intake_air,   row.maf, row.throttle, ...
                     row.manifold_pres, row.ambient_temp];
            all_data = [all_data; block];
            file_labels{end+1} = csv_files(fi).name;
            fprintf('    Loaded: %s (%d rows)\n', csv_files(fi).name, n);
        else
            fprintf('    Skipped (columns not matched): %s\n', csv_files(fi).name);
        end
    catch e
        fprintf('    Error reading %s: %s\n', csv_files(fi).name, e.message);
    end
end

if isempty(all_data)
    error('Could not load any data. Check that CSV column names match KIT dataset format.');
end

fprintf('    Total records loaded: %d\n\n', size(all_data, 1));

IDX_COOLANT  = 1;
IDX_RPM      = 2;
IDX_SPEED    = 3;
IDX_INTAKE   = 4;
IDX_MAF      = 5;
IDX_THROTTLE = 6;
IDX_MAP      = 7;
IDX_AMBIENT  = 8;

col_names = {'Coolant Temp (°C)', 'Engine RPM', 'Vehicle Speed (km/h)', ...
             'Intake Air Temp (°C)', 'MAF (g/s)', 'Throttle Position (%)', ...
             'Manifold Pressure (kPa)', 'Ambient Air Temp (°C)'};

% Remove NaN rows
all_data = all_data(~any(isnan(all_data), 2), :);
fprintf('    After NaN removal: %d records\n\n', size(all_data, 1));

% STATISTICAL SUMMARY

fprintf('[2/5] Computing statistics...\n');
fprintf('\n  %-28s %8s %8s %8s %8s %8s\n', ...
        'Parameter', 'Min', 'Mean', 'Median', 'Max', 'Std');
fprintf('  %s\n', repmat('-', 1, 72));

stats = struct();
for c = 1:length(col_names)
    col_data = all_data(:, c);
    stats(c).min    = min(col_data);
    stats(c).mean   = mean(col_data);
    stats(c).median = median(col_data);
    stats(c).max    = max(col_data);
    stats(c).std    = std(col_data);

    fprintf('  %-28s %8.2f %8.2f %8.2f %8.2f %8.2f\n', ...
            col_names{c}, stats(c).min, stats(c).mean, ...
            stats(c).median, stats(c).max, stats(c).std);
end
fprintf('\n');


% THRESHOLDS AGAINST REAL DATA

fprintf('[3/5] Validating SAE J1979 thresholds against real data...\n\n');

% normal ranges
sae_ranges = struct();
sae_ranges(1).name    = 'Coolant Temp';   sae_ranges(1).normal = [80, 105]; sae_ranges(1).col = IDX_COOLANT;
sae_ranges(2).name    = 'Engine RPM';     sae_ranges(2).normal = [600, 3000]; sae_ranges(2).col = IDX_RPM;
sae_ranges(3).name    = 'Vehicle Speed';  sae_ranges(3).normal = [0, 120]; sae_ranges(3).col = IDX_SPEED;
sae_ranges(4).name    = 'Intake Air Temp';sae_ranges(4).normal = [10, 50]; sae_ranges(4).col = IDX_INTAKE;
sae_ranges(5).name    = 'MAF Rate';       sae_ranges(5).normal = [2, 25]; sae_ranges(5).col = IDX_MAF;
sae_ranges(6).name    = 'Throttle Pos';   sae_ranges(6).normal = [10, 80]; sae_ranges(6).col = IDX_THROTTLE;

fprintf('  %-20s %10s %10s %10s %10s\n', ...
        'Parameter', 'SAE Min', 'SAE Max', 'Real Min', 'Real Max');
fprintf('  %s\n', repmat('-', 1, 55));

for i = 1:length(sae_ranges)
    col_data  = all_data(:, sae_ranges(i).col);
    real_min  = prctile(col_data, 5);   % 5th percentile
    real_max  = prctile(col_data, 95);  % 95th percentile

    % if SAE range covers real data?
    coverage = 'OK';
    if real_min < sae_ranges(i).normal(1) * 0.9
        coverage = 'REVIEW LOW';
    end
    if real_max > sae_ranges(i).normal(2) * 1.1
        coverage = 'REVIEW HIGH';
    end

    fprintf('  %-20s %10.1f %10.1f %10.1f %10.1f  %s\n', ...
            sae_ranges(i).name, sae_ranges(i).normal(1), sae_ranges(i).normal(2), ...
            real_min, real_max, coverage);
end
fprintf('\n');

% VISUAL

fprintf('[4/5] Generating visualizations...\n');

% overview
figure('Name', 'Figure 1 - OBD-II Parameter Time Series', ...
       'Position', [50, 50, 1400, 800]);

n_points = min(3000, size(all_data, 1));
t = (1:n_points) / 10;   % assume 10 Hz sampling -> seconds

plot_cols = [IDX_COOLANT, IDX_RPM, IDX_SPEED, IDX_INTAKE, ...
             IDX_MAF, IDX_THROTTLE, IDX_MAP, IDX_AMBIENT];

colors = lines(8);

for pi = 1:8
    subplot(4, 2, pi);
    plot(t, all_data(1:n_points, plot_cols(pi)), ...
         'Color', colors(pi,:), 'LineWidth', 0.8);
    xlabel('Time (s)');
    ylabel(col_names{plot_cols(pi)});
    title(col_names{plot_cols(pi)}, 'FontSize', 9);
    grid on;
    box off;
end

sgtitle('Real Vehicle OBD-II Parameters - KIT Dataset (Normal Driving)', ...
        'FontSize', 13, 'FontWeight', 'bold');

% histograms
figure('Name', 'Figure 2 - Parameter Distributions vs SAE J1979 Thresholds', ...
       'Position', [100, 100, 1400, 700]);

sae_yellow = [105, 3000, 140, 50, 25, 80];
sae_red    = [120, 5500, 180, 80, 45, 98];

for pi = 1:6
    subplot(2, 3, pi);
    col_data = all_data(:, sae_ranges(pi).col);
    histogram(col_data, 50, 'FaceColor', colors(pi,:), ...
              'EdgeColor', 'none', 'FaceAlpha', 0.7);
    hold on;

    yl = ylim;
    % normal range shading
    fill([sae_ranges(pi).normal(1), sae_ranges(pi).normal(2), ...
          sae_ranges(pi).normal(2), sae_ranges(pi).normal(1)], ...
         [0, 0, yl(2), yl(2)], ...
         [0.6, 1.0, 0.6], 'FaceAlpha', 0.15, 'EdgeColor', 'none');

    % Threshold lines
    xline(sae_yellow(pi), '--', 'Color', [0.9, 0.7, 0], ...
          'LineWidth', 1.5, 'Label', 'Yellow');
    xline(sae_red(pi),    '--', 'Color', [0.8, 0, 0], ...
          'LineWidth', 1.5, 'Label', 'Red');

    xlabel(col_names{sae_ranges(pi).col});
    ylabel('Frequency');
    title(sae_ranges(pi).name, 'FontSize', 9);
    grid on; box off;
    hold off;
end

sgtitle('Parameter Distributions vs SAE J1979 Alert Thresholds (green = normal range)', ...
        'FontSize', 12, 'FontWeight', 'bold');

% Correlation matrix
figure('Name', 'Figure 3 - Parameter Correlation Matrix', ...
       'Position', [150, 150, 700, 600]);

corr_data = all_data(:, [IDX_COOLANT, IDX_RPM, IDX_SPEED, ...
                          IDX_INTAKE, IDX_MAF, IDX_THROTTLE]);
short_names = {'Coolant', 'RPM', 'Speed', 'Air Temp', 'MAF', 'Throttle'};

R = corrcoef(corr_data);
imagesc(R);
colormap(redblue_colormap());
colorbar;
clim([-1, 1]);
xticks(1:6); xticklabels(short_names); xtickangle(30);
yticks(1:6); yticklabels(short_names);
title('Parameter Correlation Matrix (Real Vehicle Data)', ...
      'FontSize', 12, 'FontWeight', 'bold');

for i = 1:6
    for j = 1:6
        if abs(R(i,j)) > 0.5
            txt_color = 'white';
        else
            txt_color = 'black';
        end
        text(j, i, sprintf('%.2f', R(i,j)), ...
             'HorizontalAlignment', 'center', ...
             'FontSize', 8, 'Color', txt_color);
    end
end

% engine warm-up scatter
figure('Name', 'Figure 4 - RPM vs Coolant Temperature', ...
       'Position', [200, 200, 800, 500]);

% Color by vehicle speed
speed_norm = (all_data(:, IDX_SPEED) - min(all_data(:, IDX_SPEED))) / ...
             (max(all_data(:, IDX_SPEED)) - min(all_data(:, IDX_SPEED)) + 1e-9);

scatter(all_data(:, IDX_COOLANT), all_data(:, IDX_RPM), 2, ...
        speed_norm, 'filled', 'MarkerFaceAlpha', 0.4);

colormap(gca, 'cool');
cb = colorbar;
cb.Label.String = 'Vehicle Speed (normalized)';

% SAE threshold lines
xline(105, '--', 'Color', [0.9, 0.7, 0], 'LineWidth', 2, 'Label', 'Yellow 105°C');
xline(120, '--', 'Color', [0.8, 0.0, 0], 'LineWidth', 2, 'Label', 'Red 120°C');
yline(3000,'--', 'Color', [0.9, 0.7, 0], 'LineWidth', 2, 'Label', 'Yellow 3000 rpm');

xlabel('Engine Coolant Temperature (°C)');
ylabel('Engine RPM');
title('RPM vs Coolant Temperature - colored by Vehicle Speed', ...
      'FontSize', 12, 'FontWeight', 'bold');
grid on; box off;

% Anomaly detection on real data
figure('Name', 'Figure 5 - SAE J1979 Anomaly Detection on Real Data', ...
       'Position', [250, 250, 1200, 400]);

n_all = size(all_data, 1);
t_all = (1:n_all) / 10;

% alert level
alert_vec = zeros(n_all, 1);
for s = 1:n_all
    if all_data(s, IDX_COOLANT) >= 120 || all_data(s, IDX_RPM) >= 5500
        alert_vec(s) = 3;
    elseif all_data(s, IDX_COOLANT) >= 115 || all_data(s, IDX_RPM) >= 4500
        alert_vec(s) = 2;
    elseif all_data(s, IDX_COOLANT) >= 105 || all_data(s, IDX_RPM) >= 3000 || ...
           all_data(s, IDX_SPEED) >= 140
        alert_vec(s) = 1;
    end
end

subplot(1, 2, 1);
plot(t_all, all_data(:, IDX_COOLANT), 'b', 'LineWidth', 0.7);
hold on;
plot(t_all(alert_vec >= 1), all_data(alert_vec >= 1, IDX_COOLANT), ...
     'r.', 'MarkerSize', 6);
yline(105, '--y', 'Yellow', 'LineWidth', 1.5);
yline(120, '--r', 'Red',    'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Temperature (°C)');
title('Coolant Temp — Anomalies Detected (red dots)');
legend('Normal', 'Anomaly', 'Location', 'best');
grid on; box off;

subplot(1, 2, 2);
pct_normal = sum(alert_vec == 0) / n_all * 100;
pct_yellow = sum(alert_vec == 1) / n_all * 100;
pct_orange = sum(alert_vec == 2) / n_all * 100;
pct_red    = sum(alert_vec == 3) / n_all * 100;

bar_data = [pct_normal, pct_yellow, pct_orange, pct_red];
b = bar(bar_data, 'FaceColor', 'flat');
b.CData = [0.2, 0.7, 0.2;   % green
            0.9, 0.8, 0.0;   % yellow
            0.9, 0.5, 0.0;   % orange
            0.8, 0.0, 0.0];  % red

xticklabels({'Normal', 'Yellow', 'Orange', 'Red'});
ylabel('% of total readings');
title('Alert Level Distribution in Real Driving Data');
grid on; box off;

for i = 1:4
    text(i, bar_data(i) + 0.5, sprintf('%.1f%%', bar_data(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 10);
end

sgtitle('SAE J1979 Anomaly Detection Applied to Real KIT Vehicle Data', ...
        'FontSize', 12, 'FontWeight', 'bold');

fprintf('[5/5] All figures generated.\n\n');
fprintf('=============================================================\n');
fprintf('  SUMMARY FOR THESIS\n');
fprintf('=============================================================\n');
fprintf('  Dataset  : KIT Automotive OBD-II (Weber, 2023)\n');
fprintf('  Records  : %d samples across %d drive sessions\n', ...
        n_all, length(file_labels));
fprintf('  Anomalies: %.1f%% of readings showed alert-level deviation\n', ...
        100 - pct_normal);
fprintf('\n');
fprintf('  Generated figures:\n');
fprintf('    Fig 1 - OBD-II parameter time series\n');
fprintf('    Fig 2 - Distributions vs SAE J1979 thresholds\n');
fprintf('    Fig 3 - Parameter correlation matrix\n');
fprintf('    Fig 4 - RPM vs Coolant Temp scatter plot\n');
fprintf('    Fig 5 - Anomaly detection on real driving data\n');
fprintf('=============================================================\n');



% colormap
function cmap = redblue_colormap()
    n = 64;
    r = [linspace(0,1,n/2), ones(1,n/2)];
    g = [linspace(0,1,n/2), linspace(1,0,n/2)];
    b = [ones(1,n/2),       linspace(1,0,n/2)];
    cmap = [r', g', b'];
end
