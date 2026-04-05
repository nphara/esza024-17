function analyze_performance(Gz, Gcz, T, req, label)
    % Malha fechada
    FTMF = feedback(Gcz * Gz, 1);

    % Resposta ao degrau
    t = 0:T:3;
    [y, t] = step(FTMF, t);

    % --- CÁLCULO DAS MÉTRICAS ---

    % 1. Sobressinal (Mp)
    ymax = max(y);
    yfinal = y(end);
    Mp = ((ymax - yfinal) / yfinal) * 100;
    if Mp < 0, Mp = 0; end

    % 2. Tempo de Pico (tp)
    [~, idx_pico] = max(y);
    tp = t(idx_pico);

    % 3. Tempo de Estabilização (ts) - Critério de 2%
    % Encontra o último instante em que a saída sai da faixa de 2%
    threshold = 0.02;
    idx_ts = find(abs(y - yfinal) > threshold * yfinal, 1, 'last');
    if isempty(idx_ts)
        ts = 0;
    else
        ts = t(idx_ts + 1);
    end

    % 4. Esforço de Controle Máximo (u_max) para degrau unitário
    FT_ctrl = feedback(Gcz, Gz);
    u = lsim(FT_ctrl, ones(size(t)), t);
    u_max = max(abs(u));

    % --- EXIBIÇÃO DOS RESULTADOS ---
    fprintf('\n========== ANÁLISE: %s ==========\n', label);

    % 1. Mp: Sempre avaliado
    status_mp = '[SUCESSO]';
    if Mp > req.Mp, status_mp = '[FALHA]'; end
    fprintf('Mp: %.2f %% | Requisito: < %.2f %% | STATUS: %s\n', Mp, req.Mp, status_mp);

    % 2. tp: Verificação para Avanço
    % Usamos aspas simples e a função de busca de forma mais genérica
    if ~isempty(strfind(lower(label), 'avanco')) || ~isempty(strfind(lower(label), 'avanço'))
        status_tp = '[SUCESSO]';
        if tp > req.tp, status_tp = '[FALHA]'; end
        fprintf('tp: %.3f s | Requisito: < %.3f s | STATUS: %s\n', tp, req.tp, status_tp);
    else
        % Se não for avanco, apenas mostra o valor sem julgar SUCESSO/FALHA
        fprintf('tp : %.3f s (Sem requisito de pico para este tipo)\n', tp);
    end

    % 3. ts: Verificação para Atraso
    if ~isempty(strfind(lower(label), 'atraso'))
        status_ts = '[SUCESSO]';
        if ts > req.ts, status_ts = '[FALHA]'; end
        fprintf('ts (2%%): %.3f s | Requisito: < %.3f s | STATUS: %s\n', ts, req.ts, status_ts);
    else
        % Se não for atraso, apenas mostra o valor sem julgar SUCESSO/FALHA
        fprintf('ts (2%%): %.3f s (Sem requisito de assentamento para este tipo)\n', ts);
    end

    % 4. u_max
    status_u = '[SUCESSO]';
    if u_max > req.OutSat, status_u = '[ALERTA - SATURA]'; end
    fprintf('u_max: %.2f V | Limite: %.1f V | STATUS: %s\n', u_max, req.OutSat, status_u);

    fprintf('==================================================\n');

    % 1. Definir o tempo e a amplitude da referência (conforme roteiro)
    t_sim = 0:T:2;      % 2 segundos é suficiente para ver o transiente
    Amp = 1.6;          % Amplitude de 1.6V definida no roteiro

    % 2. Funções de Transferência de Malha Fechada
    FTMF = feedback(Gcz * Gz, 1);    % Relação Referência -> Saída
    FT_ctrl = feedback(Gcz, Gz);     % Relação Referência -> Esforço (u)

    % 3. Criar a Janela de Gráficos
    figure('Name', 'Simulação de Controle SRV02');

    % --- Gráfico Superior: Resposta do Sistema ---
    subplot(2,1,1);
    [y, t] = step(Amp * FTMF, t_sim);
    plot(t, y, 'b', 'LineWidth', 1.5);
    hold on;
    line([0 t(end)], [Amp Amp], 'Color', 'r', 'LineStyle', '--'); % Referência
    grid on;
    title('Resposta ao Degrau (Saída de Posição)');
    ylabel('Amplitude (V)');
    legend('Saída y', 'Referência r');

    % --- Gráfico Inferior: Esforço de Controle ---
    subplot(2,1,2);
    [u, t] = step(Amp * FT_ctrl, t_sim);
    plot(t, u, 'g', 'LineWidth', 1.5);
    hold on;
    % Linhas de limite do hardware Quanser (+/- OutSat)
    line([0 t(end)], [req.OutSat req.OutSat], 'Color', 'r', 'LineStyle', '--');
    line([0 t(end)], [-req.OutSat -req.OutSat], 'Color', 'r', 'LineStyle', '--');
    grid on;
    title('Sinal de Controle (Esforço)');
    ylabel('Tensão (V)');
    xlabel('Tempo (s)');
    legend('Esforço u', 'Limite Hardware');

    % Ajusta os limites para facilitar a visualização
    ylim([-1.2 * req.OutSat 1.2 * req.OutSat]);
end
