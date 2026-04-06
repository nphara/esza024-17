function report_path = generate_lag_report(Gs, Gz, Gcz, T, req, info, run_label, report_dir, ...
    plot_path_step_uncomp, plot_path_square_uncomp, plot_path_triangle_uncomp, ...
    plot_path_rlocus, plot_path_step, plot_path_pzmap, lgr_analysis)
    % generate_lag_report - Minimal markdown report for the lag design.

    [~, ~, ~] = mkdir(report_dir);

    report_filename = [run_label '_report.md'];
    report_path = fullfile(report_dir, report_filename);
    fid = fopen(report_path, 'w');
    now_ts = strftime('%Y-%m-%d %H:%M:%S', localtime(time()));

    fprintf(fid, '# Lag Compensator Design Report\n\n');
    fprintf(fid, '**Generated**: %s\n\n', now_ts);
    fprintf(fid, '---\n\n');

    fprintf(fid, '## Uncompensated System Analysis\n\n');
    fprintf(fid, 'The following responses compare the plant before compensation in the continuous-time domain (s) and the discrete-time domain (z).\n\n');

    fprintf(fid, '### Step Response\n\n');
    fprintf(fid, '![Uncompensated Step Response](plots/%s)\n\n', local_relpath(plot_path_step_uncomp));

    fprintf(fid, '### Square Wave Response\n\n');
    fprintf(fid, '![Uncompensated Square Wave Response](plots/%s)\n\n', local_relpath(plot_path_square_uncomp));

    fprintf(fid, '### Triangle Wave Response\n\n');
    fprintf(fid, '![Uncompensated Triangle Wave Response](plots/%s)\n\n', local_relpath(plot_path_triangle_uncomp));

    fprintf(fid, '---\n\n');

    fprintf(fid, '## System Configuration\n\n');
    fprintf(fid, '| Parameter | Value |\n');
    fprintf(fid, '|-----------|-------|\n');
    fprintf(fid, '| T_sample | %.6f s |\n', T);
    fprintf(fid, '| Mp target | %.0f%% |\n', req.Mp);
    fprintf(fid, '| ts target | %.2f s |\n', req.ts);
    fprintf(fid, '| OutSat | %.1f V |\n', req.OutSat);
    fprintf(fid, '\n');

    fprintf(fid, '## Lag Design Result\n\n');
    fprintf(fid, '| Parameter | Value |\n');
    fprintf(fid, '|-----------|-------|\n');
    fprintf(fid, '| z_c | %.6f |\n', info.zc);
    fprintf(fid, '| p_c | %.6f |\n', info.pc);
    fprintf(fid, '| K_c | %.6f |\n', info.Kc);
    fprintf(fid, '| Mp | %.2f%% |\n', info.metrics.Mp);
    fprintf(fid, '| tp | %s |\n', local_tp_text(info.metrics.tp));
    fprintf(fid, '| ts | %.3fs |\n', info.metrics.ts);
    fprintf(fid, '| u_max | %.2f V |\n', info.metrics.u_max);
    fprintf(fid, '\n');

    fprintf(fid, '## Plots\n\n');
    fprintf(fid, '### Root Locus\n\n');
    fprintf(fid, '![](plots/%s)\n\n', local_relpath(plot_path_rlocus));

    fprintf(fid, '### LGR Numerical Analysis\n\n');
    fprintf(fid, '| Scenario | Phase Error (deg) | K* real | K* imag | On Locus |\n');
    fprintf(fid, '|----------|-------------------|---------|---------|----------|\n');
    fprintf(fid, '| Original | %.2f | %.4f | %.4f | %s |\n', ...
        lgr_analysis.original.phase_err_deg, ...
        lgr_analysis.original.k_real, ...
        lgr_analysis.original.k_imag, ...
        local_on_locus_text(lgr_analysis.original.on_locus));
    fprintf(fid, '| Compensated | %.2f | %.4f | %.4f | %s |\n\n', ...
        lgr_analysis.compensated.phase_err_deg, ...
        lgr_analysis.compensated.k_real, ...
        lgr_analysis.compensated.k_imag, ...
        local_on_locus_text(lgr_analysis.compensated.on_locus));
    fprintf(fid, 'Diagnosis: %s\n\n', local_lgr_diagnosis_text(lgr_analysis));

    fprintf(fid, '### Step Response\n\n');
    fprintf(fid, '![](plots/%s)\n\n', local_relpath(plot_path_step));

    fprintf(fid, '### Pole-Zero Map\n\n');
    fprintf(fid, '![](plots/%s)\n\n', local_relpath(plot_path_pzmap));

    fprintf(fid, '---\n\n');
    fprintf(fid, '## Embedded Implementation\n\n');
    fprintf(fid, '```yaml\n');
    fprintf(fid, 'Kc: %.6f\n', info.Kc);
    fprintf(fid, 'zc: %.6f\n', info.zc);
    fprintf(fid, 'pc: %.6f\n', info.pc);
    fprintf(fid, '```\n\n');

    fprintf(fid, '_Plant used for report only: Gs = %s_\n', local_tf_text(Gs));

    fclose(fid);
end

function out = local_tp_text(tp)
    if isnan(tp)
        out = 'N/A';
    else
        out = sprintf('%.3fs', tp);
    end
end

function out = local_relpath(path_value)
    [~, name, ext] = fileparts(path_value);
    out = [name ext];
end

function out = local_tf_text(sys)
    [num, den] = tfdata(sys, 'v');
    out = sprintf('tf(%s, %s)', mat2str(num, 6), mat2str(den, 6));
end

function out = local_on_locus_text(flag)
    if flag
        out = 'YES';
    else
        out = 'NO';
    end
end

function out = local_lgr_diagnosis_text(analysis)
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