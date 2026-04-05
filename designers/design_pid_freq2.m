function [Gz, info] = design_pid_freq2(Gz_planta, T, req)
    % --- 1. Mapeamento Bilinear e Pré-empenamento ---
    % Conforme Slide 28 e Exemplo 1
    wc_analoga = 2.6 / req.tp; 
    wc_w = (2/T) * tan(wc_analoga * T / 2); 
    
    Gw = d2c(Gz_planta, 'tustin');
    [mag_p, fase_p] = bode(Gw, wc_w);
    fase_p = mod(fase_p, -360);
    
    % --- 2. Especificações de Margem de Fase (Slide 112) ---
    zeta = -log(req.Mp/100) / sqrt(pi^2 + (log(req.Mp/100))^2);
    PM_alvo = (zeta * 100) + 10; 
    
    % --- 3. Módulo de Avanço (PD / Lead) - Slide 177 ---
    fase_lag_previsao = -5.0; 
    phi_lead = PM_alvo - (180 + fase_p + fase_lag_previsao);
    phi_lead = max(min(phi_lead, 60), 15);
    
    Td = tan(deg2rad(phi_lead)) / wc_w;
    N = 4.0; % Filtro para atenuar saturação (Slide 120)
    G_lead_w = tf([Td 1], [Td/N 1]);
    
    % --- 4. Módulo de Atraso (PI / Lag) - Slide 178 ---
    Ti = 1 / (wc_w * tan(deg2rad(abs(fase_lag_previsao))));
    G_lag_w = tf([Ti 1], [Ti 0]);
    
    % --- 5. Cálculo do Ganho Kp (Slide 121) ---
    mag_lead = sqrt(1 + (Td*wc_w)^2) / sqrt(1 + (Td*wc_w/N)^2);
    mag_lag = sqrt(1 + (Ti*wc_w)^2) / (Ti*wc_w);
    Kp = 1 / (mag_p * mag_lead * mag_lag);
    
    % --- 6. Ganhos e Identificação ---
    info.label = 'PID Modular (Frequência - Refinado)';
    info.Kp = Kp; info.Ki = Kp / Ti; info.Kd = Kp * Td;
    
    % Composição e Discretização
    G_pid_w = Kp * G_lag_w * G_lead_w;
    Gz = c2d(G_pid_w, T, 'tustin');
    
    % --- EXIBIÇÃO DE RESULTADOS NO TERMINAL ---
    fprintf('\n--- DADOS DE PROJETO (AULA 2 / SEMANA 3) ---\n');
    disp('FT da Planta no plano w G(w):');
    zpk(Gw)
    disp('FT do Compensador PID no plano Z C(z):');
    zpk(Gz)
    disp('FT Malha Aberta Compensada G(w)C(w):');
    zpk(G_pid_w * Gw)
    
    fprintf('Ganhos Calculados: Kp = %.4f | Ki = %.4f | Kd = %.4f\n', info.Kp, info.Ki, info.Kd);
    
    % FT Malha Fechada com Polos e Zeros
    Gz_mf = feedback(Gz * Gz_planta, 1);
    disp('FT Malha Fechada T(z) [Zpk]:');
    zpk(Gz_mf)
    
    % Bode do Sistema Compensado
    figure('Name', 'Bode Malha Aberta Compensada');
    bode(G_pid_w * Gw); grid on;
    title('Diagrama de Bode - Sistema Compensado (Plano w)');
end