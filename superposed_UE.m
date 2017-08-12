function u = superposed_UE(dimension, poi, p, R)

%dimension determines the height and width of the field which starts from
%0,0
%poi is an array of n*2 which determines the list of points of interest
%p is the probability of u being independent and standalone
%R is the radius of clusters
%u is the location of new user generated

if rand < p
    u(1,1:2) = unifrnd(0,dimension,1,2);
else
    att = 1+floor(rand*size(poi,1));
    if att == size(poi,1)+1
        att = att-1;
    end
    r = rand*R;
    theta = rand*2*pi;
    u(1,1) = min(max(r*cos(theta)+poi(att,1),0),dimension);
    u(1,2) = min(max(r*sin(theta)+poi(att,2),0),dimension);    
end