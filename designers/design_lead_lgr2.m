function [Gcz, info] = design_lead_lgr(Gz, T, req)
    % ... (cálculo de zeta, wn e zd permanecem iguais) ...

    % 3. Determinação do Zero do Compensador (zc) - REVISADO
    polos_p = pole(Gz);
    zeros_p = zero(Gz);
    
    % Filtra polos que NÃO são o integrador (z=1)
    % Buscamos o polo em ~0.103 para cancelar
    p_estaveis = polos_p(abs(polos_p) < 0.95); 
    
    if isempty(p_estaveis)
        zc = 0.5; % Valor padrão caso não encontre polo lento
    else
        zc = max(p_estaveis); % Cancela o polo mais lento (exceto o integrador)
    end
    
    % 4. Condição de Ângulo - REVISADO
    ang_zeros = sum(angle(zd - zeros_p));
    ang_polos = sum(angle(zd - polos_p));
    ang_zc = angle(zd - zc);
    
    % Teoria: Ang(zd-zc) + Ang_zeros_p - Ang_polos_p - Ang(zd-pc) = -180
    phi_pc = ang_zc + ang_zeros - ang_polos + pi;
    
    % Localização de pc: zd = x + jy. tan(phi_pc) = y / (x - pc)
    pc = real(zd) - (imag(zd) / tan(phi_pc));
    
    % --- TRAVA DE SEGURANÇA ---
    if pc > 0.99 || pc < -0.99
        warning('O polo pc=%.2f resultaria em instabilidade. Ajustando para 0.9.', pc);
        pc = 0.9; 
    end

    % 5. Condição de Módulo para Kc
    % Calculamos Kc = 1 / |Gz(zd) * Gc_sem_Kc(zd)|
    num_val = polyval(Gz.num{1}, zd) * (zd - zc);
    den_val = polyval(Gz.den{1}, zd) * (zd - pc);
    Kc = abs(den_val / num_val);

    Gcz = Kc * Gcz_base;

    % Output info para o log
    info.label = "Avanço de Fase via LGR";
    info.zd = zd;
    info.pc = pc;
    info.zc = zc;
    info.Kc = Kc;
    info.wn = wn;
end