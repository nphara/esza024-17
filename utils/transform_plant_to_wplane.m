function [Gw, info] = transform_plant_to_wplane(Gz, T)
    % Maps discrete plant to bilinear w-plane representation.
    Gw = d2c(Gz, 'tustin');

    info.label = 'Bilinear w-plane map (Tustin)';
    info.T = T;
    info.mapping = 'w = (2/T) * (z-1)/(z+1)';
end
