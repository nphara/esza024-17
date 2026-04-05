function [Gpid_z, info] = design_pid_freq(Gz, T, req)
    % 1. Mapeamento para o plano w com Pré-empenamento (Aula 2 - Slide 28)
    % wc_analoga ajustada para 2.8/tp para buscar o tempo de pico alvo.
    wc_analoga = 2.8 / req.tp; 
    wc_w = (2/T) * tan(wc_analoga * T / 2); 
    
    % Transformação bilinear da planta para o plano w
    Gw = d2c(Gz, 'tustin');
    
    % 2. Requisitos de Estabilidade (Aula 2 - Slide 112)
    zeta = -log(req.Mp/100) / sqrt(pi^2 + (log(req.Mp/100))^2);
    % Margem de Fase (PM) alvo elevada para 85 graus para compensar
    % o overshoot residual causado pela saturação (windup).
    PM_alvo = 85; 
    
    % 3. Análise da Planta no plano w
    [mag_planta, fase_planta] = bode(Gw, wc_w);
    fase_planta = mod(fase_planta, -360);
    
    % 4. Projeto do PID como Atraso-Avanço (Slide 177)
    % Atraso (PI): Queremos uma perda de fase mínima (ex: -3 deg) na wc_w
    fase_PI = -3.0; 
    
    % Avanço (PD): fase_PD = PM_alvo - (180 + fase_planta + fase_PI)
    fase_PD = PM_alvo - (180 + fase_planta + fase_PI);
    
    % Limitação para garantir realizabilidade e suavidade
    fase_PD = max(min(fase_PD, 60), 10);
    
    % Constantes de Tempo
    Td = tan(deg2rad(fase_PD)) / wc_w;
    % Ti calculado para que o atraso de fase seja exatamente 'fase_PI'
    Ti = 1 / (wc_w * tan(deg2rad(abs(fase_PI)))); 
    
    % 5. Cálculo do Ganho Kp para Ganho Unitário em wc_w
    s_val = 1j * wc_w;
    mag_pid_ideal = abs(1 + 1/(Ti * s_val) + Td * s_val);
    Kp = 1 / (mag_planta * mag_pid_ideal);
    
    % 6. Filtro Derivativo (N) - CRÍTICO para o hardware (Slide 120)
    % Reduzir N para 2.5 limita o "kick" derivativo inicial (Kp*N).
    % Isso reduz o pico de tensão ideal de 69V para ~15V, mitigando a saturação.
    N = 2.5; 
    s = tf('s');
    Gpid_w = Kp * (1 + 1/(Ti*s) + (Td*s)/(1 + (Td/N)*s));
    
    % 7. Conversão Final para o Domínio Z (Tustin)
    Gpid_z = c2d(Gpid_w, T, 'tustin');
    
    info.label = 'PID (Frequência - Final Aula 3)';
    info.Kp = Kp; info.Ti = Ti; info.Td = Td; info.wc_w = wc_w;
end