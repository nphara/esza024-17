function plot_pzmaps(Gz, Gcz, label)
    % Sistema em Malha Aberta Compensada
    Gma_comp = Gcz * Gz;
    
    figure('Name', ['Mapas de Polos e Zeros - ', label]);
    
    % --- Subplot 1: Sistema Original ---
    subplot(1,2,1);
    pzmap(Gz);
    grid on; title('Original: G(z)');
    
    % Ajuste do domínio dos eixos para [-1.5, 1.5]
    axis([-1.5 1.5 -1.5 1.5]); 
    axis square; % Garante que o círculo unitário não fique oval
    hold on;
    
    % Círculo unitário (referência de estabilidade)
    t = linspace(0, 2*pi, 100);
    plot(cos(t), sin(t), 'k--', 'LineWidth', 1);
    
    % Legenda interna com fonte e marcadores reduzidos
    [h_leg, h_obj] = legend({'Polos', 'Zeros'}, ...
           'Location', 'northeast', ... % 'northeast' coloca dentro (topo-direita)
           'FontSize', 7, ...
           'Box', 'on'); % Box 'on' ajuda na leitura se sobreposto ao grid
    
    % Reduzir o tamanho do "X" e "O" na legenda
    set(findobj(h_obj, 'type', 'line'), 'MarkerSize', 1); 
    xlabel('Real'); ylabel('Imaginário');

    % --- Subplot 2: Sistema Compensado ---
    subplot(1,2,2);
    pzmap(Gma_comp);
    grid on; title(['Compensado: Gc(z)G(z)']);
    
    % Ajuste do domínio dos eixos para [-1.5, 1.5]
    axis([-1.5 1.5 -1.5 1.5]); 
    axis square; 
    hold on;
    
    plot(cos(t), sin(t), 'k--', 'LineWidth', 1);
    
    % Legenda idêntica para o segundo gráfico
    [h_leg2, h_obj2] = legend({'Polos', 'Zeros'}, ...
           'Location', 'northeast', ...
           'FontSize', 7, ...
           'Box', 'on');
           
    set(findobj(h_obj2, 'type', 'line'), 'MarkerSize', 1); 
    
    xlabel('Real'); ylabel('Imaginário');
end