function plant = build_plant_for_embedded(K_plant, tau_plant, T)
    % Orchestrates plant transformations for control design and firmware use.

    [Gs, Gz] = transform_plant_to_discrete(K_plant, tau_plant, T, 'zoh');
    [Gw, w_info] = transform_plant_to_wplane(Gz, T);
    emb = plant_to_embedded_coeffs(Gz);

    plant.Gs = Gs;
    plant.Gz = Gz;
    plant.Gw = Gw;
    plant.embedded = emb;
    plant.w_info = w_info;
end
