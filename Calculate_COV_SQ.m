function [COV]=Calculate_COV_SQ(points_cordinates,Win,Ep)


%     global g_user_dist uts g_interSiteDistance g_cellRadius g_cellheight COV COVsqrt xv yv
    
%     d=g_interSiteDistance;
%     r=g_cellRadius;
%     h=g_cellheight;
%     area_size_y = 10*h;
%     area_size_x = 8*r;
    
    %figure(g_user_dist);

    %voronoi(uts(:,1),uts(:,2));
    
    %axis([-area_size_x/2 area_size_x/2 -area_size_y/2 area_size_y/2]);
%     global rx ry 
if nargin < 2
    Win=[0 1000 0 1000]; % 2x2 Matrix
end
 
   rx = [Win(1) Win(2) Win(2) Win(1) Win(1)]; %   rx = [0 1000 1000 0 0]';
ry = [Win(3) Win(3) Win(4) Win(4) Win(3)]; %   ry = [0 0 1000 1000 0]';

   Xu=points_cordinates;
    
% Note: we calculate the COV over slighlty larger region (e.g %5 larger) than the study
% region in order to avoid the edge effect and get more accuret COV. 
% rxp = [-50 1050 1050 -50 -50];
% ryp = [-50 -50 1050 1050 -50];
 if nargin < 3
    Ep=1; % persentage of the extra study region   
 end

if Ep >=1
    
    in = inpolygon(Xu(:,1),Xu(:,2),Ep*rx,Ep*ry);
    Xu=Xu(in,:);
     minx = min(rx); maxx = max(rx);

  miny = min(ry); maxy = max(ry);
else
    in = inpolygon(Xu(:,1),Xu(:,2),rx,ry);
    Xu=Xu(in,:);
    
   minx = min(Ep*rx); maxx = max(Ep*rx);

  miny = min(Ep*ry); maxy = max(Ep*ry);
end



%  minx = min(rx); maxx = max(rx);
% 
%   miny = min(ry); maxy = max(ry);

 
 
    [v, c] = voronoin(Xu);
%     Index= find( 
    
%     for i = 1 : size(c ,1)
%         ind = c{i}';
%         if any(v(ind,1) > area_size_x/2) || any(v(ind,1) < -area_size_x/2) || any(v(ind,2) > area_size_y/2) || any(v(ind,2) < -area_size_y/2)
%            tess_area(i) = Inf;
%         else
%            tess_area(i) = polyarea( v(ind,1), v(ind,2));
%         end
%     end
L=size(c ,1);
Tess_area=zeros(1,L);

    for i = 1 : L
        ind = c{i}';
%          if any(inpolygon(v(ind,1),v(ind,2),rx,ry)==0) 
            if any(v(ind,1) > maxx) || any(v(ind,1) < minx) ...
                    || any(v(ind,2) > maxy) || any(v(ind,2) < miny) % take less time than using inpolygon function by afactor of 2.8 to 12 depending on the number of users. 
                Tess_area(i) = Inf;
            else
                Tess_area(i) = polyarea( v(ind,1), v(ind,2));
            end
    end
    
    
    areas = Tess_area(isfinite(Tess_area));
       
    

    
%     areassqrt = sqrt(areas);
    
    COV = std(areas)/mean(areas)/0.5293;
    
%     COVsqrt = std(areassqrt)/mean(areassqrt);

%     if isnan(COV)
%         COV=0;
%     end
    
    
end


% I dnon't need this condition because it's already guranteed from the begining