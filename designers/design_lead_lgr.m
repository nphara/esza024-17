function [Gcz, info] = design_lead_lgr(Gz, T, tau, req)
    % 1. Determinação dos parâmetros desejados no plano s
    zeta = -log(req.Mp/100) / sqrt(pi^2 + (log(req.Mp/100))^2);
    wd = pi / req.tp;
    wn = wd / sqrt(1 - zeta^2);

    sd = -zeta*wn + 1i*wd;
    zd = exp(sd*T); % Polo desejado no plano z

    % 2. Projeto do Compensador (Geometria)
    % Cancelamento do polo estável da planta
    zc = exp(-T/tau);

    % Obtenção do zero da planta (discretização gera um zero)
    [num_gz, den_gz] = tfdata(Gz, 'v');
    z_zero_plant = -num_gz(2)/num_gz(1);

    % Condição de Ângulo para achar pc
    ang_z_plant = angle(zd - z_zero_plant);
    ang_p1 = angle(zd - 1);
    ang_pc = pi + ang_z_plant - ang_p1;

    pc = real(zd) - imag(zd) / tan(ang_pc);

    % 3. Cálculo do Ganho Kc (Condição de Módulo)
    Gcz_base = tf([1 -zc], [1 -pc], T);
    num_total = conv(Gz.num{1}, Gcz_base.num{1});
    den_total = conv(Gz.den{1}, Gcz_base.den{1});
    mag = abs(polyval(num_total, zd) / polyval(den_total, zd));

    Kc = 1 / mag;
    Gcz = Kc * Gcz_base;

    % Output info para o log
    info.label = "Avanço de Fase via LGR";
    info.zd = zd;
    info.pc = pc;
    info.zc = zc;
    info.Kc = Kc;
    info.wn = wn;
end
