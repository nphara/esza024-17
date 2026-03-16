function run_periodic_simulations(Gz, Gcz, T, label)
    % Parâmetros do roteiro
    amp = 1.6;
    freq = 0.1;
    t_final = 20;
    t = 0:T:t_final;
    
    % Geração das Referências
    ref_sq = amp * square(2 * pi * freq * t);
    ref_tri = amp * sawtooth(2 * pi * freq * t, 0.5);
    
    % Funções de Transferência
    FTMF = feedback(Gcz * Gz, 1);
    FT_ctrl = feedback(Gcz, Gz);
    
    % --- SIMULAÇÃO ONDA QUADRADA ---
    y_sq = lsim(FTMF, ref_sq, t);
    u_sq_ideal = lsim(FT_ctrl, ref_sq, t);
    
    % Aplicando Saturação de +/- 10V
    u_sq_sat = u_sq_ideal;
    u_sq_sat(u_sq_sat > 10) = 10;
    u_sq_sat(u_sq_sat < -10) = -10;
    
    % Estatísticas para o Relatório
    u_max_sq = max(abs(u_sq_ideal));
    t_sat_sq = sum(abs(u_sq_ideal) > 10) * T;

    % --- SIMULAÇÃO ONDA TRIANGULAR ---
    y_tri = lsim(FTMF, ref_tri, t);
    u_tri_ideal = lsim(FT_ctrl, ref_tri, t);
    
    u_tri_sat = u_tri_ideal;
    u_tri_sat(u_tri_sat > 10) = 10;
    u_tri_sat(u_tri_sat < -10) = -10;
    
    u_max_tri = max(abs(u_tri_ideal));
    t_sat_tri = sum(abs(u_tri_ideal) > 10) * T;

    % --- PLOTAGEM QUADRADA ---
    figure('Name', ['Esforço de Controle Quadrada - ', label]);
    subplot(2,1,1);
    plot(t, ref_sq, 'k--', t, y_sq, 'b', 'LineWidth', 1.2);
    grid on; title(['Resposta à Onda Quadrada (1.6V) - ', label]);
    
    subplot(2,1,2);
    plot(t, u_sq_ideal, 'r:', 'LineWidth', 1); hold on;
    plot(t, u_sq_sat, 'g', 'LineWidth', 1.5);
    line([0 t_final], [10 10], 'Color', 'k', 'LineStyle', '--');
    line([0 t_final], [-10 -10], 'Color', 'k', 'LineStyle', '--');
    grid on; title('Sinal de Controle u(t)');
    legend('Ideal (sem limite)', 'Real (Saturado)', 'Limites ±10V');
    ylabel('Tensão (V)'); axis([0 t_final -u_max_sq-2 u_max_sq+2]);

    % --- LOG NO CONSOLE ---
    fprintf('\n--- ANÁLISE DE ESFORÇO (%s) ---\n', label);
    fprintf('QUADRADA: Pico Ideal = %.2fV | Tempo Sat = %.3fs\n', u_max_sq, t_sat_sq);
    fprintf('TRIANGULAR: Pico Ideal = %.2fV | Tempo Sat = %.3fs\n', u_max_tri, t_sat_tri);
end