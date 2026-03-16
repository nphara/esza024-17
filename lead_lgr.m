clear; clc; close all;
pkg load control;
pkg load signal;

% Adicionar subpastas ao caminho (se necessário)
addpath('designers'); addpath('utils');

% --- CONFIGURAÇÕES GERAIS ---
T = 0.02;
K_plant = 1.0836;
tau_plant = 0.0088;
Gs = tf(K_plant, [tau_plant 1 0]);
Gz = c2d(Gs, T, 'zoh');

% --- REQUISITOS ---
%req.Mp = 3.5; % Sobressinal 4%
req.Mp = 4; % Sobressinal 4%
%req.tp = 0.48; % Tempo de pico 0.5(s)
req.tp = 0.5; % Tempo de pico 0.5(s)
req.ts = 2.0;  % Tempo de assentamento (s) - para o Atraso
req.Vs = 10.0; % Tensão de saturação

% --- SELEÇÃO DO COMPENSADOR ---
%[Gcz_lead, info_lead] = design_lead_lgr(Gz, T, tau_plant, req);
[Gcz_lead, info_lead] = design_lead_lgr2(Gz, T, req);
%b0=1.95;zero=0.2;polo=0.68;
%lead_num = [b0 -b0*zero]; % b0*z + b1
%lead_den = [1 -polo];   % z + a1
%[Gcz_lead, info_lead] = design_custom(lead_num, lead_den, T, 'Avanço de Fase Ajustado via LGR'); % Novo (Otimizado)

% 4. Validação de Performance (Gráficos temporais e métricas)
analyze_performance(Gz, Gcz_lead, T, req, info_lead.label);

% 5. Validação de Estabilidade (Mapas de Polos e Zeros)
plot_pzmaps(Gz, Gcz_lead, info_lead.label);

% 6. Simulações Periódicas (Onda Quadrada e Triangular)
simulate_square(Gz, Gcz_lead, T, info_lead.label);

simulate_triangle(Gz, Gcz_lead, T, info_lead.label);
