function [Gs, Gz] = transform_plant_to_discrete(K_plant, tau_plant, T, method)
    % Builds continuous plant and returns discrete model using selected method.
    if nargin < 4 || isempty(method)
        method = 'zoh';
    end

    s = tf('s');
    Gs = K_plant / (s * (tau_plant * s + 1));
    Gz = c2d(Gs, T, method);
end
