function [t_sat_sq, t_sat_tri, u_max_sq, u_max_tri] = compute_saturation_metrics(Gz, Gcz, T, OutSat)
    % Compute saturation metrics without creating figures
    % Used during candidate search in design_lead_lgr2.m
    
    FT_ctrl = feedback(Gcz, Gz);
    
    % Square wave metrics
    t_eval = 0:T:20;
    ref_sq = 1.6 * square(2 * pi * 0.1 * t_eval);
    u_sq = lsim(FT_ctrl, ref_sq, t_eval);
    u_max_sq = max(abs(u_sq));
    t_sat_sq = sum(abs(u_sq) > OutSat) * T;
    
    % Triangle wave metrics
    ref_tri = 1.6 * sawtooth(2 * pi * 0.1 * t_eval, 0.5);
    u_tri = lsim(FT_ctrl, ref_tri, t_eval);
    u_max_tri = max(abs(u_tri));
    t_sat_tri = sum(abs(u_tri) > OutSat) * T;
end
