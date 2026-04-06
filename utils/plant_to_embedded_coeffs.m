function emb = plant_to_embedded_coeffs(Gz)
    % Converts discrete transfer function into normalized z^-1 coefficients
    % suitable for embedded difference-equation implementation.

    [num, den] = tfdata(Gz, 'v');

    % Normalize denominator leading term to 1.
    den = den / den(1);
    num = num / den(1);

    % Equalize polynomial lengths for a proper z^-1 form.
    n = max(length(den), length(num));
    den = [zeros(1, n - length(den)), den];
    num = [zeros(1, n - length(num)), num];

    % Convert from powers of z to powers of z^-1.
    den_zm1 = fliplr(den);
    num_zm1 = fliplr(num);

    emb.num_zm1 = num_zm1;
    emb.den_zm1 = den_zm1;

    % Difference equation format:
    % y[k] = -a1*y[k-1] - ... - an*y[k-n] + b0*u[k] + ... + bn*u[k-n]
    emb.a = den_zm1(2:end);
    emb.b = num_zm1;
    emb.order = length(emb.a);

    emb.equation = 'y[k] = -sum(a_i*y[k-i]) + sum(b_i*u[k-i])';
end
