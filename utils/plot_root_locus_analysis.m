function analysis = plot_root_locus_analysis(Gz, Gcz, zd, label, save_path)
    % Plota os loci de raiz da planta original e da planta compensada,
    % com overlay do ponto alvo zd e analise numerica de pertencimento ao locus.

    if nargin < 4
        label = 'Controlador';
    end
    if nargin < 5
        save_path = [];
    end

    L0 = Gz;
    Lc = Gcz * Gz;

    figure('Name', ['LGR com Overlay de zd - ', label]);

    % Prepara circulo unitario para os dois subplots
    th = linspace(0, 2*pi, 200);
    ucx = cos(th);
    ucy = sin(th);

    % Subplot 1: LGR da planta original
    ax1 = subplot(2,1,1);
    rlocus(L0);
    hold on;
    grid on;
    axis equal;
    xlabel('Real'); ylabel('Imaginario');
    title('LGR Original: K G(z)');
    h_locus_1 = plot(nan, nan, 'b-', 'LineWidth', 1.0);
    h_unit_1 = plot(ucx, ucy, 'k--', 'LineWidth', 1.0);
    h_zd_1 = plot(real(zd), imag(zd), 'LineStyle', 'none', 'Color', [1 0 1], ...
        'Marker', 'x', 'LineWidth', 2, 'MarkerSize', 10);

        % Reserve right margin and place legend outside axis area.
        set(ax1, 'Position', [0.10, 0.58, 0.62, 0.34]);
        legend(ax1, [h_locus_1, h_unit_1, h_zd_1], {'LGR', 'Circulo unitario', 'z_d (polo desejado)'}, ...
            'Location', 'eastoutside');

    % Subplot 2: LGR compensado
    ax2 = subplot(2,1,2);
    rlocus(Lc);
    hold on;
    grid on;
    axis equal;
    xlabel('Real'); ylabel('Imaginario');
    title('LGR Compensado: K G_c(z)G(z)');
    h_locus_2 = plot(nan, nan, 'b-', 'LineWidth', 1.0);
    h_unit_2 = plot(ucx, ucy, 'k--', 'LineWidth', 1.0);
    h_zd_2 = plot(real(zd), imag(zd), 'LineStyle', 'none', 'Color', [1 0 1], ...
        'Marker', 'x', 'LineWidth', 2, 'MarkerSize', 10);

        % Reserve right margin and place legend outside axis area.
        set(ax2, 'Position', [0.10, 0.10, 0.62, 0.34]);
        legend(ax2, [h_locus_2, h_unit_2, h_zd_2], {'LGR', 'Circulo unitario', 'z_d (polo desejado)'}, ...
            'Location', 'eastoutside');

    % Analise numerica do criterio de angulo/magnitude no ponto zd
    analysis.original = local_locus_point_analysis(L0, zd);
    analysis.compensated = local_locus_point_analysis(Lc, zd);

    fprintf('\n--- ANALISE LGR (zd overlay): %s ---\n', label);
    local_print_line('Original', analysis.original);
    local_print_line('Compensado', analysis.compensated);
    
    % Save figure if path provided
    if ~isempty(save_path)
        saveas(gcf, save_path, 'png');
        close(gcf);
    end

    if analysis.original.on_locus && ~analysis.compensated.on_locus
        fprintf('Diagnostico: o compensador deslocou o locus para longe do alvo zd.\n');
    elseif ~analysis.original.on_locus && analysis.compensated.on_locus
        fprintf('Diagnostico: o compensador tornou zd atingivel pelo LGR.\n');
    elseif analysis.original.on_locus && analysis.compensated.on_locus
        fprintf('Diagnostico: zd e atingivel sem e com compensacao; compare esforco e robustez.\n');
    else
        fprintf('Diagnostico: zd nao esta no locus em nenhum caso; revisar alvo ou estrutura do controlador.\n');
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

    % Tolerancias pragmaticas para analise numerica em ponto complexo
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
