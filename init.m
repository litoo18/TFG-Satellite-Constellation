function init()

% 1. Cerrar figuras relevantes
allFigs = findall(0, 'Type', 'figure');
for i = 1:length(allFigs)
    f = allFigs(i);
    if contains(f.Name, 'Satellite Scenario Viewer') || ...
       contains(f.Name, 'Selecciona Constelación Satelital')
        close(f)
    end
end

% 2. Eliminar todos los ficheros .tle del directorio raíz,
% excepto los fijos que viven en tle_data/
tleFiles = dir("*.tle");
for k = 1:length(tleFiles)
    file = tleFiles(k).name;
    delete(file);  % eliminar todo
end

% 3. Limpiar entorno
close all
clear all
clc

end
