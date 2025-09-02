function[xyzUserPosition] = lla2ecef(llaUserPosition)

    for idx=1:size(llaUserPosition,1)
        lat=deg2rad(llaUserPosition(idx,1));
        long=deg2rad(llaUserPosition(idx,2));
        h=llaUserPosition(idx,3);
        
        a = 6378137;
        e = sqrt(0.00669437999014);
        % c = e*a; % UNUSED, NO SE PORQUE
        % b = sqrt(a^2-c^2); % UNUSED, NO SE PORQUE
        
        x=(a/(sqrt(1-e^2*sin(lat)^2))+h)*cos(lat)*cos(long);
        y=(a/(sqrt(1-e^2*sin(lat)^2))+h)*cos(lat)*sin(long);
        z=(a*(1-e^2)/(sqrt(1-e^2*sin(lat)^2))+h)*sin(lat);
        
        xyzUserPosition(idx,:)=[x, y, z];
    end
end