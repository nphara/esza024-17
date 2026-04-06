function report_path = generate_design_report(Gz, T, Gs, req, Gcz, info, metrics, run_label, plots_folder)
    % generate_design_report - Create a single-mode markdown report with plots.

    if ~isfield(req, 'K_plant'), req.K_plant = NaN; end
    if ~isfield(req, 'tau_plant'), req.tau_plant = NaN; end
    if ~isfield(req, 'OutSat'), req.OutSat = NaN; end

    K_plant = req.K_plant;
    tau_plant = req.tau_plant;
    OutSat = req.OutSat;

    fprintf('\n--- Generating plots for report ---\n');

    plot_path_step_uncomp = fullfile(plots_folder, [run_label '_step_uncompensated.png']);
    plot_uncompensated_step(Gs, Gz, T, plot_path_step_uncomp);
    fprintf('  ✓ Saved: %s\n', plot_path_step_uncomp);

    plot_path_square_uncomp = fullfile(plots_folder, [run_label '_square_uncompensated.png']);
    plot_uncompensated_square(Gs, Gz, T, plot_path_square_uncomp);
    fprintf('  ✓ Saved: %s\n', plot_path_square_uncomp);

    plot_path_triangle_uncomp = fullfile(plots_folder, [run_label '_triangle_uncompensated.png']);
    plot_uncompensated_triangle(Gs, Gz, T, plot_path_triangle_uncomp);
    fprintf('  ✓ Saved: %s\n', plot_path_triangle_uncomp);

    plot_path_rlocus = fullfile(plots_folder, [run_label '_rlocus.png']);
    lgr_analysis = plot_root_locus_analysis(Gz, Gcz, info.zd, info.label, plot_path_rlocus);
    fprintf('  ✓ Saved: %s\n', plot_path_rlocus);

    plot_path_rlocus_cmp = fullfile(plots_folder, [run_label '_rlocus_comparison.png']);
    plot_root_locus_comparison(Gz, Gcz, info.zd, info.label, plot_path_rlocus_cmp);
    fprintf('  ✓ Saved: %s\n', plot_path_rlocus_cmp);

    plot_path_step = fullfile(plots_folder, [run_label '_step.png']);
    analyze_performance(Gz, Gcz, T, req, info.label, plot_path_step);
    fprintf('  ✓ Saved: %s\n', plot_path_step);

    plot_path_step_cmp = fullfile(plots_folder, [run_label '_step_comparison.png']);
    plot_step_response_comparison(Gz, Gcz, T, info.label, plot_path_step_cmp);
    fprintf('  ✓ Saved: %s\n', plot_path_step_cmp);

    plot_path_pzmap = fullfile(plots_folder, [run_label '_pzmap.png']);
    plot_pzmaps(Gz, Gcz, info.label, plot_path_pzmap);
    fprintf('  ✓ Saved: %s\n', plot_path_pzmap);

    plot_path_square = fullfile(plots_folder, [run_label '_square.png']);
    simulate_square(Gz, Gcz, T, info.label, OutSat, plot_path_square);
    fprintf('  ✓ Saved: %s\n', plot_path_square);

    plot_path_triangle = fullfile(plots_folder, [run_label '_triangle.png']);
    simulate_triangle(Gz, Gcz, T, info.label, OutSat, plot_path_triangle);
    fprintf('  ✓ Saved: %s\n', plot_path_triangle);

    status = 'INFEASIBLE';
    if isfield(info, 'found') && info.found
        status = 'FEASIBLE';
    end

    report_filename = [run_label, '_report.md'];
    report_dir = fileparts(plots_folder);
    report_path = fullfile(report_dir, report_filename);

    fprintf('\n--- Generating markdown report ---\n');
    fid = fopen(report_path, 'w');
    now_ts = strftime('%Y-%m-%d %H:%M:%S', localtime(time()));

    fprintf(fid, '# Lead Compensator Design Report\n\n');
    fprintf(fid, '**Generated**: %s | **Status**: %s | **Mode**: Analytic LGR\n\n', now_ts, status);
    fprintf(fid, '---\n\n');

    fprintf(fid, '## Uncompensated System Analysis\n\n');
    fprintf(fid, 'The following responses compare the plant before compensation in the continuous-time domain (s) and the discrete-time domain (z).\n\n');
    fprintf(fid, '### Step Response\n\n');
    fprintf(fid, '![Uncompensated Step Response](plots/%s_step_uncompensated.png)\n\n', run_label);
    fprintf(fid, '### Square Wave Response\n\n');
    fprintf(fid, '![Uncompensated Square Wave Response](plots/%s_square_uncompensated.png)\n\n', run_label);
    fprintf(fid, '### Triangle Wave Response\n\n');
    fprintf(fid, '![Uncompensated Triangle Wave Response](plots/%s_triangle_uncompensated.png)\n\n', run_label);
    fprintf(fid, '---\n\n');

    fprintf(fid, '## System Configuration\n\n');
    fprintf(fid, '| Parameter | Value |\n');
    fprintf(fid, '|-----------|-------|\n');
    fprintf(fid, '| K_plant | %.6f |\n', K_plant);
    fprintf(fid, '| tau_plant | %.6f s |\n', tau_plant);
    fprintf(fid, '| T_sample | %.6f s |\n', T);
    fprintf(fid, '| OutSat | %.1f V |\n', OutSat);
    fprintf(fid, '\n');

    fprintf(fid, '## Design Result\n\n');
    fprintf(fid, '| Parameter | Value | Status |\n');
    fprintf(fid, '|-----------|-------|--------|\n');
    fprintf(fid, '| z_c | %.6f | ✓ |\n', info.zc);
    fprintf(fid, '| p_c | %.6f | ✓ |\n', info.pc);
    fprintf(fid, '| K_c | %.6f | ✓ |\n', info.Kc);
    fprintf(fid, '| Structure | %s | %s |\n', info.structure, iif(strcmp(info.structure, 'lead-like'), 'OK', 'WARN'));
    fprintf(fid, '| Feasibility | %s | %s |\n', status, iif(strcmp(status, 'FEASIBLE'), 'OK', 'FAIL'));
    fprintf(fid, '\n');

    fprintf(fid, '## Performance Metrics\n\n');
    fprintf(fid, '| Metric | Target | Achieved | Status |\n');
    fprintf(fid, '|--------|--------|----------|--------|\n');
    if isstruct(metrics)
        fprintf(fid, '| Mp | <= %.0f%% | %s | %s |\n', req.Mp, fmt_metric(metrics, 'Mp', '%.2f%%'), metric_status_le(metrics, 'Mp', req.Mp));
        fprintf(fid, '| tp | <= %.2fs | %s | %s |\n', req.tp, fmt_metric(metrics, 'tp', '%.3fs'), metric_status_le(metrics, 'tp', req.tp));
        fprintf(fid, '| u_max_step | <= %.1fV | %s | %s |\n', 0.9 * OutSat, fmt_metric(metrics, 'u_max_step', '%.2fV'), metric_status_le(metrics, 'u_max_step', 0.9 * OutSat));
        fprintf(fid, '| u_max_sq | <= %.1fV | %s | %s |\n', 1.1 * OutSat, fmt_metric(metrics, 'u_max_sq', '%.2fV'), metric_status_le(metrics, 'u_max_sq', 1.1 * OutSat));
        fprintf(fid, '| u_max_tri | <= %.1fV | %s | %s |\n', 1.1 * OutSat, fmt_metric(metrics, 'u_max_tri', '%.2fV'), metric_status_le(metrics, 'u_max_tri', 1.1 * OutSat));
        fprintf(fid, '| t_sat_sq | <= 0.05s | %s | %s |\n', fmt_metric(metrics, 't_sat_sq', '%.3fs'), metric_status_le(metrics, 't_sat_sq', 0.05));
        fprintf(fid, '| t_sat_tri | <= 0.02s | %s | %s |\n', fmt_metric(metrics, 't_sat_tri', '%.3fs'), metric_status_le(metrics, 't_sat_tri', 0.02));
    else
        fprintf(fid, '| *Metrics unavailable* | - | - | FAIL |\n');
    end
    fprintf(fid, '\n');

    fprintf(fid, '## Feasibility Gate Diagnostics\n\n');
    fprintf(fid, '| Gate | Threshold | Rejections |\n');
    fprintf(fid, '|------|-----------|------------|\n');
    fprintf(fid, '| u_max_step | <= %.1fV | %s |\n', 0.9 * OutSat, gate_rejections(info, 'u_max_step'));
    fprintf(fid, '| u_max_sq | <= %.1fV | %s |\n', 1.1 * OutSat, gate_rejections(info, 'u_max_sq'));
    fprintf(fid, '| u_max_tri | <= %.1fV | %s |\n', 1.1 * OutSat, gate_rejections(info, 'u_max_tri'));
    fprintf(fid, '| t_sat_sq | <= 0.05s | %s |\n', gate_rejections(info, 't_sat_sq'));
    fprintf(fid, '| t_sat_tri | <= 0.02s | %s |\n', gate_rejections(info, 't_sat_tri'));
    fprintf(fid, '\n');

    fprintf(fid, '## Root Locus Analysis (Open Loop)\n\n');
    fprintf(fid, '![Root Locus](plots/%s_rlocus.png)\n\n', run_label);
    fprintf(fid, '### LGR Numerical Analysis\n\n');
    fprintf(fid, '| Scenario | Phase Error (deg) | K* real | K* imag | On Locus |\n');
    fprintf(fid, '|----------|-------------------|---------|---------|----------|\n');
    fprintf(fid, '| Original | %.2f | %.4f | %.4f | %s |\n', ...
        lgr_analysis.original.phase_err_deg, lgr_analysis.original.k_real, lgr_analysis.original.k_imag, on_locus_text(lgr_analysis.original.on_locus));
    fprintf(fid, '| Compensated | %.2f | %.4f | %.4f | %s |\n\n', ...
        lgr_analysis.compensated.phase_err_deg, lgr_analysis.compensated.k_real, lgr_analysis.compensated.k_imag, on_locus_text(lgr_analysis.compensated.on_locus));
    fprintf(fid, 'Diagnosis: %s\n\n', lgr_diagnosis_text(lgr_analysis));

    fprintf(fid, '## Root Locus Comparison (Open Loop)\n\n');
    fprintf(fid, 'This figure overlays the uncompensated and compensated open-loop root loci on the same axes.\n\n');
    fprintf(fid, '![Open-loop Root Locus Comparison](plots/%s_rlocus_comparison.png)\n\n', run_label);

    fprintf(fid, '## Step Response (Closed Loop)\n\n');
    fprintf(fid, '![Step Response](plots/%s_step.png)\n\n', run_label);

    fprintf(fid, '## Step Response Comparison (Closed Loop)\n\n');
    fprintf(fid, 'This figure overlays the uncompensated and compensated closed-loop step responses on the same axes.\n\n');
    fprintf(fid, '![Closed-loop Step Response Comparison](plots/%s_step_comparison.png)\n\n', run_label);

    fprintf(fid, '## Pole-Zero Map\n\n');
    fprintf(fid, '![Pole-Zero Map](plots/%s_pzmap.png)\n\n', run_label);

    fprintf(fid, '## Square Wave Response\n\n');
    fprintf(fid, '![Square Wave Response](plots/%s_square.png)\n\n', run_label);

    fprintf(fid, '## Triangle Wave Response\n\n');
    fprintf(fid, '![Triangle Wave Response](plots/%s_triangle.png)\n\n', run_label);

    fprintf(fid, '---\n\n');
    fprintf(fid, '## Embedded Implementation\n\n');
    fprintf(fid, '```yaml\n');
    fprintf(fid, 'Kc: %.6f\n', info.Kc);
    fprintf(fid, 'z_c: %.6f\n', info.zc);
    fprintf(fid, 'p_c: %.6f\n', info.pc);
    fprintf(fid, 'b0: %.6f\n', info.Kc);
    fprintf(fid, 'b1: %.6f\n', -info.Kc * info.zc);
    fprintf(fid, 'a1: %.6f\n', -info.pc);
    fprintf(fid, '```\n\n');
    fprintf(fid, 'Run: `python deploy_yaml_generator.py %.6f %.6f %.6f`\n\n', info.Kc, info.pc, info.zc);

    fprintf(fid, '---\n\n');
    fprintf(fid, '_Report generated by: `generate_design_report.m`_\n');
    fprintf(fid, '_Timestamp: %s_\n', now_ts);

    fclose(fid);
    fprintf('\n✓ Report saved: %s\n', report_path);
end

function result = iif(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

function out = fmt_metric(metrics, field_name, fmt)
    if isstruct(metrics) && isfield(metrics, field_name)
        val = metrics.(field_name);
        if isnumeric(val) && isscalar(val) && isfinite(val)
            out = sprintf(fmt, val);
            return;
        end
    end
    out = 'N/A';
end

function out = metric_status_le(metrics, field_name, limit)
    if isstruct(metrics) && isfield(metrics, field_name)
        val = metrics.(field_name);
        if isnumeric(val) && isscalar(val) && isfinite(val)
            out = iif(val <= limit, 'OK', 'FAIL');
            return;
        end
    end
    out = 'WARN';
end

function out = gate_rejections(info, gate_name)
    if isstruct(info) && isfield(info, 'gate_failures') && isstruct(info.gate_failures) && ...
       isfield(info.gate_failures, gate_name)
        val = info.gate_failures.(gate_name);
        if isnumeric(val) && isscalar(val) && isfinite(val)
            out = sprintf('%d', round(val));
            return;
        end
    end
    out = 'N/A';
end

function out = on_locus_text(flag)
    if flag
        out = 'YES';
    else
        out = 'NO';
    end
end

function out = lgr_diagnosis_text(analysis)
    if analysis.original.on_locus && ~analysis.compensated.on_locus
        out = 'Compensation shifted the locus away from z_d.';
    elseif ~analysis.original.on_locus && analysis.compensated.on_locus
        out = 'Compensation made z_d reachable by root locus.';
    elseif analysis.original.on_locus && analysis.compensated.on_locus
        out = 'z_d is reachable in both cases; compare effort and robustness.';
    else
        out = 'z_d is not on the locus in either case; revise target or controller structure.';
    end
end

function plot_uncompensated_step(Gs, Gz, T, save_path)
    t_cont = 0:0.001:2.0;
    t_disc = 0:T:2.0;
    y_cont = step(Gs, t_cont);
    y_disc = step(Gz, t_disc);

    figure('Name', 'Uncompensated Step Response');
    subplot(1,2,1);
    plot(t_cont, y_cont, 'b', 'LineWidth', 1.5);
    grid on; title('Step Response - s domain'); xlabel('Time (s)'); ylabel('Output');

    subplot(1,2,2);
    stairs(t_disc, y_disc, 'r', 'LineWidth', 1.5);
    grid on; title('Step Response - z domain'); xlabel('Time (s)'); ylabel('Output');

    saveas(gcf, save_path, 'png');
    close(gcf);
end

function plot_uncompensated_square(Gs, Gz, T, save_path)
    t_cont = 0:0.001:20;
    t_disc = 0:T:20;
    ref_cont = 1.6 * square(2 * pi * 0.1 * t_cont);
    ref_disc = 1.6 * square(2 * pi * 0.1 * t_disc);
    y_cont = lsim(Gs, ref_cont, t_cont);
    y_disc = lsim(Gz, ref_disc, t_disc);

    figure('Name', 'Uncompensated Square Response');
    subplot(1,2,1);
    plot(t_cont, ref_cont, 'k--', t_cont, y_cont, 'b', 'LineWidth', 1.2);
    grid on; title('Square - s domain'); xlabel('Time (s)'); ylabel('Output'); legend('Ref', 'y');

    subplot(1,2,2);
    stairs(t_disc, ref_disc, 'k--'); hold on;
    stairs(t_disc, y_disc, 'r', 'LineWidth', 1.2);
    grid on; title('Square - z domain'); xlabel('Time (s)'); ylabel('Output'); legend('Ref', 'y');

    saveas(gcf, save_path, 'png');
    close(gcf);
end

function plot_uncompensated_triangle(Gs, Gz, T, save_path)
    t_cont = 0:0.001:20;
    t_disc = 0:T:20;
    ref_cont = 1.6 * sawtooth(2 * pi * 0.1 * t_cont, 0.5);
    ref_disc = 1.6 * sawtooth(2 * pi * 0.1 * t_disc, 0.5);
    y_cont = lsim(Gs, ref_cont, t_cont);
    y_disc = lsim(Gz, ref_disc, t_disc);

    figure('Name', 'Uncompensated Triangle Response');
    subplot(1,2,1);
    plot(t_cont, ref_cont, 'k--', t_cont, y_cont, 'b', 'LineWidth', 1.2);
    grid on; title('Triangle - s domain'); xlabel('Time (s)'); ylabel('Output'); legend('Ref', 'y');

    subplot(1,2,2);
    stairs(t_disc, ref_disc, 'k--'); hold on;
    stairs(t_disc, y_disc, 'r', 'LineWidth', 1.2);
    grid on; title('Triangle - z domain'); xlabel('Time (s)'); ylabel('Output'); legend('Ref', 'y');

    saveas(gcf, save_path, 'png');
    close(gcf);
end
