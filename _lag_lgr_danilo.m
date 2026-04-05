% Aula - Projeto pelo lugar das raizes

% Compensador atraso de fase

% Octave



clear

close all

clc



pkg load control

pkg load signal

format long



% Sistema continuo

ns = 1.0836; %K aqui

ds = [0.0088 1 0]; %tau no lugar do 0.0088

% Periodo de amostragem

T = 0.02;

%ns = 1.4388; %K aqui

%ds = [0.0212 1 0]; %tau no lugar do 0.0088

%T = 0.002;

Gs = tf(ns,ds)


% FTP do sistema

Gz =(c2d(Gs,T))



% Mostrando os valores dos polos, zeros e ganho

[z, p, k] = tf2zp(Gz.num{1}, Gz.den{1})



% Calculemos o valor de Kv para o sistema sem

% compensacao

% Kv=lim  (z-1)  1.6542e-05 (z+3.704) (z+0.2659)

%        z->1 -----  --------------------------------

%                  T z       (z-1)(z-0.99) (z-0.9802)

Gz_auxi = zpk(z,p(2,1),k/T,T)

% Gz_auxi e' FTP com o polo em 1, cancelado

%Avaliando o polinomio do numerador

nkv = polyval(Gz_auxi.num{1},1)

%Avaliando o polinomio do denominador

dkv = polyval(Gz_auxi.den{1},1)

%Calculando o valor da Kv

Kv = nkv/dkv



% FTP em MF do sistema sem controle

Gz_mf = zpk(feedback(Gz,1))

% Obtemos zeros, polos e ganho da FTPMF

[zmf, pmf, kmf] = tf2zp(Gz_mf.num{1}, Gz_mf.den{1})



% Dados polos dominantes

% Obtemos a parte imaginaria e real do polo complexo

w1 = imag(pmf(1))

s1 = real(pmf(1))

% Escolhemos o valor de theta = -3?

t1 = tan(-3/180*pi)



% Escolha do polo do compensador por atraso de fase

pc = 0.99995;



% Zero do compensador

zc = (t1*(s1^2 + w1^2)-t1*s1*pc+w1*pc)/(t1*(s1-pc)+w1)



% Num e den do compensador

ncz = [1 -zc]

dcz = [1 -pc]



% FTP do compensador

Gcz = tf(ncz,dcz,T)



% FTP em MA do sistema compensado

Gz_ma_cc = series(Gz,Gcz)

% Obtemos zeros, polos e ganho da FTPMF do

% sistema compensado

[zma_cc, pma_cc, kma_cc] = tf2zp(Gz_ma_cc.num{1}, Gz_ma_cc.den{1})



% Calculemos o valor de Kv

% Kv=lim  (z-1)*(z - 0.999565)1.6542e-05 (z+3.704) (z+0.2659)

%        z->1 -------------------------------------

%                  T z  (z - 0.99995)(z-1)(z-0.99) (z-0.9802)

% Gz_ma_cc_auxi e' a FTP em MA com polo em 1 cancelado

Gz_ma_cc_auxi = zpk(zma_cc,pma_cc(2:3,1),kma_cc/T)

%Avaliando o polinomio do numerador

nkv_cc = polyval(Gz_ma_cc_auxi.num{1},1)

%Avaliando o polinomio do denominador

dkv_cc = polyval(Gz_ma_cc_auxi.den{1},1)

%Calculando o valor da Kv do sistema compensado

Kv_cc = nkv_cc/dkv_cc

% Calculamos o valor do ganho K para satisfazer Kv

K = 5/Kv_cc



figure(1)

hold on;

rlocus(Gz);

rlocus(K*Gz_ma_cc);

axis([-10 2 -6 6]);

axis square;

hold off;

legend("off");

title('LGR para T=0,01 sem e com compensação');

xlabel('Eixo real');

ylabel('Eixo imaginário');

%% size_font;

box on;

print('figura_lgr_1.png', '-dpng', '-S820,820');

%%saveas(1, "figura_lgr_1.png");



% FTP em MA sistema compensado e ganho ajustado

Gz_ma_cc = K*series(Gz,Gcz)

% FTP em MF do sistema compensado e ganho ajustado

Gz_mf_cc = feedback(Gz_ma_cc,1)



% Simulação

tfs = 80;

nn = tfs/T;

t = 0:T:T*nn;



figure(2)

hold on;

[y, t, x] = step (Gz_mf, t); % Dados resposta degrau sem compensa

[yc, t, xc] = step (Gz_mf_cc, t); % Dados resposta degrau com compensa

plot(t,y,"r",t,yc,"b")

legend({"Sem compensador","Com compensador"});

axis([0 80 0 1.4]);

axis square;

% % size_font;

box on;

grid;

title('Resposta ao degrau T=0.01');

xlabel('Tempo');

ylabel('Amplitude');

print('figura_step_1.png', '-dpng', '-S820,820');



% Simulação rampa unitária

% Obtemos as respostas a uma emtrada rampa

% com o comando lsim

t = 0:T:T*nn; % Vetor do tempo a intervalos de amostragem

[y1, t1,x1] = lsim(Gz_mf,t);

[y2,t2,x2] = lsim(Gz_mf_cc,t);



figure(3)

hold on;

h1 = stairs(t,y1,'b');

h2 = stairs(t,y2,'r');

h3 = line([0,tfs],[0,tfs],'Color',[0 0 0]);

xlabel('Tempo');

legend('Sem comp.','Com comp.','Ramps','Location','NorthWest');

box on;

grid;

set([h1 h2 h3],'LineWidth',2);

% size_font;

axis([0 80 0 80]);

axis square;

hold off;

title('Resposta a rampa T=0.01 e_{ss}=0.2 K_v=5');

print('figura_rampa_1.png', '-dpng', '-S820,820');



% Simulação esforço de controle

rr = ones(nn+1,1); % Sinal de referencia

ee = rr - yc; % Diferença entre ref e saida compensada

[y3,t3,x3] = lsim(K*Gcz,ee);



%t = 0:T:T*nn;

figure(4)

h1 = plot(t3,y3);

xlabel('Tempo');

ylabel('Amplitude');

title('Esforco de controle')

%%set([h1],'LineWidth',3);

% size_font;

grid;

axis([0 80 -0.5 1.5]);

axis square;



print('figura_controle_1.png', '-dpng', '-S820,820');
