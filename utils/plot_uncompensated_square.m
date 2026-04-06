function plot_uncompensated_square(Gs, Gz, T, save_path)
    t_cont = 0:0.001:20;
    t_disc = 0:T:20;
    ref_cont = 1.6 * square(2 * pi * 0.1 * t_cont);
    ref_disc = 1.6 * square(2 * pi * 0.1 * t_disc);
    y_cont = lsim(Gs, ref_cont, t_cont);
    y_disc = lsim(Gz, ref_disc, t_disc);

    figure('Name', 'Uncompensated Square Response');
    subplot(1,2,1);
    plot(t_cont, ref_cont, 'k--', t_cont, y_cont, 'b', 'LineWidth', 1.2);
    grid on;
    title('Square - s domain');
    xlabel('Tempo (s)');
    ylabel('Saída');
    legend('Ref', 'y');

    subplot(1,2,2);
    stairs(t_disc, ref_disc, 'k--');
    hold on;
    stairs(t_disc, y_disc, 'r', 'LineWidth', 1.2);
    grid on;
    title('Square - z domain');
    xlabel('Tempo (s)');
    ylabel('Saída');
    legend('Ref', 'y');

    saveas(gcf, save_path, 'png');
    close(gcf);
end