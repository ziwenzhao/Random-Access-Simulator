function [clusterno,clusterlist,member,centroid,sizeofcluster,clusterattach]=hclustering(coordinate,~,minclusterdistance)
%clusterno -- # of cluster
%clusterlist -- the sequential number (S.N.) list of current existing cluster
%member -- member(listed using the S.N. of each node) of each cluster(using the fixed cluster S.N.)
%sizeofcluster -- # of nodes in each cluster
%clusterattach -- each node belong to which cluster
%coordinate -- the input of coordinate of all nodes
%nocl -- the intended # of cluster (might not be used depends on the stopping condition)

%Initiallly assign each point as a cluster

pointno=size(coordinate,1);
clusterno=pointno;
clusterattach=1:pointno;
maxclustersn=pointno;
clusterlist=(1:clusterno)';

member=cell(1,2*pointno);

for i=1:clusterno
    member{i}=i;
end
%calculate all pair distance
%{
dcluster=zeros(clusterno,clusterno);
%}
dcluster=(sqdistance(coordinate',coordinate')).^0.5;
%{
for i=1:clusterno
    for j=1:clusterno
        dcluster(i,j)=pdist([coordinate(i,:);coordinate(j,:)]);
    end
end
%}
        
%find the closest cluster pair

dcluster=dcluster-diag(diag(dcluster));
dcluster(dcluster==0)=nan;
[r,c]=find(dcluster==min(dcluster(:)));
closestpair=[r(1),c(1)];


%merge the closestpair
clusterlist(closestpair)=[];
member{maxclustersn+1}=closestpair;
clusterlist=[clusterlist;maxclustersn+1];
clusterattach(closestpair)=maxclustersn+1;
clusterno=clusterno-1;
maxclustersn=maxclustersn+1;
dcluster=dcluster([1:c(1)-1,c(1)+1:r(1)-1,r(1)+1:end],:);
dcluster=dcluster(:,[1:c(1)-1,c(1)+1:r(1)-1,r(1)+1:end]);
%{
dcluster(closestpair,:)=[];
dcluster(:,closestpair)=[];
%}
%calculate centroid of each cluster
centroid=zeros(clusterno,2);
for i=1:clusterno
    centroid(i,:)=[mean(coordinate(member{clusterlist(i)},1)),mean(coordinate(member{clusterlist(i)},2))];
end

%compute distance between new cluster and all the old clusters
dcluster(clusterno,1:clusterno)=(sqdistance(centroid(clusterno,:)',centroid')).^0.5;
dcluster(1:clusterno,clusterno)=(sqdistance(centroid(clusterno,:)',centroid')).^0.5;
%{
for i=1:clusterno
    dcluster(clusterno,i)=pdist([centroid(i,:);centroid(clusterno,:)]);
    dcluster(i,clusterno)=dcluster(clusterno,i);
end
%}
dcluster(clusterno,clusterno)=nan;

%iteration:find the closest pair, merge them and compute distance between
%new cluster and all others
%stopping condition: minimum cluster distance larger than 35
while(min(dcluster(:))<minclusterdistance)
    %find closest cluster pair
    [r,c]=find(dcluster==min(dcluster(:)));
    closestpair=[r(1),c(1)];
    %merge them
    member{maxclustersn+1}=[member{clusterlist(r(1))},member{clusterlist(c(1))}];
    maxclustersn=maxclustersn+1;
    clusterlist(closestpair)=[];
    clusterlist=[clusterlist;maxclustersn];
    clusterattach(member{maxclustersn})=maxclustersn;
    clusterno=clusterno-1;
    dcluster=dcluster([1:c(1)-1,c(1)+1:r(1)-1,r(1)+1:end],:);
    dcluster=dcluster(:,[1:c(1)-1,c(1)+1:r(1)-1,r(1)+1:end]);
    
    centroid(closestpair,:)=[];
    centroid(clusterno,:)=[mean(coordinate(member{clusterlist(clusterno)},1)),mean(coordinate(member{clusterlist(clusterno)},2))];
    
    %calculate distance between new cluster and all other old clusters
dcluster(clusterno,1:clusterno)=(sqdistance(centroid(clusterno,:)',centroid')).^0.5;
dcluster(1:clusterno,clusterno)=(sqdistance(centroid(clusterno,:)',centroid')).^0.5;
%{
for i=1:clusterno
    dcluster(clusterno,i)=pdist([centroid(i,:);centroid(clusterno,:)]);
    dcluster(i,clusterno)=dcluster(clusterno,i);
    end
    %}
    dcluster(clusterno,clusterno)=nan;
end
%get the size of each cluster
sizeofcluster=zeros(1,clusterno);
for i=1:clusterno
    sizeofcluster(i)=numel(member{clusterlist(i)});
end