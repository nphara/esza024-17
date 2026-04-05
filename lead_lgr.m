clear; clc; close all;
pkg load control;
pkg load signal;

% Adicionar subpastas ao caminho (se necessário)
addpath('designers'); addpath('utils');

% PLANTA DO SISTEMA %
%===================%

sys(1).T = 0.002;
sys(1).K_plant = 1.0836;
sys(1).tau_plant = 0.0088;


sys(2).K_plant = 1.4388;
sys(2).tau_plant = 0.0212;
sys(2).T = sys(2).tau_plant/10;

plant = 2

T = sys(plant).T
K_plant = sys(plant).K_plant
tau_plant = sys(plant).tau_plant

s = tf('s');
Gs = K_plant / (s * (tau_plant * s + 1));
Gz = c2d(Gs, T, 'zoh');


% REQUISITOS %
%============%

% Condições do roteiro %
%----------------------%

req.Mp = 4; % Sobressinal 4%
req.tp = 0.5;   % Tempo de pico 0.5(s)

req.ts = 2.0;  % Tempo de assentamento (s) - para o Atraso
req.OutSat = 10.0; % Tensão de saturação

% ANALISE %
%=========%

% LGR %
%-----%

% Resposta em frequência %
%------------------------%

% PROJETO DO CONTROLADOR %
%========================%


% Geração Automatica %
%--------------------%

[Gcz_lead, info_lead] = design_lead_lgr2(Gz, T, req);



% Planta Customizada %
%--------------------%

%b0=1.46;zero=0.103;polo=0.764;lead_num = [b0 -b0*zero];lead_den = [1 -polo];
%[Gcz_lead, info_lead] = design_custom(lead_num, lead_den, T, 'Avanço de Fase Ajustado via LGR'); % Novo (Otimizado)


%   RESULTADOS   %
%================%

% 4. Validação de Performance (Gráficos temporais e métricas)
analyze_performance(Gz, Gcz_lead, T, req, info_lead.label);

% 5. Validação de Estabilidade (Mapas de Polos e Zeros)
plot_pzmaps(Gz, Gcz_lead, info_lead.label);

% 6. Simulações Periódicas (Onda Quadrada e Triangular)
simulate_square(Gz, Gcz_lead, T, info_lead.label, req.OutSat);

simulate_triangle(Gz, Gcz_lead, T, info_lead.label, req.OutSat);
