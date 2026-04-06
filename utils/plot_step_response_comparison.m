function plot_step_response_comparison(Gz, Gcz, T, label, save_path)
    % Plot uncompensated and compensated closed-loop step responses on the same axes.

    if nargin < 4
        label = 'Controlador';
    end
    if nargin < 5
        save_path = [];
    end

    F0 = feedback(Gz, 1);
    Fc = feedback(Gcz * Gz, 1);

    t = 0:T:3;
    y0 = step(F0, t);
    yc = step(Fc, t);

    figure('Name', ['Comparacao Resposta ao Degrau - ', label]);
    ax = axes();
    hold(ax, 'on');
    grid(ax, 'on');
    xlabel(ax, 'Tempo (s)');
    ylabel(ax, 'Saida (amostras discretas)');
    title(ax, 'Comparacao da Resposta ao Degrau em Malha Fechada (z, discreta)');

    h0 = stairs(t, y0, 'b-', 'LineWidth', 1.5);
    hc = stairs(t, yc, 'r-', 'LineWidth', 1.5);

    legend(ax, [h0, hc], ...
        {'Malha fechada discreta sem compensacao', 'Malha fechada discreta com compensacao'}, ...
        'Location', 'best');

    fprintf('\n--- ANALISE DEGRAU COMPARATIVA (fechada): %s ---\n', label);
    fprintf('Malha fechada sem compensacao | y_final=%.4f | y_max=%.4f\n', y0(end), max(y0));
    fprintf('Malha fechada com compensacao | y_final=%.4f | y_max=%.4f\n', yc(end), max(yc));

    if ~isempty(save_path)
        saveas(gcf, save_path, 'png');
        close(gcf);
    end
end