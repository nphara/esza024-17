function [Gcz, info] = design_lead_lgr(Gz, T, tau, req)
    % 1. Cálculos de wn, zeta e zd
    zeta = -log(req.Mp/100) / sqrt(pi^2 + (log(req.Mp/100))^2);
    wn = pi / (req.tp * sqrt(1 - zeta^2));
    sd = -zeta*wn + 1i*wn*sqrt(1-zeta^2);
    zd = exp(sd*T);

    % 2. Projeto Geométrico
    zc = exp(-T/tau); 
    % ... (Cálculos de pc e Kc que fizemos anteriormente)
    
    Gcz = Kc * tf([1 -zc], [1 -pc], T);
    info.zd = zd;
    info.type = "Lead LGR";
end