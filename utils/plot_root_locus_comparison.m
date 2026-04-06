function analysis = plot_root_locus_comparison(Gz, Gcz, zd, label, save_path)
    % Plot open-loop root loci of uncompensated and compensated systems on the same axes.

    if nargin < 4
        label = 'Controlador';
    end
    if nargin < 5
        save_path = [];
    end

    L0 = Gz;
    Lc = Gcz * Gz;

    figure('Name', ['Comparacao LGR Aberto - ', label]);
    ax = axes();
    hold(ax, 'on');
    grid(ax, 'on');
    axis(ax, 'equal');
    xlabel(ax, 'Real');
    ylabel(ax, 'Imaginario');
    title(ax, 'Comparacao de LGR em Malha Aberta');
    set(ax, 'Position', [0.10, 0.11, 0.62, 0.82]);

    h_before = findobj(ax, 'Type', 'line');
    rlocus(L0);
    h_after_open = findobj(ax, 'Type', 'line');
    h_open_locus = setdiff(h_after_open, h_before);

    h_before_comp = findobj(ax, 'Type', 'line');
    rlocus(Lc);
    h_after_comp = findobj(ax, 'Type', 'line');
    h_comp_locus = setdiff(h_after_comp, h_before_comp);

    set(h_open_locus, 'Color', 'b', 'LineWidth', 1.4);
    set(h_comp_locus, 'Color', 'r', 'LineWidth', 0.7);

    th = linspace(0, 2*pi, 200);
    plot(cos(th), sin(th), 'k--', 'LineWidth', 1.0);

    h_open = plot(nan, nan, 'b-', 'LineWidth', 1.4);
    h_comp = plot(nan, nan, 'r-', 'LineWidth', 0.7);
    h_unit = plot(nan, nan, 'k--', 'LineWidth', 1.0);
    h_zd = plot(real(zd), imag(zd), 'LineStyle', 'none', 'Color', [1 0 1], ...
        'Marker', 'x', 'LineWidth', 2, 'MarkerSize', 10);

    legend(ax, [h_open, h_comp, h_unit, h_zd], ...
        {'LGR malha aberta sem compensacao', 'LGR malha aberta com compensacao', ...
        'Circulo unitario', 'z_d (polo desejado)'}, ...
        'Location', 'eastoutside');

    analysis.original = local_locus_point_analysis(L0, zd);
    analysis.compensated = local_locus_point_analysis(Lc, zd);

    fprintf('\n--- ANALISE LGR COMPARATIVA (aberto): %s ---\n', label);
    local_print_line('Aberto sem compensacao', analysis.original);
    local_print_line('Aberto com compensacao', analysis.compensated);

    if ~isempty(save_path)
        saveas(gcf, save_path, 'png');
        close(gcf);
    end
end

function out = local_locus_point_analysis(L, zd)
    val = local_eval_tf(L, zd);

    phase_err = abs(atan2(sin(angle(val) - pi), cos(angle(val) - pi)));
    k_complex = -1 / val;

    out.phase_err_deg = phase_err * 180 / pi;
    out.k_real = real(k_complex);
    out.k_imag = imag(k_complex);

    imag_ratio = abs(out.k_imag) / max(abs(out.k_real), 1e-12);
    phase_tol_deg = 3.0;
    imag_ratio_tol = 0.02;

    out.on_locus = (out.phase_err_deg <= phase_tol_deg) && ...
                   (out.k_real > 0) && ...
                   (imag_ratio <= imag_ratio_tol);
end

function y = local_eval_tf(sys, z)
    [num, den] = tfdata(sys, 'v');
    y = polyval(num, z) / polyval(den, z);
end

function local_print_line(name, data)
    if data.on_locus
        tag = '[OK]';
    else
        tag = '[FORA]';
    end

    fprintf('%s: fase_err=%.2f deg | K*=%.4f%+.4fj | %s\n', ...
        name, data.phase_err_deg, data.k_real, data.k_imag, tag);
end