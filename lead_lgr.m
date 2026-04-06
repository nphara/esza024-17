clear; clc; close all;
pkg load control;
pkg load signal;

% Adicionar subpastas ao caminho (se necessário)
addpath('designers'); addpath('utils');

% PLANTA DO SISTEMA %
%===================%

sys(1).T = 0.002;
sys(1).K_plant = 1.0836;
sys(1).tau_plant = 0.0088;


sys(2).K_plant = 1.4388;
sys(2).tau_plant = 0.0212;
sys(2).T = sys(2).tau_plant/10;

plant = 2

T = sys(plant).T
K_plant = sys(plant).K_plant
tau_plant = sys(plant).tau_plant

% Transformacoes da planta para projeto e uso embarcado
plant_model = build_plant_for_embedded(K_plant, tau_plant, T);
Gs = plant_model.Gs;
Gz = plant_model.Gz;
Gw = plant_model.Gw;

fprintf('Planta (embedded) ordem=%d | a=%s | b=%s\n', ...
    plant_model.embedded.order, mat2str(plant_model.embedded.a, 6), mat2str(plant_model.embedded.b, 6));
fprintf('Mapa bilinear: %s\n', plant_model.w_info.mapping);


% REQUISITOS %
%============%

% Condições do roteiro %
%----------------------%

req.Mp = 4; % Sobressinal 4%
req.tp = 0.5;   % Tempo de pico 0.5(s)

req.ts = 2.0;  % Tempo de assentamento (s) - para o Atraso
req.OutSat = 10.0; % Tensão de saturação

% Plant parameters (needed for reporting)
req.K_plant = K_plant;
req.tau_plant = tau_plant;

% ANALISE %
%=========%

% LGR %
%-----%

% Resposta em frequência %
%------------------------%

% PROJETO DO CONTROLADOR %
%========================%


% Geração Automatica (single analytic mode) %
%-------------------------------------------%

req_design = req;
req_design.mode = "analytic";

fprintf('\n╔════════════════════════════════════════╗\n');
fprintf('║ EXECUTION MODE: ANALYTIC LGR          ║\n');
fprintf('║ Target: Mp ≤ %.0f%%, tp ≤ %.1fs         ║\n', req_design.Mp, req_design.tp);
fprintf('╚════════════════════════════════════════╝\n');

[Gcz_lead, info_lead] = design_lead_lgr2(Gz, T, req_design);

fprintf('\n--- ANALYTIC MODE RESULT ---\n');
fprintf('Compensador projetado: zc=%.4f, pc=%.4f\n', info_lead.zc, info_lead.pc);
fprintf('Kc=%.4f | structure=%s | FOUND: %d\n', info_lead.Kc, info_lead.structure, info_lead.found);

if info_lead.found && isstruct(info_lead.metrics)
    fprintf('  Mp=%.2f%% | tp=%.3fs\n', info_lead.metrics.Mp, info_lead.metrics.tp);
    fprintf('  u_max_step=%.2fV | u_max_sq=%.2fV | u_max_tri=%.2fV\n', ...
        info_lead.metrics.u_max_step, info_lead.metrics.u_max_sq, info_lead.metrics.u_max_tri);
    fprintf('  t_sat_sq=%.3fs | t_sat_tri=%.3fs\n', ...
        info_lead.metrics.t_sat_sq, info_lead.metrics.t_sat_tri);
    status_design = "FEASIBLE";
else
    fprintf('  Status: INFEASIBLE UNDER HARD CHECKS\n');
    status_design = "INFEASIBLE";
end

fprintf('\n➤ Using ANALYTIC configuration (%s)\n', status_design);



% Planta Customizada %
%--------------------%

%b0=1.46;zero=0.103;polo=0.764;lead_num = [b0 -b0*zero];lead_den = [1 -polo];
%[Gcz_lead, info_lead] = design_custom(lead_num, lead_den, T, 'Avanço de Fase Ajustado via LGR'); % Novo (Otimizado)


%   RESULTADOS   %
%================%

% === REPORT GENERATION ===
fprintf('\n╔════════════════════════════════════════╗\n');
fprintf('║ GENERATING COMPREHENSIVE REPORT       ║\n');
fprintf('╚════════════════════════════════════════╝\n');

% Setup report folder structure
timestamp = strftime('%Y%m%d_%Hh%M', localtime(time()));
controller_type = 'lead';
design_method = 'lgr';
run_label = sprintf('%s_%s_%s', timestamp, controller_type, design_method);

% Relative path (from srv02 directory)
report_base_dir = fullfile(pwd, 'report');
run_folder = fullfile(report_base_dir, run_label);
plots_folder = fullfile(run_folder, 'plots');

% Create folders
[~, ~, ~] = mkdir(run_folder);
[~, ~, ~] = mkdir(plots_folder);

fprintf('Report folder: %s\n', run_folder);
fprintf('Plots folder:  %s\n', plots_folder);

% Generate comprehensive report with plots
report_path = generate_design_report(Gz, T, Gs, ...
    req_design, ...
    Gcz_lead, info_lead, info_lead.metrics, ...
    run_label, plots_folder);

fprintf('\n✅ Full report and plots generated successfully!\n');
fprintf('   Report: %s\n', report_path);
