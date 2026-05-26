% =========================================================================
% VEHICLE FAULT PREDICTION SYSTEM
% Bachelor's Thesis: Application of Artificial Neural Networks
%                    for Vehicle Technical Condition Analysis
%
% Author  : Niks Isacenko
% Advisor : Docent Henrihs Gorskis
% =========================================================================

clc; clear; close all;

% SAE J1979 PARAMETER DEFINITIONS

%   .name       - display name
%   .unit       - measurement unit
%   .normal     - [min, max] normal operating range
%   .yellow     - LOW alert
%   .orange     - MEDIUM alert
%   .red        - HIGH alert

params = struct();

% Engine
params(1).name      = 'Engine Coolant Temperature';
params(1).unit      = 'C';
params(1).normal    = [80, 105];
params(1).yellow    = 105;
params(1).orange    = 115;
params(1).red       = 120;
params(1).direction = 'high';
params(1).nominal   = 92;   % default

params(2).name      = 'Engine RPM';
params(2).unit      = 'rpm';
params(2).normal    = [600, 3000];
params(2).yellow    = 3000;
params(2).orange    = 4500;
params(2).red       = 5500;
params(2).direction = 'high';
params(2).nominal   = 1500;

params(3).name      = 'Engine Load';
params(3).unit      = '%';
params(3).normal    = [10, 75];
params(3).yellow    = 75;
params(3).orange    = 88;
params(3).red       = 95;
params(3).direction = 'high';
params(3).nominal   = 35;

params(4).name      = 'Intake Air Temperature';
params(4).unit      = 'C';
params(4).normal    = [10, 50];
params(4).yellow    = 50;
params(4).orange    = 65;
params(4).red       = 80;
params(4).direction = 'high';
params(4).nominal   = 25;

% Fuel System
params(5).name      = 'Short Term Fuel Trim';
params(5).unit      = '%';
params(5).normal    = [-10, 10];
params(5).yellow    = 15;
params(5).orange    = 20;
params(5).red       = 25;
params(5).direction = 'both';
params(5).nominal   = 0;

params(6).name      = 'Fuel Tank Pressure';
params(6).unit      = 'kPa';
params(6).normal    = [-1, 1];
params(6).yellow    = 1.5;
params(6).orange    = 2.5;
params(6).red       = 3.5;
params(6).direction = 'both';
params(6).nominal   = 0;

% Air & Throttle
params(7).name      = 'Mass Air Flow Rate';
params(7).unit      = 'g/s';
params(7).normal    = [2, 25];
params(7).yellow    = 25;
params(7).orange    = 35;
params(7).red       = 45;
params(7).direction = 'high';
params(7).nominal   = 8;

params(8).name      = 'Throttle Position';
params(8).unit      = '%';
params(8).normal    = [10, 80];
params(8).yellow    = 80;
params(8).orange    = 90;
params(8).red       = 98;
params(8).direction = 'high';
params(8).nominal   = 20;

% Electrical
params(9).name      = 'Battery Voltage';
params(9).unit      = 'V';
params(9).normal    = [13.5, 14.5];
params(9).yellow    = 12.5;
params(9).orange    = 12.0;
params(9).red       = 11.5;
params(9).direction = 'low';
params(9).nominal   = 14.0;

% Exhaust & Emissions
params(10).name      = 'O2 Sensor Voltage';
params(10).unit      = 'V';
params(10).normal    = [0.1, 0.9];
params(10).yellow    = 0.05;
params(10).orange    = 0.03;
params(10).red       = 0.01;
params(10).direction = 'low';
params(10).nominal   = 0.45;

% Transmission
params(11).name      = 'Vehicle Speed';
params(11).unit      = 'km/h';
params(11).normal    = [0, 120];
params(11).yellow    = 140;
params(11).orange    = 160;
params(11).red       = 180;
params(11).direction = 'high';
params(11).nominal   = 60;

% Component Wear
params(12).name      = 'Component Wear Index';
params(12).unit      = 'min';
params(12).normal    = [0, 150];
params(12).yellow    = 150;
params(12).orange    = 200;
params(12).red       = 240;
params(12).direction = 'high';
params(12).nominal   = 50;

num_params = length(params);


% FAULT KNOWLEDGE BASE


faults = struct();

faults(1).name        = 'Engine Overheating';
faults(1).triggers    = [1, 7, 3];   % coolant temp, MAF, engine load
faults(1).description = 'High coolant temp with elevated load suggests cooling system failure';
faults(1).action      = 'Stop vehicle immediately. Allow engine to cool. Check coolant level.';

faults(2).name        = 'Fuel System Malfunction';
faults(2).triggers    = [5, 6, 10];  % fuel trim, tank pressure, O2
faults(2).description = 'Abnormal fuel trim and O2 readings indicate fuel mixture problems';
faults(2).action      = 'Reduce speed. Schedule fuel injector or O2 sensor inspection.';

faults(3).name        = 'Air Intake Fault';
faults(3).triggers    = [4, 7, 8];   % intake air temp, MAF, throttle
faults(3).description = 'Abnormal airflow and intake temperature suggest air system restriction';
faults(3).action      = 'Check air filter and throttle body. Inspect MAF sensor.';

faults(4).name        = 'Electrical / Charging Fault';
faults(4).triggers    = [9, 2];      % battery voltage, RPM
faults(4).description = 'Low battery voltage may indicate alternator or battery failure';
faults(4).action      = 'Test battery and alternator. Avoid turning off engine if possible.';

faults(5).name        = 'Engine Mechanical Stress';
faults(5).triggers    = [2, 3, 12];  % RPM, engine load, wear index
faults(5).description = 'High RPM with excessive load indicates mechanical overstrain';
faults(5).action      = 'Reduce engine load. Avoid aggressive acceleration. Schedule inspection.';

faults(6).name        = 'Exhaust / Emissions Fault';
faults(6).triggers    = [10, 5];     % O2 sensor, fuel trim
faults(6).description = 'O2 sensor anomaly with fuel trim deviation suggests catalytic or exhaust issue';
faults(6).action      = 'Reduce speed. Inspect O2 sensors and catalytic converter.';

faults(7).name        = 'Transmission / Speed Anomaly';
faults(7).triggers    = [11, 2];     % vehicle speed, RPM
faults(7).description = 'Speed-RPM mismatch may indicate transmission or wheel sensor issue';
faults(7).action      = 'Drive cautiously. Have transmission inspected at next opportunity.';

num_faults = length(faults);


% TRAINING DATA


fprintf('=============================================================\n');
fprintf('   VEHICLE FAULT PREDICTION SYSTEM\n');
fprintf('   Two-Level Diagnostic Architecture\n');
fprintf('   Based on SAE J1979 Standard\n');
fprintf('=============================================================\n\n');

fprintf('[1/4] Generating training dataset from SAE J1979 thresholds...\n');

rng(42);
n_per_class = 600;    % samples per fault class
X_data = [];
Y_data = [];

for f = 1:num_faults
    for s = 1:n_per_class

        % Start with all-normal values
        sample = arrayfun(@(p) p.nominal, params);

        % noise
        for pi = 1:num_params
            p = params(pi);
            baseline_range = p.normal(2) - p.normal(1);
            sample(pi) = sample(pi) + randn() * baseline_range * 0.08;
        end

        triggers = faults(f).triggers;
        n_triggers = length(triggers);
        % Randomly use 1 to all trigger params
        n_active = randi([1, n_triggers]);
        active_triggers = triggers(randperm(n_triggers, n_active));

        for ti = 1:length(active_triggers)
            pi = active_triggers(ti);
            p  = params(pi);

            % Randomly vary how severe the anomaly is
            r = rand();
            if r < 0.40
                severity = 1;   % yellow
            elseif r < 0.80
                severity = 2;   % orange
            else
                severity = 3;   % red
            end

            if strcmp(p.direction, 'high') || strcmp(p.direction, 'both')
                switch severity
                    case 1, lo = p.yellow; hi = p.orange;
                    case 2, lo = p.orange; hi = p.red;
                    case 3, lo = p.red;    hi = p.red * 1.15;
                end
            else
                switch severity
                    case 1, lo = p.orange; hi = p.yellow;
                    case 2, lo = p.red;    hi = p.orange;
                    case 3, lo = p.red * 0.85; hi = p.red;
                end
            end

            sample(pi) = lo + rand() * (hi - lo);
        end

        % more noise
        for pi = 1:num_params
            noise_pct = 0.07 + rand() * 0.05;   % 7-12% 
            sample(pi) = sample(pi) * (1 + noise_pct * randn());
        end

        % secondary random parameter deviation
 
        if rand() < 0.15
            rand_param = randi(num_params);
            p = params(rand_param);
            cross_range = p.normal(2) - p.normal(1);
            sample(rand_param) = sample(rand_param) + randn() * cross_range * 0.4;
        end

        X_data = [X_data; sample];
        Y_data = [Y_data; f];
    end
end

% no fault class
for s = 1:n_per_class
    sample = arrayfun(@(p) p.nominal, params);
    for pi = 1:num_params
        p = params(pi);
        range = p.normal(2) - p.normal(1);
        sample(pi) = p.normal(1) + rand() * range;
        % noise
        sample(pi) = sample(pi) * (1 + 0.05 * randn());
    end
    X_data = [X_data; sample];
    Y_data = [Y_data; 0];
end

total_samples = size(X_data, 1);
fprintf('    Generated %d training samples (%d fault classes + normal)\n', ...
        total_samples, num_faults);


% MLP


fprintf('[2/4] Training neural network (MLP 12->32->16->8)...\n');

% Normalize
[X_norm, mu, sigma] = zscore(X_data);

% Shuffle and split 80/20
idx = randperm(total_samples);
split = round(0.8 * total_samples);
train_idx = idx(1:split);
test_idx  = idx(split+1:end);

num_classes = num_faults + 1;   % faults + "no fault"
Y_labels = Y_data + 1;          

X_train = X_norm(train_idx, :)';
Y_train = full(ind2vec(Y_labels(train_idx)', num_classes));
X_test  = X_norm(test_idx, :)';
Y_test  = full(ind2vec(Y_labels(test_idx)', num_classes));

net = patternnet([32, 16, 8]);
net.trainFcn = 'trainscg';
net.trainParam.epochs     = 300;
net.trainParam.goal       = 1e-5;
net.trainParam.showWindow = false;
net.divideParam.trainRatio = 0.80;
net.divideParam.valRatio   = 0.10;
net.divideParam.testRatio  = 0.10;

[net, tr] = train(net, X_train, Y_train);

% Accuracy check
Y_pred_raw = net(X_test);
[~, pred_class] = max(Y_pred_raw);
[~, true_class] = max(Y_test);
accuracy = mean(pred_class == true_class) * 100;

fprintf('    Training complete. Best epoch: %d\n', tr.best_epoch);
fprintf('    Test Accuracy: %.2f%%\n\n', accuracy);

% Confusion matrix
figure('Name', 'Neural Network Confusion Matrix');
plotconfusion(Y_test, Y_pred_raw);
title(sprintf('MLP Confusion Matrix — Test Accuracy: %.1f%%', accuracy));


% HELPER


% SAE J1979 threshold check
function [level, info] = check_threshold(value, p)
    level = 0;
    info  = '';
    if strcmp(p.direction, 'high')
        if     value >= p.red,    level = 3; info = sprintf('%.2f %s >> RED threshold (%.1f)', value, p.unit, p.red);
        elseif value >= p.orange, level = 2; info = sprintf('%.2f %s > ORANGE threshold (%.1f)', value, p.unit, p.orange);
        elseif value >= p.yellow, level = 1; info = sprintf('%.2f %s > YELLOW threshold (%.1f)', value, p.unit, p.yellow);
        end
    elseif strcmp(p.direction, 'low')
        if     value <= p.red,    level = 3; info = sprintf('%.2f %s << RED threshold (%.1f)', value, p.unit, p.red);
        elseif value <= p.orange, level = 2; info = sprintf('%.2f %s < ORANGE threshold (%.1f)', value, p.unit, p.orange);
        elseif value <= p.yellow, level = 1; info = sprintf('%.2f %s < YELLOW threshold (%.1f)', value, p.unit, p.yellow);
        end
    else % 'both'
        dev = abs(value - mean(p.normal)) / (diff(p.normal)/2);
        if     dev >= 2.5, level = 3; info = sprintf('%.2f %s far outside normal [%.1f, %.1f]', value, p.unit, p.normal(1), p.normal(2));
        elseif dev >= 1.8, level = 2; info = sprintf('%.2f %s outside normal range', value, p.unit);
        elseif dev >= 1.2, level = 1; info = sprintf('%.2f %s near boundary of normal', value, p.unit);
        end
    end
end


% MAIN DIAGNOSIS


function run_diagnosis_cycle(values, params, net, mu, sigma, faults, num_classes, label)

    num_params = length(params);
    alert_names = {'NONE', 'LOW [YELLOW]', 'MEDIUM [ORANGE]', 'HIGH [RED]'};

    fprintf('\n=============================================================\n');
    fprintf('  DIAGNOSIS REPORT — %s\n', label);
    fprintf('=============================================================\n');

    % Threshold Analysis
    fprintf('\n  LEVEL 1: Parameter Threshold Analysis (SAE J1979)\n');
    fprintf('  ----------------------------------------------------------\n');

    max_alert    = 0;
    anomalies    = [];   % indices of anomalous parameters
    alert_levels = zeros(1, num_params);

    for pi = 1:num_params
        [lv, info] = check_threshold(values(pi), params(pi));
        alert_levels(pi) = lv;
        if lv > 0
            anomalies(end+1) = pi;
            max_alert = max(max_alert, lv);
            fprintf('  [%s] %s\n', alert_names{lv+1}, params(pi).name);
            fprintf('       Value: %s\n\n', info);
        end
    end

    if isempty(anomalies)
        fprintf('  All parameters within normal operating ranges.\n');
    end

    % MLP Prediction
    fprintf('\n  LEVEL 2: Neural Network Fault Prediction (MLP)\n');
    fprintf('  ----------------------------------------------------------\n');

    input_norm = ((values - mu) ./ sigma)';
    prediction = net(input_norm);
    [sorted_conf, sorted_idx] = sort(prediction, 'descend');

    class_names = {'No Fault'};
    for f = 1:length(faults)
        class_names{end+1} = faults(f).name;
    end

    top_class = sorted_idx(1);
    top_conf  = sorted_conf(1) * 100;

    fprintf('  Top predicted faults:\n');
    for k = 1:min(3, num_classes)
        ci = sorted_idx(k);
        fprintf('    %d. %-35s %.1f%%\n', k, class_names{ci}, sorted_conf(k)*100);
    end

    % RESULT
    % Decision logic:
    %     - NO anomalies detected -> result is NORMAL
    %     - anomalies detected -> mlp identifies fault type

    fprintf('\n=============================================================\n');
    fprintf('  FINAL DIAGNOSIS\n');
    fprintf('=============================================================\n');

    if max_alert == 0
        % found nothing - system is ok
        fprintf('  STATUS     : NORMAL\n');
        fprintf('  FAULT      : No fault detected\n');
        fprintf('  ALERT      : NONE\n');
        fprintf('  ACTION     : No action required. Continue monitoring.\n');
        % mlp = supplementary info only
        fprintf('\n  [INFO] Neural network supplementary output:\n');
        fprintf('         Top prediction: %s (%.1f%%)\n', ...
                class_names{top_class}, top_conf);
        fprintf('         Note: Ignored — no threshold violations detected.\n');

    elseif max_alert > 0 && top_class > 1 && top_conf >= 70
        % found anomaly and mlp confirms with high confidence
        f_idx = top_class - 1;
        fprintf('  STATUS     : FAULT DETECTED\n');
        fprintf('  FAULT      : %s\n', faults(f_idx).name);
        fprintf('  CONFIDENCE : %.1f%%\n', top_conf);
        fprintf('  ALERT      : %s\n', alert_names{max_alert+1});
        fprintf('  REASON     : %s\n', faults(f_idx).description);
        fprintf('  ACTION     : %s\n', faults(f_idx).action);

    elseif max_alert > 0 && top_conf < 70
        % found anomaly but mlp is uncertain
        fprintf('  STATUS     : ANOMALY DETECTED (fault type unclear)\n');
        fprintf('  ALERT      : %s\n', alert_names{max_alert+1});
        fprintf('  CONFIDENCE : %.1f%% (below threshold for fault ID)\n', top_conf);
        fprintf('  ACTION     : Inspect anomalous parameters. Seek professional diagnosis.\n');

    else
        % found anomaly, mlp predicts normal
        fprintf('  STATUS     : ANOMALY DETECTED\n');
        fprintf('  ALERT      : %s\n', alert_names{max_alert+1});
        fprintf('  ACTION     : Monitor affected parameters. Schedule inspection.\n');
    end

    % parameters triggers the alert
    if ~isempty(anomalies)
        fprintf('\n  ANOMALOUS PARAMETERS:\n');
        for ai = anomalies
            fprintf('    - %s: %.2f %s\n', params(ai).name, values(ai), params(ai).unit);
        end
    end
    fprintf('=============================================================\n\n');
end


% INTERACTIVE MAIN MENU

fprintf('[3/4] System ready.\n');
fprintf('[4/4] Starting interactive interface...\n\n');

running = true;

while running

    fprintf('-------------------------------------------------------------\n');
    fprintf('  MAIN MENU\n');
    fprintf('-------------------------------------------------------------\n');
    fprintf('  1. Manual diagnosis  (enter sensor values yourself)\n');
    fprintf('  2. Random simulation (system randomizes parameters)\n');
    fprintf('  3. Exit\n');
    fprintf('-------------------------------------------------------------\n');
    choice = input('  Select option (1/2/3): ', 's');
    choice = strtrim(choice);

    switch choice

        % MANUAL MODE

        case '1'  
        fprintf('\n  Enter current OBD-II sensor readings:\n');
        fprintf('  (Press ENTER to use default normal value)\n\n');

        values = zeros(1, num_params);
        for pi = 1:num_params
            prompt = sprintf('  %s (%s) [normal: %.1f]: ', ...
                             params(pi).name, params(pi).unit, params(pi).nominal);
            raw = input(prompt, 's');
            raw = strtrim(raw);
            if isempty(raw)
                values(pi) = params(pi).nominal;
            else
                values(pi) = str2double(raw);
                if isnan(values(pi))
                    fprintf('  Invalid input, using default.\n');
                    values(pi) = params(pi).nominal;
                end
            end
        end

        run_diagnosis_cycle(values, params, net, mu, sigma, faults, num_classes, 'MANUAL INPUT');

        % RANDOM MODE

        case '2'  
        fprintf('\n-------------------------------------------------------------\n');
        fprintf('  RANDOM SIMULATION\n');
        fprintf('-------------------------------------------------------------\n');

        values = arrayfun(@(p) p.nominal, params);

        % how many parameters (1 to 4)
        num_disturb = randi([1, 4]);
        disturb_idx = randperm(num_params, num_disturb);

        fprintf('  Starting state: ALL PARAMETERS NORMAL\n\n');
        fprintf('  Applying random disturbances to %d parameter(s)...\n\n', num_disturb);
        fprintf('  CHANGES MADE:\n');
        fprintf('  ----------------------------------------------------------\n');

        for di = 1:num_disturb
            pi = disturb_idx(di);
            p  = params(pi);
            old_val = values(pi);

            % alert level random
            sim_level = randi([1, 3]);

            if strcmp(p.direction, 'high')
                switch sim_level
                    case 1, new_val = p.yellow  + rand() * (p.orange - p.yellow);
                    case 2, new_val = p.orange  + rand() * (p.red    - p.orange);
                    case 3, new_val = p.red     + rand() * (p.red    * 0.15);
                end
            elseif strcmp(p.direction, 'low')
                switch sim_level
                    case 1, new_val = p.orange  + rand() * (p.yellow  - p.orange);
                    case 2, new_val = p.red     + rand() * (p.orange  - p.red);
                    case 3, new_val = p.red     * (0.85  + rand() * 0.1);
                end
            else % both
                sign_dir = sign(randn());
                shift = p.yellow + rand() * (p.red - p.yellow);
                new_val = mean(p.normal) + sign_dir * shift;
            end

            values(pi) = new_val;
            change_pct = (new_val - old_val) / abs(old_val) * 100;

            if change_pct > 0
                direction_str = sprintf('+%.1f%%', change_pct);
            else
                direction_str = sprintf('%.1f%%',  change_pct);
            end

            level_names = {'YELLOW', 'ORANGE', 'RED'};
            fprintf('  [%s] %s\n', level_names{sim_level}, p.name);
            fprintf('         Normal value : %.2f %s\n', old_val, p.unit);
            fprintf('         New value    : %.2f %s  (%s)\n\n', new_val, p.unit, direction_str);
        end

        fprintf('  ----------------------------------------------------------\n');
        fprintf('  Parameters NOT changed (remain normal):\n');
        normal_idx = setdiff(1:num_params, disturb_idx);
        for ni = normal_idx
            fprintf('    OK  %s: %.2f %s\n', params(ni).name, values(ni), params(ni).unit);
        end

        run_diagnosis_cycle(values, params, net, mu, sigma, faults, num_classes, 'RANDOM SIMULATION');

       % EXIT
       
        case '3'   
        running = false;
        fprintf('\n  System closed. Goodbye.\n');
        fprintf('=============================================================\n');

        otherwise
            fprintf('  Invalid option. Please enter 1, 2, or 3.\n\n');
    end
end
