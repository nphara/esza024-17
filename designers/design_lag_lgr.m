function [Gcz, info] = design_lag_lgr(Gz, T, req)
    % design_lag_lgr - Simple lag compensator design by root locus.
    %
    % This version keeps a single design branch and uses a fixed lag pair
    % near z = 1. It is intentionally simpler than the lead workflow.

    if ~isfield(req, 'Mp'), req.Mp = 8; end
    if ~isfield(req, 'ts'), req.ts = 2.0; end
    if ~isfield(req, 'OutSat'), req.OutSat = 10.0; end

    Mp = req.Mp / 100;
    zeta = -log(Mp) / sqrt(pi^2 + (log(Mp))^2);
    wn = 4 / (zeta * req.ts);

    sd = -zeta * wn + 1i * wn * sqrt(1 - zeta^2);
    zd = exp(sd * T);

    % Lag pair: pole closer to z=1 than zero.
    % The values below follow the handwritten design idea, but with lag order.
    zc = 0.8205;
    pc = 0.9800;

    [num_p, den_p] = tfdata(Gz, 'v');
    val_Gz = polyval(num_p, zd) / polyval(den_p, zd);
    val_Gc_base = (zd - zc) / (zd - pc);
    Kc = 1 / abs(val_Gc_base * val_Gz);

    Gcz = Kc * tf([1 -zc], [1 -pc], T);

    FTMF = feedback(Gcz * Gz, 1);
    FT_ctrl = feedback(Gcz, Gz);

    t_eval = 0:T:max(3.0, 4 * req.ts);
    [y, ~] = step(FTMF, t_eval);

    y_end = y(end);
    y_max = max(y);
    Mp_meas = ((y_max - y_end) / abs(y_end)) * 100;
    if Mp_meas < 0
        Mp_meas = 0;
    end

    [~, idx_pk] = max(y);
    tp_meas = t_eval(idx_pk);
    if Mp_meas <= 0.1 || idx_pk == numel(y)
        tp_meas = NaN;
    end

    ts_meas = local_settling_time(y, t_eval, y_end, 0.02);

    u = lsim(FT_ctrl, ones(size(t_eval)), t_eval);
    u_max = max(abs(u));

    info.label = 'Atraso de Fase via LGR';
    info.type = 'lag';
    info.mode = 'lag';
    info.zd = zd;
    info.zc = zc;
    info.pc = pc;
    info.Kc = Kc;
    info.wn = wn;
    info.found = true;
    info.metrics = struct('Mp', Mp_meas, 'tp', tp_meas, 'ts', ts_meas, 'u_max', u_max);

    fprintf('\n========== DESIGNER: Lag-LGR ==========\n');
    fprintf('Alvo do LGR (zd): %.4f + %.4fi\n', real(zd), imag(zd));
    fprintf('Compensador projetado: zc=%.4f, pc=%.4f\n', zc, pc);
    fprintf('Kc=%.4f\n', Kc);
    fprintf('Mp=%.2f%% | tp=%s | ts=%.3fs | u_max=%.2fV\n', ...
        Mp_meas, local_fmt_tp(tp_meas), ts_meas, u_max);
end

function ts = local_settling_time(y, t, y_final, band_ratio)
    band = band_ratio * max(abs(y_final), 1e-12);
    idx = find(abs(y - y_final) > band, 1, 'last');
    if isempty(idx)
        ts = 0;
    elseif idx >= numel(t)
        ts = t(end);
    else
        ts = t(idx + 1);
    end
end

function out = local_fmt_tp(tp)
    if isnan(tp)
        out = 'N/A';
    else
        out = sprintf('%.3fs', tp);
    end
end