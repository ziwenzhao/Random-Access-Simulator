function U=U_Hetnet_fix(dimension,device_no,nocl,p,R)
%dimension: size of space
%lambda:average # of points
%nocl: # of clusters
%p: probability of points being independent
%R: radius of clusters
U=zeros(device_no,2);
poi=unifrnd(0,dimension,nocl,2);
for i=1:device_no
    U(i,:)=het_UE(dimension, poi, p, R);
end