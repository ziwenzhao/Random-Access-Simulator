function u = het_UE(dimension, poi, p, R)

%dimension determines the height and width of the field which starts from
%0,0
%poi is an array of n*2 which determines the list of points of interest
%p is the probability of u being independent and standalone
%R is the radius of clusters
%u is the location of new user generated

if rand < p
    u(1,1:2) = unifrnd(0,dimension,1,2);
else
    poi_selection=randi(size(poi,1));
    r = rand*R;
    theta = rand*2*pi;
    u(1,1) = r*cos(theta)+poi(poi_selection,1);
    u(1,2) = r*sin(theta)+poi(poi_selection,2); 
    while(u(1,1)<0 || u(1,1)>dimension || u(1,2)<0 || u(1,2)>dimension)
        r = rand*R;
        theta = rand*2*pi;
        u(1,1) = r*cos(theta)+poi(poi_selection,1);
        u(1,2) = r*sin(theta)+poi(poi_selection,2); 
    end
end