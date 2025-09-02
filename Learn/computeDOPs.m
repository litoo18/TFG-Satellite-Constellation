function [allDOPs] = computeDOPs(xyzSatellites,xyzUserPosition, llaUserPosition, elev)

numUE=size(xyzUserPosition,1); numSAT=size(xyzSatellites,3); numTS=size(xyzSatellites,2);

%eachH = zeros(numUE,numSAT,4);
%allH=();
allDOPs=zeros(numTS,numUE,5);

for idxTS=1:numTS
    eachDOP=zeros(numUE,5);
    for idxUE=1:numUE
        H=zeros(numSAT,4); % Compute H matrix at each iteration, se podria hacer una función aqui de compute H
        % fprintf("Computing Matrix H number = %d\n",idxUE);
        for idxSAT=1:numSAT
            xr = xyzSatellites(1,idxTS,idxSAT)-xyzUserPosition(idxUE,1);
            yr = xyzSatellites(2,idxTS,idxSAT)-xyzUserPosition(idxUE,2);
            zr = xyzSatellites(3,idxTS,idxSAT)-xyzUserPosition(idxUE,3);
            ri = sqrt(xr^2+yr^2+zr^2);
            
            ax=xr/ri;
            ay=yr/ri;
            az=zr/ri;
            
            if elev(idxSAT,idxUE,idxTS) > 10
                H(idxSAT,:) = [ax, ay, az, 1];
            end
        end
        [HDOP, VDOP, PDOP, TDOP, GDOP] = DoP(H, llaUserPosition(idxUE,1), llaUserPosition(idxUE,2));
        % eachH(idxUE,:,:) = H; % Compute H for each UE at TS = 1, NO NEED TO SAVE IT
        eachDOP(idxUE,:) = [HDOP, VDOP, PDOP, TDOP, GDOP]; % Save DOPs for each UE at TS=1.
    end
    %allH % Compute H for each UE and TS, NO NEED TO SAVE IT
    allDOPs(idxTS,:,:) = eachDOP; % Save all DOPs for each UE and TS
end

    if (min(allDOPs)==1000)
       % fprintf("    No se ha encontrado ningun momento donde haya 4 satelites visibles para almenos 1 GS.\n");
    else
       % fprintf("    Computed DOPs satisfactorios\n");
    end

end