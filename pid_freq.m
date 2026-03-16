clear; clc; close all;
pkg load control;
pkg load signal;

% Adicionar subpastas ao caminho (se necessário)
addpath('designers'); addpath('utils');

% --- CONFIGURAÇÕES GERAIS ---
T = 0.02;
K_plant = 1.0836;
tau_plant = 0.0088;

s = tf('s');
Gs = K_plant / (s * (tau_plant * s + 1));
Gz = c2d(Gs, T, 'zoh');

% --- REQUISITOS ---

% Condições do roteiro
req.Mp = 4; % Sobressinal 4%
req.tp = 0.5; % Tempo de pico 0.5(s)

% Condições para não saturar
req.Mp = 4.1; % Sobressinal 4%
req.tp = 0.61; % Tempo de pico 0.5(s)

req.ts = 2.0;  % Tempo de assentamento (s) - para o Atraso
req.Vs = 10.0; % Tensão de saturação

% --- SELEÇÃO DO COMPENSADOR ---
%[Gcz_lead, info_lead] = design_lead_lgr(Gz, T, tau_plant, req);
%[Gcz_lead, info_lead] = design_lead_lgr2(Gz, T, req);

% Projeto 2: PID (Resposta em Frequência)
[Gcz_pid, info_pid] = design_pid_freq(Gz, T, req);

% Planta projetada no papel
%b0=1.46;zero=0.103;polo=0.764;lead_num = [b0 -b0*zero];lead_den = [1 -polo];
%[Gcz_lead, info_lead] = design_custom(lead_num, lead_den, T, 'Avanço de Fase Ajustado via LGR'); % Novo (Otimizado)

% 4. Validação de Performance (Gráficos temporais e métricas)
analyze_performance(Gz, Gcz_pid, T, req, info_pid.label);

% 5. Validação de Estabilidade (Mapas de Polos e Zeros)
plot_pzmaps(Gz, Gcz_pid, info_pid.label);

% 6. Simulações Periódicas (Onda Quadrada e Triangular)
simulate_square(Gz, Gcz_pid, T, info_pid.label);

simulate_triangle(Gz, Gcz_pid, T, info_pid.label);
