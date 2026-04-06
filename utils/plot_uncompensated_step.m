function plot_uncompensated_step(Gs, Gz, T, save_path)
    t_cont = 0:0.001:2.0;
    t_disc = 0:T:2.0;
    y_cont = step(Gs, t_cont);
    y_disc = step(Gz, t_disc);

    figure('Name', 'Uncompensated Step Response');
    subplot(1,2,1);
    plot(t_cont, y_cont, 'b', 'LineWidth', 1.5);
    grid on;
    title('Step Response - s domain');
    xlabel('Tempo (s)');
    ylabel('Saída');

    subplot(1,2,2);
    stairs(t_disc, y_disc, 'r', 'LineWidth', 1.5);
    grid on;
    title('Step Response - z domain');
    xlabel('Tempo (s)');
    ylabel('Saída');

    saveas(gcf, save_path, 'png');
    close(gcf);
end