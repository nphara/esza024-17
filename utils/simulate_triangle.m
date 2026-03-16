function simulate_triangle(Gz, Gcz, T, label)
    amp = 1.6; freq = 0.1; t_final = 20;
    t = 0:T:t_final;
    ref = amp * sawtooth(2 * pi * freq * t, 0.5);
    
    FTMF = feedback(Gcz * Gz, 1);
    FT_ctrl = feedback(Gcz, Gz);
    
    y = lsim(FTMF, ref, t);
    u_ideal = lsim(FT_ctrl, ref, t);
    
    % Cálculo de métricas
    u_max = max(abs(u_ideal));
    t_sat = sum(abs(u_ideal) > 10.0) * T;
    
    u_sat = u_ideal;
    u_sat(u_sat > 10) = 10;
    u_sat(u_sat < -10) = -10;
    
    figure('Name', ['Simulação Triangular - ', label]);
    subplot(2,1,1);
    plot(t, ref, 'k--', t, y, 'r', 'LineWidth', 1.5);
    grid on; title(['Resposta à Onda Triangular - ', label]);
    legend('Referência', 'Saída y(t)');
    
    subplot(2,1,2);
    plot(t, u_ideal, 'b:', t, u_sat, 'm', 'LineWidth', 1.2);
    grid on; title('Esforço de Controle u(t)');
    xlabel('Tempo (s)'); ylabel('Tensão (V)');
    
    % Inserir métricas no gráfico
    txt = {['Pico Ideal: ', num2str(u_max, '%.2f'), ' V'], ...
           ['Tempo Sat: ', num2str(t_sat, '%.3f'), ' s']};
    text(t_final*0.6, max(abs(u_ideal))*0.7, txt, 'FontSize', 10, 'EdgeColor', 'blue');
    
    fprintf('\n--- MÉTRICAS TRIANGULAR (%s) ---\n', label);
    fprintf('Pico de Tensão Ideal: %.2f V\n', u_max);
    fprintf('Tempo Total em Saturação: %.3f s\n', t_sat);
end