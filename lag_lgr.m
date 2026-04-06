clear; clc; close all;
pkg load control;
pkg load signal;

addpath('designers');
addpath('utils');

% Planta do sistema
sys(1).T = 0.002;
sys(1).K_plant = 1.0836;
sys(1).tau_plant = 0.0088;

sys(2).K_plant = 1.4388;
sys(2).tau_plant = 0.0212;
sys(2).T = sys(2).tau_plant / 10;

plant = 2;

T = sys(plant).T;
K_plant = sys(plant).K_plant;
tau_plant = sys(plant).tau_plant;

plant_model = build_plant_for_embedded(K_plant, tau_plant, T);
Gs = plant_model.Gs;
Gz = plant_model.Gz;

fprintf('Planta (embedded) ordem=%d | a=%s | b=%s\n', ...
    plant_model.embedded.order, mat2str(plant_model.embedded.a, 6), mat2str(plant_model.embedded.b, 6));
fprintf('Mapa bilinear: %s\n', plant_model.w_info.mapping);

% Requisitos simples para o lag
req.Mp = 8;
req.ts = 2.0;
req.OutSat = 10.0;
req.K_plant = K_plant;
req.tau_plant = tau_plant;

fprintf('\n╔════════════════════════════════════════╗\n');
fprintf('║ EXECUTION MODE: LAG                   ║\n');
fprintf('║ Target: Mp ≤ 8%%, ts ≤ 2.0s           ║\n');
fprintf('╚════════════════════════════════════════╝\n');

[Gcz_lag, info_lag] = design_lag_lgr(Gz, T, req);

fprintf('\n--- LAG MODE RESULT ---\n');
fprintf('Compensador projetado: zc=%.4f, pc=%.4f\n', info_lag.zc, info_lag.pc);
fprintf('Kc=%.4f\n', info_lag.Kc);
if isnan(info_lag.metrics.tp)
    tp_text = 'N/A';
else
    tp_text = sprintf('%.3fs', info_lag.metrics.tp);
end
fprintf('Mp=%.2f%% | tp=%s | ts=%.3fs | u_max=%.2fV\n', ...
    info_lag.metrics.Mp, tp_text, info_lag.metrics.ts, info_lag.metrics.u_max);

report_dir = fullfile(pwd, 'report', 'lag_lgr');
plots_dir = fullfile(report_dir, 'plots');
[~, ~, ~] = mkdir(plots_dir);

timestamp = strftime('%Y%m%d_%Hh%M', localtime(time()));
run_label = sprintf('%s_lag_lgr', timestamp);

plot_path_rlocus = fullfile(plots_dir, [run_label '_rlocus.png']);
plot_path_step = fullfile(plots_dir, [run_label '_step.png']);
plot_path_pzmap = fullfile(plots_dir, [run_label '_pzmap.png']);
plot_path_step_uncomp = fullfile(plots_dir, [run_label '_step_uncompensated.png']);
plot_path_square_uncomp = fullfile(plots_dir, [run_label '_square_uncompensated.png']);
plot_path_triangle_uncomp = fullfile(plots_dir, [run_label '_triangle_uncompensated.png']);

plot_uncompensated_step(Gs, Gz, T, plot_path_step_uncomp);
plot_uncompensated_square(Gs, Gz, T, plot_path_square_uncomp);
plot_uncompensated_triangle(Gs, Gz, T, plot_path_triangle_uncomp);
lgr_analysis = plot_root_locus_analysis(Gz, Gcz_lag, info_lag.zd, info_lag.label, plot_path_rlocus);
analyze_performance(Gz, Gcz_lag, T, req, info_lag.label, plot_path_step);
plot_pzmaps(Gz, Gcz_lag, info_lag.label, plot_path_pzmap);

report_path = generate_lag_report(Gs, Gz, Gcz_lag, T, req, info_lag, run_label, report_dir, ...
    plot_path_step_uncomp, plot_path_square_uncomp, plot_path_triangle_uncomp, ...
    plot_path_rlocus, plot_path_step, plot_path_pzmap, lgr_analysis);

fprintf('\n✓ Lag-LGR plots saved in: %s\n', plots_dir);
fprintf('✓ Lag-LGR report saved in: %s\n', report_path);
