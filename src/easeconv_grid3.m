function [column, row] = easeconv_grid3(latitude, longitude, resolution)

% WGS 84 / EASE-Grid 2.0 constants
Req = 6378137;
ecc = 0.0818191908426;

COS_PHI1 = cosd(30);
SIN_PHI1 = sind(30);

% -----------------------------
% GRID SIZE DEFINITIONS
% -----------------------------
switch resolution
    case 3.125
        cols = 11104; rows = 4672;
        CELL_m = 25025.2600081;

    case 6.25
        cols = 5552; rows = 2336;
        CELL_m = 25025.2600081;

    case 9
        cols = 3856; rows = 1624;
        CELL_m = 36032.22;

    case 12.5
        cols = 2776; rows = 1168;
        CELL_m = 25025.2600081;

    case 25
        cols = 1388; rows = 584;
        CELL_m = 25025.2600081;

    case 36
        cols = 964; rows = 406;
        CELL_m = 36032.22;

    otherwise
        error('Unsupported resolution: %g', resolution);
end

% Grid origin
r0 = (cols - 1) / 2;
s0 = (rows - 1) / 2;

% -----------------------------
% LONGITUDE NORMALIZATION
% -----------------------------
longitude = mod(longitude + 180, 360) - 180;

% Convert to radians
lam = pi * longitude / 180;
phi = pi * latitude / 180;

% -----------------------------
% EASE GRID PROJECTION
% -----------------------------
k0 = COS_PHI1 / sqrt(1 - ecc^2 * SIN_PHI1^2);

quPHI = (1 - ecc^2) .* ( ...
    (sin(phi) ./ (1 - ecc^2 .* sin(phi).^2)) ...
    - (1 / (2 * ecc)) .* log((1 - ecc .* sin(phi)) ./ (1 + ecc .* sin(phi))) ...
);

ics = Req .* k0 .* lam;
ips = Req .* quPHI ./ (2 * k0);

% Convert to grid indices
column = round(r0 + ics ./ CELL_m) + 1;
row    = round(s0 - ips ./ CELL_m) + 1;

% -----------------------------
% BOUNDARY CLIPPING
% -----------------------------
column(column > cols) = cols;
column(column < 1) = 1;

row(row > rows) = rows;
row(row < 1) = 1;

end