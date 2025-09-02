% Altitude to radius conversion
function r = alt2radius(alt)
    r = (alt + 6.378137) * 1e6;
end
