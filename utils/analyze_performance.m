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
    fprintf('Mp: %.2f %% | Requisito: < %.1f %% | STATUS: %s\n', Mp, req.Mp, status_mp);

    % 2. tp: Verificação para Avanço
    % Usamos aspas simples e a função de busca de forma mais genérica
    if ~isempty(strfind(lower(label), 'avanco')) || ~isempty(strfind(lower(label), 'avanço'))
        status_tp = '[SUCESSO]';
        if tp > req.tp, status_tp = '[FALHA]'; end
        fprintf('tp: %.3f s | Requisito: < %.1f s | STATUS: %s\n', tp, req.tp, status_tp);
    else
        % Se não for avanco, apenas mostra o valor sem julgar SUCESSO/FALHA
        fprintf('tp (2%%): %.3f s (Sem requisito de assentamento para este tipo)\n', tp);
    end

    % 3. ts: Verificação para Atraso
    if ~isempty(strfind(lower(label), 'atraso'))
        status_ts = '[SUCESSO]';
        if ts > req.ts, status_ts = '[FALHA]'; end
        fprintf('ts (2%%): %.3f s | Requisito: < %.1f s | STATUS: %s\n', ts, req.ts, status_ts);
    else
        % Se não for atraso, apenas mostra o valor sem julgar SUCESSO/FALHA
        fprintf('ts (2%%): %.3f s (Sem requisito de assentamento para este tipo)\n', ts);
    end

    % 4. u_max
    status_u = '[SUCESSO]';
    if u_max > 10.0, status_u = '[ALERTA - SATURA]'; end
    fprintf('u_max: %.2f V | Limite: 10.0 V | STATUS: %s\n', u_max, status_u);

    fprintf('==================================================\n');
end
