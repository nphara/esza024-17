function [Gcz, info] = design_lead_lgr2(Gz, T, req, theta)
  
  % 1. Inputs and defaults (single analytic mode)
  if ~isfield(req, 'mode'), req.mode = "analytic"; end
  if ~isfield(req, 'OutSat'), req.OutSat = 10.0; end
  if ~isfield(req, 'Mp'), req.Mp = 8; end
  if ~isfield(req, 'tp') || ~isfinite(req.tp) || req.tp <= 0
      req.tp = NaN;
  end
  if ~isfield(req, 'ts') || ~isfinite(req.ts) || req.ts <= 0
      req.ts = NaN;
  end

  Mp = req.Mp / 100;
  zeta = -log(Mp) / sqrt(pi^2 + (log(Mp))^2);

  if isfinite(req.tp)
      wn = pi / (req.tp * sqrt(1 - zeta^2));
      t_ref = req.tp;
  elseif isfinite(req.ts)
      wn = 4 / (zeta * req.ts);
      t_ref = req.ts;
  else
      wn = 4 / (zeta * 1.0);
      t_ref = 1.0;
  end

  wd = wn * sqrt(1 - zeta^2);
  sd = -zeta * wn + 1i * wd;
  zd = exp(sd * T);

  fprintf('\n========== DESIGNER: Lead-LGR (analytic) ==========\n');
  fprintf('Alvo do LGR (zd): %.4f + %.4fi\n', real(zd), imag(zd));

  % 2. Analytic design (no grid / no scoring)
  [num_p, den_p] = tfdata(Gz, 'v');
  val_Gz = polyval(num_p, zd) / polyval(den_p, zd);

  if isfield(req, 'zc_manual') && isfinite(req.zc_manual)
      zc = req.zc_manual;
  else
      zc = 0.90;
  end

  Delta = pi - angle(val_Gz);
  theta_p = angle(zd - zc) - Delta;
  pc = real(zd) - (imag(zd) / tan(theta_p));

  if ~isfinite(pc) || abs(pc) >= 0.999 || abs(zc) >= 0.999
      pc = 0.80;
      zc = 0.90;
      fprintf('⚠️  Solução analítica inválida; usando fallback simples zc=%.2f, pc=%.2f\n', zc, pc);
  end

  val_Gc_base = (zd - zc) / (zd - pc);
  Kc = 1 / abs(val_Gc_base * val_Gz);
  if ~isfinite(Kc) || Kc <= 0
      Kc = 1.0;
      fprintf('⚠️  Kc analítico inválido; usando fallback Kc=1.0\n');
  end

  % 3. Build controller and evaluate metrics
  Gcz = Kc * tf([1 -zc], [1 -pc], T);
  FTMF = feedback(Gcz * Gz, 1);
  FT_ctrl = feedback(Gcz, Gz);

  t_eval = 0:T:max(3.0, 4 * t_ref);
  [y, ~] = step(FTMF, t_eval);

  y_end = y(end);
  y_max = max(y);
  Mp_meas = ((y_max - y_end) / abs(y_end)) * 100;
  if Mp_meas < 0, Mp_meas = 0; end

  [~, idx_pk] = max(y);
  tp_meas = t_eval(idx_pk);
  if Mp_meas <= 0.1 || idx_pk == numel(y)
      tp_meas = NaN;
  end

  u = lsim(FT_ctrl, ones(size(t_eval)), t_eval);
  u_max_step = max(abs(u));

  [t_sat_sq, t_sat_tri, u_max_sq, u_max_tri] = compute_saturation_metrics(Gz, Gcz, T, req.OutSat);

  found = true;
  if Mp_meas > req.Mp
      found = false;
  end
  if isfinite(req.tp) && isfinite(tp_meas) && tp_meas > req.tp
      found = false;
  end
  if isfinite(req.ts)
      ts_meas = local_settling_time(y, t_eval, y_end, 0.02);
      if ts_meas > req.ts
          found = false;
      end
  end
  if u_max_step > 0.9 * req.OutSat || u_max_sq > 1.1 * req.OutSat || u_max_tri > 1.1 * req.OutSat || ...
     t_sat_sq > 0.05 || t_sat_tri > 0.02
      found = false;
  end

  if zc > pc
      structure = "lead-like";
  else
      structure = "lag-like";
  end

  info.label = "Compensador via LGR (analítico)";
  info.zd = zd;
  info.pc = pc;
  info.zc = zc;
  info.Kc = Kc;
  info.wn = wn;
  info.type = "lead";
  info.mode = "analytic";
  info.structure = structure;
  info.found = found;
  info.metrics = struct('Mp', Mp_meas, 'tp', tp_meas, ...
                        'u_max_step', u_max_step, ...
                        'u_max_sq', u_max_sq, ...
                        'u_max_tri', u_max_tri, ...
                        't_sat_sq', t_sat_sq, ...
                        't_sat_tri', t_sat_tri);
  info.gate_failures = struct('u_max_step', double(u_max_step > 0.9 * req.OutSat), ...
                              'u_max_sq', double(u_max_sq > 1.1 * req.OutSat), ...
                              'u_max_tri', double(u_max_tri > 1.1 * req.OutSat), ...
                              't_sat_sq', double(t_sat_sq > 0.05), ...
                              't_sat_tri', double(t_sat_tri > 0.02));
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
