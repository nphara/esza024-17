function [Gcz, info] = design_custom(num, den, T, label)
    % Cria a função de transferência do controlador a partir dos vetores
    % num = [b0, b1, b2...]
    % den = [1, a1, a2...]

    Gcz = tf(num, den, T);

    info.label = ['Custom: ', label];
    info.num = num;
    info.den = den;

    fprintf('\n--- Controlador Customizado Carregado ---\n');
    disp(Gcz);
end
