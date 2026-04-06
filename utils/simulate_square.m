function [t_sat, u_max] = simulate_square(Gz, Gcz, T, label, OutSat, save_path)
    amp = 1.6; freq = 0.1; t_final = 20;
    t = 0:T:t_final;
    ref = amp * square(2 * pi * freq * t);
    color_uncomp = [1.0, 0.5, 0.0];
    
    if nargin < 6
        save_path = [];
    end

    FTMF = feedback(Gcz * Gz, 1);
    FT_ctrl = feedback(Gcz, Gz);
    FTMF_uncomp = feedback(Gz, 1);
    FT_ctrl_uncomp = feedback(1, Gz);

    y = lsim(FTMF, ref, t);
    u_ideal = lsim(FT_ctrl, ref, t);
    y_uncomp = lsim(FTMF_uncomp, ref, t);
    u_uncomp = lsim(FT_ctrl_uncomp, ref, t);

    % Cálculo de métricas
    u_max = max(abs(u_ideal));
    t_sat = sum(abs(u_ideal) > OutSat) * T;

    u_sat = u_ideal;
    u_sat(u_sat > OutSat) = OutSat;
    u_sat(u_sat < -OutSat) = -OutSat;

    figure('Name', ['Simulação Quadrada - ', label]);
    ax1 = subplot(2,1,1);
    stairs(t, ref, 'k--', 'LineWidth', 1.2); hold on;
    stairs(t, y, 'b', 'LineWidth', 1.5);
    stairs(t, y_uncomp, 'Color', color_uncomp, 'LineWidth', 1.5);
    grid on;
    title({['Resposta à Onda Quadrada - ', label], sprintf('T_s = %.4f s', T)});
    set(ax1, 'Position', [0.10, 0.58, 0.62, 0.34]);
    legend(ax1, 'Referência', 'Saída compensada y(k)', 'Saída sem compensação y(k)', 'Location', 'eastoutside');
    ylabel('Tensão (V)');

    ax2 = subplot(2,1,2);
    stairs(t, u_ideal, 'r', 'LineWidth', 1.2); hold on;
    stairs(t, u_sat, 'g', 'LineWidth', 1.2);
    stairs(t, u_uncomp, 'Color', color_uncomp, 'LineWidth', 1.2);
    grid on;
    title({'Esforço de Controle u(k)', sprintf('T_s = %.4f s', T)});
    xlabel('Tempo (s)'); ylabel('Tensão (V)');
    set(ax2, 'Position', [0.10, 0.10, 0.62, 0.34]);
    legend(ax2, 'u ideal compensado', 'u saturado compensado', 'u sem compensação', 'Location', 'eastoutside');

    % Inserir métricas no gráfico
    txt = {['Pico Ideal: ', num2str(u_max, '%.2f'), ' V'], ...
           ['Tempo Sat: ', num2str(t_sat, '%.3f'), ' s']};
    text(t_final*0.6, u_max*0.7, txt, 'FontSize', 10, 'EdgeColor', 'red');

    fprintf('\n--- MÉTRICAS QUADRADA (%s) ---\n', label);
    fprintf('Pico de Tensão Ideal: %.2f V\n', u_max);
    fprintf('Tempo Total em Saturação: %.3f s\n', t_sat);
    
    % Save figure if path provided
    if ~isempty(save_path)
        saveas(gcf, save_path, 'png');
        close(gcf);
    end
end
