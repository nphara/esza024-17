function [Gcz, info] = design_lead_lgr(Gz, T, req)

  % 1. Extração e Normalização dos Requisitos
  Mp = req.Mp / 100;    % Converte de 4 para 0.04
  tp = req.tp;          % 0.5 s

  % 2. Cálculo dos Parâmetros de Segunda Ordem (Domínio Contínuo)
  % Conforme Ogata (Referência do roteiro da Semana 4)
  zeta = -log(Mp) / sqrt(pi^2 + (log(Mp))^2);
  wn = pi / (tp * sqrt(1 - zeta^2));

  % 3. Localização do Polo Dominante no Plano S
  sigma_d = zeta * wn;
  wd = wn * sqrt(1 - zeta^2);
  sd = -sigma_d + 1i*wd; % Polo complexo desejado

  % 4. Mapeamento para o Plano Z (Crucial para o LGR Discreto)
  % Nota: T deve ser o período de amostragem vindo da planta ou global
  zd = exp(sd * T);

  % Exibe o ponto alvo para o Root Locus no console
  fprintf('Alvo do LGR (zd): %.4f + %.4fi\n', real(zd), imag(zd));

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

  % 1. Extração dos coeficientes dos polinômios da planta
  [num_p, den_p] = tfdata(Gz, 'v');

  % 2. Avaliação direta dos polinômios no ponto complexo zd usando polyval
  val_num = polyval(num_p, zd);
  val_den = polyval(den_p, zd);

  % 3. Valor da planta Gz no ponto zd
  val_Gz = val_num / val_den;

  % 4. Avaliação do compensador (sem o ganho Kc) no ponto zd
  val_Gc_base = (zd - zc) / (zd - pc);

  % 5. Cálculo do Ganho Kc pela condição de módulo: |Kc * Gc_base * Gz| = 1 em zd
  Kc = 1 / abs(val_Gc_base * val_Gz);

  % 6. Definição do controlador final
  Gcz = Kc * tf([1 -zc], [1 -pc], T);

  % Output info para o log
  info.label = "Avanço de Fase via LGR";
  info.zd = zd;
  info.pc = pc;
  info.zc = zc;
  info.Kc = Kc;
  info.wn = wn;
end
