function Gcz = design_pi_freq(Gz, T, req)
    Gw = d2c(Gz, 'tustin');
    % Lógica de Margem de Fase (MF)
    % ... (Cálculo de wzi e Kpi)
    Gcz = c2d(Cw, T, 'tustin');
end