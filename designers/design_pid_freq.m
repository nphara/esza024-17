function [Gpid_z, info] = design_pid_freq(Gz, T, req)
    % 1. Mapeamento para o plano w
    Gw = d2c(Gz, 'tustin');
    
    % 2. Especificações
    zeta = -log(req.Mp/100) / sqrt(pi^2 + (log(req.Mp/100))^2);
    % Margem de Fase alvo (regra de projeto: entre 45 e 65 graus)
    PM_desejada = 85; 
    
    % Frequência de cruzamento (limitada para não ser agressiva demais)
    % Se wc for muito alto, o PID explode. Vamos limitar a 10 rad/s para teste.
    %wc = min(pi / req.tp, 15); 
    wc = 7.0;
    
    % 3. Obter magnitude e fase
    [mag, fase_planta] = bode(Gw, wc);
    fase_planta = mod(fase_planta, -360);
    
    % 4. Projeto simplificado (PI-D) para evitar instabilidade
    % Vamos garantir que o PID adicione fase positiva
    fase_necessaria = PM_desejada - (180 + fase_planta);
    
    % Limitamos a fase do derivador para 60 graus para evitar ganhos infinitos
    fase_necessaria = max(min(fase_necessaria, 60), 10);
    
    % Ganhos baseados na frequência
    Td = tan(deg2rad(fase_necessaria)) / wc;
    Ti = 4 / wc; % Regra de Zeigler-Nichols adaptada
    
    % Kp para cruzar em 0dB
    mag_pid = abs(1 + 1/(1j*Ti*wc) + 1j*Td*wc);
    Kp = 1 / (mag * mag_pid);
    
    % 5. Filtro Derivativo (Obrigatório para não explodir)
    %N = 5; % Filtro mais forte (menor ganho de alta frequência)
    N = 1.8;
    s = tf('s');
    Gpid_w = Kp * (1 + 1/(Ti*s) + (Td*s)/(1 + (Td/N)*s));
    
    % 6. Conversão e Estabilização
    Gpid_z = c2d(Gpid_w, T, 'tustin');
    
    % VERIFICAÇÃO DE ESTABILIDADE: Se pc > 1, o sistema explode
    p_pid = pole(Gpid_z);
    if any(abs(p_pid) > 1.0001)
        warning('Controlador PID instável detectado! Reduzindo ganhos...');
        Gpid_z = Gpid_z * 0.1; % Redução de emergência para teste
    end
    
    info.label = 'PID (Frequência)';
    info.Kp = Kp; info.Ti = Ti; info.Td = Td;
end