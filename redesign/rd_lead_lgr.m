% Definição dos dois controladores
Gcz1 = tf([1.801 -0.1856], [1 -0.7244], T); % Antigo
Gcz2 = tf([1.320 -0.5940], [1 -0.7709], T); % Novo (Otimizado)

% Tempo e Referência (Onda Quadrada 1.6V)
t = 0:T:5;
ref = 1.6 * ones(size(t)); % Analisando apenas um degrau para clareza

% Resposta do Controle (u)
FT_ctrl1 = feedback(Gcz1, Gz);
FT_ctrl2 = feedback(Gcz2, Gz);

u1 = lsim(FT_ctrl1, ref, t);
u2 = lsim(FT_ctrl2, ref, t);

figure;
plot(t, u1, 'r--', 'LineWidth', 1); hold on;
plot(t, u2, 'b', 'LineWidth', 1.5);
line([0 5], [10 10], 'Color', 'k', 'LineStyle', ':');
grid on;
title('Comparação do Esforço de Controle (u)');
ylabel('Tensão (V)'); xlabel('Tempo (s)');
legend('Projeto 1 (Saturação em 13.1V)', 'Projeto 2 (Linear em 9.45V)', 'Limite Hardware');