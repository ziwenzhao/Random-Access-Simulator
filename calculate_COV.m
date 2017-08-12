function calculate_COV()

    global g_user_dist uts g_interSiteDistance g_cellRadius g_cellheight COV COVsqrt xv yv
    
    d=g_interSiteDistance;
    r=g_cellRadius;
    h=g_cellheight;
    area_size_y = 10*h;
    area_size_x = 8*r;
    
    %figure(g_user_dist);

    %voronoi(uts(:,1),uts(:,2));
    
    %axis([-area_size_x/2 area_size_x/2 -area_size_y/2 area_size_y/2]);
 
    
    [v, c] = voronoin(uts);
    
%     for i = 1 : size(c ,1)
%         ind = c{i}';
%         if any(v(ind,1) > area_size_x/2) || any(v(ind,1) < -area_size_x/2) || any(v(ind,2) > area_size_y/2) || any(v(ind,2) < -area_size_y/2)
%            tess_area(i) = Inf;
%         else
%            tess_area(i) = polyarea( v(ind,1), v(ind,2));
%         end
%     end
    for i = 1 : size(c ,1)
        ind = c{i}';
        if any(inpolygon(v(ind,1),v(ind,2),xv',yv')==0)
           tess_area(i) = Inf;
        else
           tess_area(i) = polyarea( v(ind,1), v(ind,2));
        end
    end
    
    
    areas = tess_area(isfinite(tess_area));
    
    
    sumarea = sum(areas);
    
    areassqrt = sqrt(areas);
    
    COV = std(areas)/mean(areas);
    COVsqrt = std(areassqrt)/mean(areassqrt);

    
    
end