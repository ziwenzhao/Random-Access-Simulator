%update the schemes of slotted ALOHA and recalcuate its power consumption
%adjust the minclusterdistance of hclustering
%add performance metrics of energy consumption
%add performance metrics of collision rate
%modify7----if collision not resolved then performance still counts instead of nan
%modify6----another access delay for slotted aloha is defined as from the
%first transmission to the last successful transmission
%modify5----all cluster reuse all slotted aloha resource. Take interference
%into consideration when doing slotted aloha transmission for each node to decide the success state.
%the channel model is from the reference paper "Radio Resource Allocation in LTE-Advanced Cellular Networks with M2M Communications"
%modify4----divide slotted Aloha resources for different clusters
%modify3----get the statistics of delay of each device's access
%modify2----the resources for slot aloha is borrowed from RACH. Considering
%configuration 6, two access subframes per frame. One for slot aloha, the
%other one for RACH. Also Assume the one slot-aloha-resource is fully
%resued in every massive cluster.
clear all; close all;
%generate traffic pattern

%% 
loop=1;
R_sample=10:1:300;
sample_no=numel(R_sample);
COV=zeros(1,sample_no);
device_no=zeros(1,sample_no);
transmission_times_total=zeros(1,sample_no);
average_access_delay_cluster=zeros(1,sample_no);
collision_cluster_rate=zeros(1,sample_no);
success_cluster_rate=zeros(1,sample_no);
EC_slot_aloha_sum=zeros(1,sample_no);
EC_RACH_sum=zeros(1,sample_no);
EC_cluster_sum=zeros(1,sample_no);
run_time=10;
for R=R_sample
    COV_run=zeros(1,run_time);
    device_no_run=zeros(1,run_time);
    transmission_times_total_run=zeros(1,run_time);
    average_access_delay_cluster_run=zeros(1,run_time);
    collision_cluster_rate_run=zeros(1,run_time);
    success_cluster_rate_run=zeros(1,run_time);
    EC_slot_aloha_sum_run=zeros(1,run_time);
    EC_RACH_sum_run=zeros(1,run_time);
    EC_sum_run=zeros(1,run_time);
    
    for run=1:run_time
   dimension=1000;
  RACH_interval=100;
p=0.01;

nocl=50;
lambda=2000;
coordinate=U_Hetnet_fix(dimension,lambda,nocl,p,R);
win=[0,dimension,0,dimension];
COV_run(run)=Calculate_COV_SQ(coordinate,win);
device_no_run(run)=size(coordinate,1);

%cluster 
minclusterdistance=2*R;h_nocl=nan;
[clusterno,clusterlist,member,centroid,sizeofcluster,clusterattach]=hclustering(coordinate,h_nocl,minclusterdistance);

%draw figure
%{
scatter(coordinate(:,1),coordinate(:,2),'k.');
hold on;
scatter(centroid(:,1),centroid(:,2),'r.');
for i=1:clusterno
    for j=member{clusterlist(i)}
        line([coordinate(j,1),centroid(i,1)],[coordinate(j,2),centroid(i,2)],'Color','k');
    end
end
%}
%classify small cluster and massive cluster
small_cluster=find(sizeofcluster<=10);
small_cluster_no=numel(small_cluster);
massive_cluster=find(sizeofcluster>10);
massive_cluster_no=numel(massive_cluster);
member_small_cluster=[];
for i=small_cluster
    member_small_cluster=[member_small_cluster,member{clusterlist(i)}];
end
member_small_cluster_no=numel(member_small_cluster);
member_massive_cluster=[];
for i=massive_cluster
    member_massive_cluster=[member_massive_cluster,member{clusterlist(i)}];
end
   member_massive_cluster_no=numel(member_massive_cluster);
   %new number system in layer of slot aloha and RACH
   %1. Entities in slot aloha system: member_massive_cluster,the number of
   %entities are index in member_massive_cluster.
   %2. Entities in RACH system:member_small_cluster+massive_cluster
   % the number are the index in the above entity set
   %re-number members in each massive cluster
   member_slot_aloha=cell(1,massive_cluster_no);
for i=1:massive_cluster_no
    member_i=member{clusterlist(massive_cluster(i))};
    member_slot_aloha{i}=[];
    for j=1:numel(member_i)
        member_slot_aloha{i}=[member_slot_aloha{i},find(member_massive_cluster==member_i(j))];
    end
end
CH_individual_user=1:member_small_cluster_no;
CH_cluster=member_small_cluster_no+1:member_small_cluster_no+massive_cluster_no;
CH_no=member_small_cluster_no+massive_cluster_no;


%Channels/Path Loss of massive cluster members to eNB.
%distance of all massive cluster members to eNB
D=sqdistance(coordinate(member_massive_cluster,:)',[500;500]).^0.5;
PL=128.1+37.6*log10(D/1000)+normrnd(0,8,1,member_massive_cluster_no)';
%select a cluster header in each cluster
CH=zeros(1,massive_cluster_no);
for i=1:massive_cluster_no
    member_slot_aloha_i=member_slot_aloha{i};
    CH(i)=member_slot_aloha_i(PL(member_slot_aloha_i)==min(PL(member_slot_aloha_i)));
end




%Two-Tier Random Access System time-based operation (subframe by subframe)
%some assumptions
%1. the link is perfect, as long as no collision, message will be successfully recieved.
%2. all data can be finished uploading in only one slot.
%3. the ACK response will be acknowledged in the current transmission slot.
%4. the backoff should be done within the slotted aloha access frame,and the value can be set as 5)





%slot aloha environment settup

STATE_IDLE_SLOT_ALOHA=0;
STATE_ACTIVE_SLOT_ALOHA=1;
STATE_BACK_OFF_SLOT_ALOHA=2;
STATE_COMPLETION_SLOT_ALOHA=3;
CH_buffer=zeros(1,massive_cluster_no);
CH_buffer_threshold=20;
CH_cluster_complete_subframe=cell(1,massive_cluster_no);
slot_aloha_channel_no=1;
BACKOFF_INDICATOR_SLOT_ALOHA=20;
RAR_WINDOW_SIZE_SLOT_ALOHA=5;
SINR_THRESHOLD=20;
Ptx_slot_aloha=25;
Prx_slot_aloha=25;
%RACH environment settup
USER_NO=CH_no; 


% Preamble Configuration, each Index here corresponds to Index-1 in 3GPP
Configuration_Index=[1,4,7,10,13,15];
Configuration=zeros(6,20);
Configuration(Configuration_Index(1),:)=[0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
Configuration(Configuration_Index(2),:)=[0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0];
Configuration(Configuration_Index(3),:)=[0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0];
Configuration(Configuration_Index(4),:)=[0,1,0,0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,0];
Configuration(Configuration_Index(5),:)=[1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0];
Configuration(Configuration_Index(6),:)=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];


%parameter settup
PREAMBLE_NO=54;
PREABMLE_TRAN_MAX=10;
RAR_WINDOW_SIZE=5;
CONTENTION_RESOLUTION_TIMER=48;
BACKOFF_INDICATOR=20;
TMSG1=1;
TMSG2=3;
TMSG3=5;
TTRANMSG3=1;
TMSG4=5;
MAX_PREAM_TRANS=10;
MAX_RETRANS_HARQ=5;
MSG34_SUCCESS_PROBABILITY=0.9;
RAR_GRANT_NO_PER_RAO=12;
Pidle=0.025;
Prx=50;
Ptx=50;
RACH_PERIOD=10;
RACH_PERIOD_SUBFRAME=RACH_PERIOD*1000;
%user_state value definition
%STATE_IDLE--idle;
%STATE_ACTIVE--have packets ready to initial access request(send Msg1);
%STATE_RA_RESPONSE_WINDOW--msg1 fail wait until RA_response_window time out
%STATE_BACKOFF--msg1 fail after RA response timeout during the backoff period
%STATE_MSG1_SUCCESS--Msg1 success in the medium period before Msg3 transmission.
%STATE_MSG34_SUCCESS--Msg34 success waiting for RACH completion
%STATE_COMPLETION--After RACH completion
%STATE_MSG34_FAIL--Msg34 fail waiting for next retransmission of Msg3
%STATE_DROP--exceed maximum allowable retransmission times, DROP packet and report to upper layer
STATE_IDLE=0;STATE_ACTIVE=1;STATE_RA_RESPONSE_WINDOW=2;STATE_BACKOFF=3;STATE_MSG1_SUCCESS=4;STATE_MSG34_SUCCESS=5;STATE_COMPLETION=6;STATE_MSG34_FAIL=7;STATE_DROP=8;

%# of actual running subframe
N=10000;

RACH_PERIOD_SUBFRAME_CONFIGURE=repmat(Configuration(7,:),1,RACH_PERIOD_SUBFRAME/20);
access_subframe=find(RACH_PERIOD_SUBFRAME_CONFIGURE==1);
RACH_PERIOD_SUBFRAME_CONFIGURE_EXTEND=repmat(Configuration(7,:),1,RACH_PERIOD_SUBFRAME*6/20);
access_subframe_extend=find(RACH_PERIOD_SUBFRAME_CONFIGURE_EXTEND==1);
RACH_access_subframe=access_subframe_extend(RACH_interval:RACH_interval:end);
RACH_access_subframe_no=numel(RACH_access_subframe);
slot_aloha_access_subframe=setdiff(access_subframe_extend,RACH_access_subframe);


access_subframe_no=numel(access_subframe);

access_subframe_actual_no=N/5;
user_state=zeros(RACH_PERIOD_SUBFRAME*2,USER_NO);
user_state(:)=nan;
user_state(1,:)=STATE_IDLE;
active_user=cell(1,N);
user_complete=zeros(1,device_no_run(run)); IN_PROGRESS=0; COMPLETE=1; DROP=2;%IN_PROGRESS--0 COMPLETE--1 DROP--2

success_state=zeros(RACH_access_subframe_no,USER_NO);
access_subframe_current=0;
msg1_counter=zeros(1,USER_NO);
msg34_counter=zeros(1,USER_NO);
user_preamble=zeros(RACH_access_subframe_no,USER_NO);
user_preamble(:)=nan;
user_delay=zeros(1,USER_NO);

first_active_subframe=zeros(1,device_no_run(run));
first_access_subframe=zeros(1,device_no_run(run));
last_active_subframe=zeros(1,device_no_run(run));
complete_subframe=zeros(1,device_no_run(run));
preamble_transmission=zeros(1,USER_NO);
subframe_elapse_from_current_subframe=zeros(1,USER_NO);
used_preamble=cell(1,RACH_access_subframe_no);
collision_preambles=cell(1,RACH_access_subframe_no);
success_preambles=cell(1,RACH_access_subframe_no);
idle_preambles=cell(1,RACH_access_subframe_no);
collision_preambles_no=zeros(1,RACH_access_subframe_no);
success_preambles_no=zeros(1,RACH_access_subframe_no);
idle_preambles_no=zeros(1,RACH_access_subframe_no);
idle_preambles_no(:)=PREAMBLE_NO;
transmission_times_slot_aloha=zeros(1,member_massive_cluster_no);
collision_cluster_slot_aloha=zeros(1,member_massive_cluster_no);
success_cluster_slot_aloha=zeros(1,member_massive_cluster_no);
transmission_times_RACH=zeros(1,USER_NO);
collision_cluster_RACH=zeros(1,USER_NO);
success_cluster_RACH=zeros(1,USER_NO);
delay_member_massive_cluster=zeros(1,member_massive_cluster_no);
delay_member_small_cluster=zeros(1,member_small_cluster_no);
EC_slot_aloha=zeros(1,member_massive_cluster_no);
EC_RACH=zeros(1,USER_NO);
subframe=1;


%distribute access uniformly over RACH period
user_access_subframe=access_subframe(randi(access_subframe_no,1,device_no_run(run)));



 
  
  
  
   



            
 %assign user state according to access distribution
user_state_slot_aloha=zeros(2*RACH_PERIOD_SUBFRAME,member_massive_cluster_no);
for i=1:member_massive_cluster_no
    next_access_subframe=slot_aloha_access_subframe(find(slot_aloha_access_subframe>=user_access_subframe(member_massive_cluster(i)),1,'first'));
    user_state_slot_aloha(1:user_access_subframe(member_massive_cluster(i))-1,i)=STATE_IDLE_SLOT_ALOHA;
    user_state_slot_aloha(user_access_subframe(member_massive_cluster(i)):next_access_subframe,i)=STATE_ACTIVE_SLOT_ALOHA;
    active_before_transmission_period=next_access_subframe-user_access_subframe(member_massive_cluster(i))+1-1;
    EC_slot_aloha(i)=EC_slot_aloha(i)+active_before_transmission_period/1000*Pidle;
end


for i=1:member_small_cluster_no
    next_access_subframe=RACH_access_subframe(find(RACH_access_subframe>=user_access_subframe(member_small_cluster(i)),1,'first'));
    user_state(1:user_access_subframe(member_small_cluster(i))-1,i)=STATE_IDLE;
    user_state(user_access_subframe(member_small_cluster(i)):next_access_subframe,i)=STATE_ACTIVE;
    active_before_access_period=next_access_subframe-user_access_subframe(member_small_cluster(i))+1-1;
    EC_RACH(i)=EC_RACH(i)+active_before_access_period/1000*Pidle;
end

while(subframe<RACH_PERIOD_SUBFRAME*2 && any(user_complete==IN_PROGRESS) || any(user_state(subframe,:)==STATE_ACTIVE | user_state(subframe,:)==STATE_RA_RESPONSE_WINDOW | user_state(subframe,:)==STATE_BACKOFF | user_state(subframe,:)==STATE_MSG1_SUCCESS | user_state(subframe,:)==STATE_MSG34_SUCCESS | user_state(subframe,:)==STATE_MSG34_FAIL))
    
    %run slot aloha system in massive clusters
    if any(user_complete(member_massive_cluster)~=COMPLETE)
        
        if ismembc(subframe,slot_aloha_access_subframe)
            active_member_all=find(user_state_slot_aloha(subframe,:)==STATE_ACTIVE_SLOT_ALOHA);
            % all active member consume transmission energy
            EC_slot_aloha(active_member_all)=EC_slot_aloha(active_member_all)+Ptx*0.001;
        for i=1:massive_cluster_no
        member_i=member_slot_aloha{i};
        active_member=member_i(user_state_slot_aloha(subframe,member_i)==STATE_ACTIVE_SLOT_ALOHA);
        
        active_member_no=numel(active_member);
        transmission_times_slot_aloha(active_member)=transmission_times_slot_aloha(active_member)+1;
        success_state_slot_aloha=zeros(1,active_member_no);
        CH_coordinate=coordinate(member_massive_cluster(CH(i)),:);
        D_slot_aloha=sqdistance(coordinate(member_massive_cluster(active_member_all),:)',CH_coordinate').^0.5;
        PL_slot_aloha=(D_slot_aloha<0.3).*(38.5+20*log10(D_slot_aloha))+(D_slot_aloha>=0.3).*(48.9+40*log10(D_slot_aloha));
        %get active member success state
       for k=1:active_member_no
           if active_member(k)==CH(i)
               success_state_slot_aloha(k)=1;
           else
           index_in_active_member_all=find(active_member_all==active_member(k));
           pathloss=PL_slot_aloha(index_in_active_member_all);
           pr=14-pathloss;
           PL_slot_aloha_others=PL_slot_aloha;
           PL_slot_aloha_others(index_in_active_member_all)=[];
           
           if isempty(PL_slot_aloha_others)
               sum_interference_dB=-inf;
           else
               
           interference_dB=14-PL_slot_aloha_others;
           interference=10.^(interference_dB/10);
           sum_interference=sum(interference);
           sum_interference_dB=10*log10(sum_interference);
           end
           SINR=pr-sum_interference_dB;
           if SINR>=SINR_THRESHOLD
               success_state_slot_aloha(k)=1;
           else
               success_state_slot_aloha(k)=0;
           end
                     
           end
       end
       
        %setting for success user
        success_user_slot_aloha=active_member(success_state_slot_aloha==1);
        user_complete(member_massive_cluster(success_user_slot_aloha))=COMPLETE;
        success_cluster_slot_aloha(success_user_slot_aloha)=success_cluster_slot_aloha(success_user_slot_aloha)+1;
        user_state_slot_aloha(subframe+1,success_user_slot_aloha)=STATE_COMPLETION_SLOT_ALOHA;
        user_state_slot_aloha((subframe+1):end,success_user_slot_aloha)=STATE_COMPLETION_SLOT_ALOHA;
        EC_slot_aloha(success_user_slot_aloha)=EC_slot_aloha(success_user_slot_aloha)+Prx_slot_aloha*0.001;
        %get CH_buffer
        throughput=numel(success_user_slot_aloha);
        if subframe==1
            CH_buffer(subframe,i)= throughput;
        elseif subframe>1
            if ismembc(subframe,CH_cluster_complete_subframe{i})
                CH_buffer(subframe,i)=0;
            else                
            CH_buffer(subframe,i)=CH_buffer(subframe-1,i)+throughput;
            end
        end
    
        
        %setting for failure user
        fail_user_slot_aloha=active_member(success_state_slot_aloha==0);
        collision_cluster_slot_aloha(fail_user_slot_aloha)=collision_cluster_slot_aloha(fail_user_slot_aloha)+1;
             
        for k=fail_user_slot_aloha
            backoff_value=randi(BACKOFF_INDICATOR_SLOT_ALOHA);
            last_access_subframe_position=find(slot_aloha_access_subframe<=subframe,1,'last');
            next_slot_aloha_access_subframe=slot_aloha_access_subframe(last_access_subframe_position+backoff_value);
            user_state_slot_aloha(subframe+1:next_slot_aloha_access_subframe-1,k)=STATE_BACK_OFF_SLOT_ALOHA;
            user_state_slot_aloha(next_slot_aloha_access_subframe,k)=STATE_ACTIVE_SLOT_ALOHA;
            backoff_period=next_slot_aloha_access_subframe-1-(subframe+1)+1;
            EC_slot_aloha(k)=EC_slot_aloha(k)+Prx_slot_aloha*RAR_WINDOW_SIZE_SLOT_ALOHA/1000;
            EC_slot_aloha(k)=EC_slot_aloha(k)+backoff_period/1000*Pidle;
        end
        
        end
        else
        for i=1:massive_cluster_no
        if subframe==1
       CH_buffer(subframe,i)=0;
        elseif subframe>1
            
                if ismembc(subframe,CH_cluster_complete_subframe{i})
                CH_buffer(subframe,i)=0;
                else                
                CH_buffer(subframe,i)=CH_buffer(subframe-1,i);
                end
        end
        end
        end
    else
        for i=1:massive_cluster_no
        if ismembc(subframe,CH_cluster_complete_subframe{i})
           CH_buffer(subframe,i)=0;
        else                
           CH_buffer(subframe,i)=CH_buffer(subframe-1,i);
        end
        end
        
     end
        
    
        %run RACH system for all CHs
        subframe_elapse_from_current_subframe(:)=0;
        %Observe Each Subframe
        %check configure of the current frame  
        %if current subframe is access slot active users send Msg 1
        for i=find(user_state(subframe,1+member_small_cluster_no:end)==STATE_IDLE)
           if CH_buffer(subframe,i)>=CH_buffer_threshold
               next_access_subframe=RACH_access_subframe(find(RACH_access_subframe>subframe,1,'first'));
               user_state(subframe+1:next_access_subframe,i+member_small_cluster_no)=STATE_ACTIVE;
               active_before_transmission_period=next_access_subframe-(subframe+1)+1-1;
               EC_RACH(i+member_small_cluster_no)=EC_RACH(i+member_small_cluster_no)+active_before_transmission_period/1000*Pidle;
             elseif CH_buffer(subframe,i)<CH_buffer_threshold
               user_state(subframe+1,i+member_small_cluster_no)=STATE_IDLE;
           end
        end
        
        if ismembc(subframe,RACH_access_subframe)
               
        access_subframe_current=access_subframe_current+1;
        active_user{subframe}=find(user_state(subframe,:)==STATE_ACTIVE);
        access_attempt_no=numel(active_user{subframe});
        
        %each active user random select a preamble
        for j=active_user{subframe}
            
            user_preamble(access_subframe_current,j)=unidrnd(PREAMBLE_NO);
        end
        user_preamble(access_subframe_current,setdiff(1:USER_NO,active_user{subframe}))=nan;
        transmission_times_RACH(active_user{subframe})=transmission_times_RACH(active_user{subframe})+1;
        EC_RACH(active_user{subframe})=EC_RACH(active_user{subframe})+0.001*Ptx;
        %success state
        for j=active_user{subframe}
                if numel(find(user_preamble(access_subframe_current,:)==user_preamble(access_subframe_current,j)))>=2
                    success_state(access_subframe_current,j)=0;
                else
                    preamble_success_probability=1-exp(-(msg1_counter(j)+1));
                    rand_preamble_success_probability=rand;
                    if rand_preamble_success_probability>preamble_success_probability
                    success_state(access_subframe_current,j)=0;
                    else 
                        success_state(access_subframe_current,j)=1;
                    end
                end
        end
        success_state(access_subframe_current,setdiff(1:USER_NO,active_user{subframe}))=0;
        success_state_success=find(success_state(access_subframe_current,:)==1);
        success_state_success_no=numel(success_state_success);
        if success_state_success_no>RAR_GRANT_NO_PER_RAO
            RAR_grant=success_state_success(randperm(success_state_success_no,12));
            success_state(access_subframe_current,setdiff(success_state_success,RAR_grant))=0;
        end
            
        % preambles statistics in current access subframe
        if any (~isnan(user_preamble(access_subframe_current,:)))
        used_preamble_frequency_table=tabulate(user_preamble(access_subframe_current,:));
        used_preamble_frequency_table(used_preamble_frequency_table(:,2)==0,:)=[];
        used_preamble{access_subframe_current}=used_preamble_frequency_table(:,1);
        used_preamble_access_subframe_current=used_preamble{access_subframe_current};
        used_preamble_frequency=used_preamble_frequency_table(:,2);
        collision_preambles{access_subframe_current}=used_preamble_access_subframe_current((find(used_preamble_frequency>1)));
        collision_preambles_no(access_subframe_current)=numel(find(used_preamble_frequency>1));
        success_preambles{access_subframe_current}=used_preamble_access_subframe_current((find(used_preamble_frequency==1)));
        success_preambles_no(access_subframe_current)=numel((find(used_preamble_frequency==1)));
        idle_preambles{access_subframe_current}=setdiff(1:PREAMBLE_NO,used_preamble_access_subframe_current);
        idle_preambles_no(access_subframe_current)=numel(idle_preambles{access_subframe_current});
        else
            used_preamble{access_subframe_current}=nan;
            collision_preambles{access_subframe_current}=nan;
            collision_preambles_no(access_subframe_current)=0;
            success_preambles{access_subframe_current}=nan;
            success_preambles_no(access_subframe_current)=0;
            idle_preambles{access_subframe_current}=1:PREAMBLE_NO;
            idle_preambles_no(access_subframe_current)=PREAMBLE_NO;
        end
     
        %success user 
        %will receive rar within period of TMSG1+TMSG2
        %success user add a delay of TMSG1+TMSG2+TMSG3,
        %within the medium period user_state is always STATE_MSG1_SUCCESS. 
        %after medium period transmit Msg3 
        %if Msg34 success user_state turn into STATE_MSG34_SUCCESS during period waiting for completion
        %after receiving Msg4 user_state turn into STATE_COMPLETION
        %if Msg34 fail user_state turn into STATE_MSG34_FAIL,
        %after contention window, retransmit Msg3.
       
        success_user=find(success_state(access_subframe_current,:)==1);
        success_cluster_RACH(success_user)=success_cluster_RACH(success_user)+1;
        msg1_counter(success_user)=0;
        subframe_elapse_from_current_subframe(success_user)=subframe_elapse_from_current_subframe(success_user)+TMSG1+TMSG2+TMSG3;
        user_state(subframe+1:subframe+TMSG1-1+TMSG2+TMSG3,success_user)=STATE_MSG1_SUCCESS;
        msg1_success_period=subframe+TMSG1-1+TMSG2+TMSG3-(subframe+1)+1;
        EC_RACH(success_user)=EC_RACH(success_user)+msg1_success_period/1000*Prx;
        for j=success_user
            while(true)
                msg34_probability=rand(1);
                if  msg34_probability<MSG34_SUCCESS_PROBABILITY
                    %Msg34 success and random access procedure COMPLETE
                    user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:subframe+subframe_elapse_from_current_subframe(j)-1+TTRANMSG3+TMSG4,j)=STATE_MSG34_SUCCESS;
                    msg34_success_period=TTRANMSG3+TMSG4-1+1-1;
                    EC_RACH(j)=EC_RACH(j)+0.001*Ptx+msg34_success_period/1000*Prx;
                    subframe_elapse_from_current_subframe(j)=subframe_elapse_from_current_subframe(j)+TTRANMSG3+TMSG4;
                    if ismembc(j,CH_individual_user)
                    user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1,j)=STATE_COMPLETION;
                    user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:N,j)=STATE_COMPLETION;
                    msg34_counter(j)=0;
                    msg1_counter(j)=0;
                    user_complete(member_small_cluster(j))=COMPLETE;
                    
                    elseif ismembc(j,CH_cluster)
                        user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1,j)=STATE_IDLE;
                        msg34_counter(j)=0;
                        msg1_counter(j)=0;
                        CH_buffer(subframe+subframe_elapse_from_current_subframe(j)-1,j-member_small_cluster_no)=0;
                        CH_cluster_complete_subframe{j-member_small_cluster_no}=[CH_cluster_complete_subframe{j-member_small_cluster_no},subframe+subframe_elapse_from_current_subframe(j)-1];
                    end
                    break;
                else
                    %Msg34 failure 
                    user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:subframe+subframe_elapse_from_current_subframe(j)-1+TTRANMSG3+CONTENTION_RESOLUTION_TIMER,j)=STATE_MSG34_FAIL;
                    msg34_fail_period=CONTENTION_RESOLUTION_TIMER;
                    EC_RACH(j)=EC_RACH(j)+TTRANMSG3/1000*Ptx+msg34_fail_period/1000*Prx;
                    subframe_elapse_from_current_subframe(j)=subframe_elapse_from_current_subframe(j)+TTRANMSG3+CONTENTION_RESOLUTION_TIMER;
                    msg34_counter(j)=msg34_counter(j)+1;
                    if msg34_counter(j)==MAX_RETRANS_HARQ
                        if ismembc(j,CH_individual_user)
                        user_complete(member_small_cluster(j))=DROP;
                        user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:N,j)=STATE_DROP;
                        elseif ismembc(j,CH_cluster)
                            user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1,j)=STATE_IDLE;
                            msg34_counter(j)=0;
                            msg1_counter(j)=0;
                            CH_buffer(subframe+subframe_elapse_from_current_subframe(j)-1,j-member_small_cluster_no)=0;
                            CH_cluster_complete_subframe{j-member_small_cluster_no}=[CH_cluster_complete_subframe{j-member_small_cluster_no},subframe+subframe_elapse_from_current_subframe(j)-1];
                        end
                        break;
                       
                    end
                end
            end
        end    
        %failure user 
        %enter into RA-response window state, delay+TMSG1+RA_response_window
        %msg1_counter+1
        %if msg1_counter larger than MAX_PREAM_TRANS, DROP packet and report to upper layer
        %if msg1_counter smaller than MAX_PREAM_TRANS, enter into back-off state, delay+random backoff--unif(0,BACKOFF_INDICATOR)
       failure_user=intersect(active_user{subframe},find(success_state(access_subframe_current,:)==0));
       collision_cluster_RACH(failure_user)=collision_cluster_RACH(failure_user)+1;
       if ~isempty(failure_user)
       for j=failure_user
           user_state(subframe+1:subframe+RAR_WINDOW_SIZE,j)=STATE_RA_RESPONSE_WINDOW;
           RA_RESPONSE_WINDOW_period=RAR_WINDOW_SIZE;
           EC_RACH(j)=EC_RACH(j)+RAR_WINDOW_SIZE/1000*Prx;
            subframe_elapse_from_current_subframe(j)=subframe_elapse_from_current_subframe(j)+TMSG1+RAR_WINDOW_SIZE;
            msg1_counter(j)=msg1_counter(j)+1;
            if msg1_counter(j)==MAX_PREAM_TRANS
                if ismembc(j,CH_individual_user)
                user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:N,j)=STATE_DROP;
                user_complete(member_small_cluster(j))=DROP;
                elseif ismembc(j,CH_cluster)
                user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1,j)=STATE_IDLE;
                msg34_counter(j)=0;
                msg1_counter(j)=0;
                CH_buffer(subframe+subframe_elapse_from_current_subframe(j)-1,j-member_small_cluster_no)=0;
                CH_cluster_complete_subframe{j-member_small_cluster_no}=[CH_cluster_complete_subframe{j-member_small_cluster_no},subframe+subframe_elapse_from_current_subframe(j)-1];
                end
            else
                backoff_time=unidrnd(BACKOFF_INDICATOR+1)-1;
                user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:subframe+subframe_elapse_from_current_subframe(j)-1+backoff_time,j)=STATE_BACKOFF;
                BACKOFF_period=backoff_time;
                EC_RACH(j)=EC_RACH(j)+BACKOFF_period/1000*Pidle;
                subframe_elapse_from_current_subframe(j)=subframe_elapse_from_current_subframe(j)+backoff_time;
                next_access_subframe=RACH_access_subframe(find(RACH_access_subframe>subframe+subframe_elapse_from_current_subframe(j)-1,1,'first'));
                user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:next_access_subframe,j)=STATE_ACTIVE;
                active_before_access_period=next_access_subframe-(subframe+subframe_elapse_from_current_subframe(j)-1+1)+1-1;
                EC_RACH(j)=EC_RACH(j)+active_before_access_period/1000*Pidle;
            end
       end
       end
        else
        
       end
        subframe=subframe+1;
end

%{
if subframe>=RACH_PERIOD_SUBFRAME*1.5
      transmission_times_total(loop)=nan;
    
    average_access_delay_cluster(loop)=nan;
else
%}
%get stastics of transmission times
transmission_times_total_run(run)=sum(transmission_times_slot_aloha)+sum(transmission_times_RACH);



%get stastics of delay
%for individual device delay is from first active subframe to its RACH complete subframe
member_small_cluster_complete=member_small_cluster(user_complete(member_small_cluster)==COMPLETE);
member_small_cluster_drop=member_small_cluster(user_complete(member_small_cluster)==DROP);
for i=member_small_cluster_complete
    i_in_RACH_no=find(member_small_cluster==i);
   first_active_subframe(i)=find(user_state(:,i_in_RACH_no)==STATE_ACTIVE,1,'first');
   first_access_subframe(i)=find(user_state(first_active_subframe(i):end,i_in_RACH_no)~=STATE_ACTIVE,1,'first')+first_active_subframe(i)-1-1;
   %{ 
subframe_track=first_active_subframe(i);
    while user_state(subframe_track+1,i_no_in_RACH)==1
        subframe_track=subframe_track+1;
    end
    first_access_subframe(i)=subframe_track;
   %}
    complete_subframe(i)=find(user_state(:,i_in_RACH_no)==STATE_MSG34_SUCCESS,1,'last');
    user_delay(i)=complete_subframe(i)-first_access_subframe(i)+1;
end
user_delay(member_small_cluster_drop)=nan;
%for cluster devices delay is from first active subframe, then successfully 
%upload its packets, to the next subframe of its CH complete RACH.
for i=member_massive_cluster
    i_in_slot_aloha_no=find(member_massive_cluster==i);
    first_active_subframe(i)=find(user_state_slot_aloha(:,i_in_slot_aloha_no)==STATE_ACTIVE,1,'first');
     first_access_subframe(i)=find(user_state_slot_aloha(first_active_subframe(i):end,i_in_slot_aloha_no)~=STATE_ACTIVE,1,'first')+first_active_subframe(i)-1-1;
    %{
subframe_track=first_active_subframe(i);
    while user_state(subframe_track+1,i_no_in_RACH)==1
        subframe_track=subframe_track+1;
    end
    first_access_subframe(i)=subframe_track;
    %}
    %{
slot_aloha_complete_subframe=find(user_state_slot_aloha(:,i_in_slot_aloha_no)==STATE_ACTIVE,1,'last');
    i_attach_cluster=clusterattach(i);
    i_attach_cluster_in_clusterlist_no=find(clusterlist==i_attach_cluster);
    i_attach_cluster_in_massive_cluster_no=find(massive_cluster==i_attach_cluster_in_clusterlist_no);
    i_attach_cluster_in_RACH_no=member_small_cluster_no+i_attach_cluster_in_massive_cluster_no;
    if any(user_state(slot_aloha_complete_subframe:end,i_attach_cluster_in_RACH_no)==STATE_MSG34_SUCCESS)
    CH_complete_subframe=slot_aloha_complete_subframe-1+find(user_state(slot_aloha_complete_subframe:end,i_attach_cluster_in_RACH_no)==STATE_MSG34_SUCCESS,1,'first')+5;
    user_delay(i)=CH_complete_subframe-first_active_subframe(i)+1;
    else
        user_delay(i)=nan;
    end
    %}
    
    last_active_subframe(i)=find(user_state_slot_aloha(:,i_in_slot_aloha_no)==STATE_ACTIVE,1,'last');
    user_delay(i)=last_active_subframe(i)-first_access_subframe(i)+1;
end
delay=user_delay;
delay(isnan(delay))=[];
average_access_delay_cluster_run(run)=sum(delay)/numel(delay);
%get collision rate
collision_cluster_rate_run(run)=(sum(collision_cluster_slot_aloha)+sum(collision_cluster_RACH))/transmission_times_total_run(run);
success_cluster_rate_run(run)=(sum(success_cluster_slot_aloha)+sum(success_cluster_RACH))/transmission_times_total_run(run);
%get energy consumption
EC_slot_aloha_sum_run(run)=sum(EC_slot_aloha);
EC_RACH_sum_run(run)=sum(EC_RACH);
EC_sum_run(run)=EC_slot_aloha_sum_run(run);
    end
    collision_cluster_rate(loop)=mean(collision_cluster_rate_run);
    success_cluster_rate(loop)=mean(success_cluster_rate_run);
    COV(loop)=mean(COV_run);
    device_no(loop)=mean(device_no_run);
    transmission_times_total(loop)=mean(transmission_times_total_run);
    average_access_delay_cluster(loop)=mean(average_access_delay_cluster_run);
    EC_slot_aloha_sum(loop)=mean(EC_slot_aloha_sum_run);
    EC_RACH_sum(loop)=mean(EC_RACH_sum_run);
    EC_cluster_sum(loop)=mean(EC_sum_run);
loop=loop+1;
    
end
transmission_times_total_min=min(transmission_times_total);
transmission_times_total(transmission_times_total>3*device_no)=nan;
average_access_delay_cluster_min=min(average_access_delay_cluster);
average_access_delay_cluster(average_access_delay_cluster>10*average_access_delay_cluster_min)=nan;


clearvars -except device_no R_sample COV  transmission_times_total average_access_delay_cluster collision_cluster_rate success_cluster_rate EC_cluster_sum
%only count one RACH procedure for each user



%% 
loop=1;
total_preamble_transmission=zeros(1,sample_no);
average_access_delay=zeros(1,sample_no);
collision_rate=zeros(1,sample_no);
success_rate=zeros(1,sample_no);
EC_sum=zeros(1,sample_no);
for R=R_sample
USER_NO=device_no(loop);
%only count one RACH procedure for each user
% Preamble Configuration, each Index here corresponds to Index-1 in 3GPP
Configuration_Index=[1,4,7,10,13,15];
Configuration=zeros(6,20);
Configuration(Configuration_Index(1),:)=[0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
Configuration(Configuration_Index(2),:)=[0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0];
Configuration(Configuration_Index(3),:)=[0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0];
Configuration(Configuration_Index(4),:)=[0,1,0,0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,0];
Configuration(Configuration_Index(5),:)=[1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0];
Configuration(Configuration_Index(6),:)=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];


%parameter settup
PREAMBLE_NO=54;
PREABMLE_TRAN_MAX=10;
RAR_WINDOW_SIZE=5;
CONTENTION_RESOLUTION_TIMER=48;
BACKOFF_INDICATOR=20;
TMSG1=1;
TMSG2=3;
TMSG3=5;
TTRANMSG3=1;
TMSG4=5;
MAX_PREAM_TRANS=10;
MAX_RETRANS_HARQ=5;
MSG34_SUCCESS_PROBABILITY=0.9;
RAR_GRANT_NO_PER_RAO=12;
Pidle=0.025;
Prx=50;
Ptx=50;
RACH_PERIOD=10;
RACH_PERIOD_SUBFRAME=RACH_PERIOD*1000;
%user_state value definition
%STATE_IDLE--idle;
%STATE_ACTIVE--have packets ready to initial access request(send Msg1);
%STATE_RA_RESPONSE_WINDOW--msg1 fail wait until RA_response_window time out
%STATE_BACKOFF--msg1 fail after RA response timeout during the backoff period
%STATE_MSG1_SUCCESS--Msg1 success in the medium period before Msg3 transmission.
%STATE_MSG34_SUCCESS--Msg34 success waiting for RACH completion
%STATE_COMPLETION--After RACH completion
%STATE_MSG34_FAIL--Msg34 fail waiting for next retransmission of Msg3
%STATE_DROP--exceed maximum allowable retransmission times, DROP packet and report to upper layer
STATE_IDLE=0;STATE_ACTIVE=1;STATE_RA_RESPONSE_WINDOW=2;STATE_BACKOFF=3;STATE_MSG1_SUCCESS=4;STATE_MSG34_SUCCESS=5;STATE_COMPLETION=6;STATE_MSG34_FAIL=7;STATE_DROP=8;

%# of actual running subframe
N=10000;

RACH_PERIOD_SUBFRAME_CONFIGURE=repmat(Configuration(7,:),1,RACH_PERIOD_SUBFRAME/20);
access_subframe=find(RACH_PERIOD_SUBFRAME_CONFIGURE==1);
access_subframe_no=numel(access_subframe);

access_subframe_actual_no=N/5;
user_state=zeros(RACH_PERIOD_SUBFRAME,USER_NO);
user_state(:)=nan;
user_state(1,:)=STATE_IDLE;
active_user=cell(1,N);
user_complete=zeros(1,USER_NO); IN_PROGRESS=0; COMPLETE=1; DROP=2;%IN_PROGRESS--0 COMPLETE--1 DROP--2

success_state=zeros(access_subframe_no,USER_NO);
access_subframe_current=0;
msg1_counter=zeros(1,USER_NO);
msg34_counter=zeros(1,USER_NO);
user_preamble=zeros(access_subframe_no,USER_NO);
user_preamble(:)=nan;
user_delay=zeros(1,USER_NO);
first_access_subframe=zeros(1,USER_NO);
first_active_subframe=zeros(1,USER_NO);

complete_subframe=zeros(1,USER_NO);
preamble_transmission=zeros(1,USER_NO);
subframe_elapse_from_current_subframe=zeros(1,USER_NO);
used_preamble=cell(1,access_subframe_no);
collision_preambles=cell(1,access_subframe_no);
success_preambles=cell(1,access_subframe_no);
idle_preambles=cell(1,access_subframe_no);
collision_preambles_no=zeros(1,access_subframe_no);
success_preambles_no=zeros(1,access_subframe_no);
idle_preambles_no=zeros(1,access_subframe_no);
idle_preambles_no(:)=PREAMBLE_NO;
success_times=zeros(1,USER_NO);
collision_times=zeros(1,USER_NO);
EC=zeros(1,USER_NO);
subframe=2;


%distribute access uniformly over RACH period
user_access_subframe=access_subframe(randi(access_subframe_no,1,USER_NO));

%user_active_state assignment according to access distribution
for i=1:USER_NO
    user_state(1:user_access_subframe(i)-1,i)=STATE_IDLE;
    user_state(user_access_subframe(i),i)=STATE_ACTIVE;
end

%run RACH system subframe by subframe
while(any(user_complete==0))
subframe_elapse_from_current_subframe(:)=0;
    %Observe Each Subframe
    %check configure of the current frame
  
   
    
        
    
    %if current subframe is access slot active users send Msg 1
    if mod(subframe,10)==2 || mod(subframe,10)==7
               
        access_subframe_current=access_subframe_current+1;
        active_user{subframe}=find(user_state(subframe,:)==STATE_ACTIVE);
        access_attempt_no=numel(active_user{subframe});
        
        
        
        %each active user random select a preamble
        for j=active_user{subframe}
            
            user_preamble(access_subframe_current,j)=unidrnd(PREAMBLE_NO);
        end
        user_preamble(access_subframe_current,setdiff(1:USER_NO,active_user{subframe}))=nan;
        %success state
        for j=active_user{subframe}
                if numel(find(user_preamble(access_subframe_current,:)==user_preamble(access_subframe_current,j)))>=2
                    success_state(access_subframe_current,j)=0;
                else
                    preamble_success_probability=1-exp(-(msg1_counter(j)+1));
                    rand_preamble_success_probability=rand;
                    if rand_preamble_success_probability>preamble_success_probability
                    success_state(access_subframe_current,j)=0;
                    else 
                        success_state(access_subframe_current,j)=1;
                    end
                end
        end
        success_state(access_subframe_current,setdiff(1:USER_NO,active_user{subframe}))=0;
        success_state_success=find(success_state(access_subframe_current,:)==1);
        success_state_success_no=numel(success_state_success);
        if success_state_success_no>RAR_GRANT_NO_PER_RAO
            RAR_grant=success_state_success(randperm(success_state_success_no,12));
            success_state(access_subframe_current,setdiff(success_state_success,RAR_grant))=0;
        end
            
        % preambles in current access subframe
        if any (~isnan(user_preamble(access_subframe_current,:)))
        used_preamble_frequency_table=tabulate(user_preamble(access_subframe_current,:));
        used_preamble_frequency_table(used_preamble_frequency_table(:,2)==0,:)=[];
        used_preamble{access_subframe_current}=used_preamble_frequency_table(:,1);
        used_preamble_access_subframe_current=used_preamble{access_subframe_current};
        used_preamble_frequency=used_preamble_frequency_table(:,2);
        collision_preambles{access_subframe_current}=used_preamble_access_subframe_current((find(used_preamble_frequency>1)));
        collision_preambles_no(access_subframe_current)=numel(find(used_preamble_frequency>1));
        success_preambles{access_subframe_current}=used_preamble_access_subframe_current((find(used_preamble_frequency==1)));
        success_preambles_no(access_subframe_current)=numel((find(used_preamble_frequency==1)));
        idle_preambles{access_subframe_current}=setdiff(1:PREAMBLE_NO,used_preamble_access_subframe_current);
        idle_preambles_no(access_subframe_current)=numel(idle_preambles{access_subframe_current});
        else
            used_preamble{access_subframe_current}=nan;
            collision_preambles{access_subframe_current}=nan;
            collision_preambles_no(access_subframe_current)=0;
            success_preambles{access_subframe_current}=nan;
            success_preambles_no(access_subframe_current)=0;
            idle_preambles{access_subframe_current}=1:PREAMBLE_NO;
            idle_preambles_no(access_subframe_current)=PREAMBLE_NO;
        end
        %success user 
        %will receive rar within period of TMSG1+TMSG2
        %success user add a delay of TMSG1+TMSG2+TMSG3,
        %within the medium period user_state is always STATE_MSG1_SUCCESS. 
        %after medium period transmit Msg3 
        %if Msg34 success user_state turn into STATE_MSG34_SUCCESS during period waiting for completion
        %after receiving Msg4 user_state turn into STATE_COMPLETION
        %if Msg34 fail user_state turn into STATE_MSG34_FAIL,
        %after contention window, retransmit Msg3.
       
        success_user=find(success_state(access_subframe_current,:)==1);
        success_times(success_user)=success_times(success_user)+1;
        msg1_counter(success_user)=0;
        subframe_elapse_from_current_subframe(success_user)=subframe_elapse_from_current_subframe(success_user)+TMSG1+TMSG2+TMSG3;
        user_state(subframe+1:subframe+TMSG1-1+TMSG2+TMSG3,success_user)=STATE_MSG1_SUCCESS;
        for j=success_user
            while(true)
                msg34_probability=rand(1);
                if  msg34_probability<MSG34_SUCCESS_PROBABILITY
                    %Msg34 success and random access procedure COMPLETE
                    user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:subframe+subframe_elapse_from_current_subframe(j)-1+TTRANMSG3+TMSG4,j)=STATE_MSG34_SUCCESS;
                    subframe_elapse_from_current_subframe(j)=subframe_elapse_from_current_subframe(j)+TTRANMSG3+TMSG4;
                    user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:N,j)=STATE_COMPLETION;
                    msg34_counter(j)=0;
                    msg1_counter(j)=0;
                    user_complete(j)=COMPLETE;
                    break;
                else
                    %Msg34 failure 
                    user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:subframe+subframe_elapse_from_current_subframe(j)-1+TTRANMSG3+CONTENTION_RESOLUTION_TIMER,j)=STATE_MSG34_FAIL;
                    subframe_elapse_from_current_subframe(j)=subframe_elapse_from_current_subframe(j)+TTRANMSG3+CONTENTION_RESOLUTION_TIMER;
                    msg34_counter(j)=msg34_counter(j)+1;
                    if msg34_counter(j)==MAX_RETRANS_HARQ
                        user_complete(j)=DROP;
                        break;
                       
                    end
                end
            end
        end    
        %failure user 
        %enter into RA-response window state, delay+TMSG1+RA_response_window
        %msg1_counter+1
        %if msg1_counter larger than MAX_PREAM_TRANS, DROP packet and report to upper layer
        %if msg1_counter smaller than MAX_PREAM_TRANS, enter into back-off state, delay+random backoff--unif(0,BACKOFF_INDICATOR)
       failure_user=intersect(active_user{subframe},find(success_state(access_subframe_current,:)==0));
       collision_times(failure_user)=collision_times(failure_user)+1;
       if ~isempty(failure_user)
       for j=failure_user
           user_state(subframe+1:subframe+RAR_WINDOW_SIZE,j)=STATE_RA_RESPONSE_WINDOW;
            subframe_elapse_from_current_subframe(j)=subframe_elapse_from_current_subframe(j)+TMSG1+RAR_WINDOW_SIZE;
            msg1_counter(j)=msg1_counter(j)+1;
            if msg1_counter(j)==MAX_PREAM_TRANS
                user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:N,j)=STATE_DROP;
                user_complete(j)=DROP;
            else
                backoff_time=unidrnd(21)-1;
                user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:subframe+subframe_elapse_from_current_subframe(j)-1+backoff_time,j)=STATE_BACKOFF;
                subframe_elapse_from_current_subframe(j)=subframe_elapse_from_current_subframe(j)+backoff_time;
                next_ten_subframe=subframe+subframe_elapse_from_current_subframe(j)-1+1:subframe+subframe_elapse_from_current_subframe(j)-1+10;
                next_access_subframe=next_ten_subframe(find(mod(next_ten_subframe,10)==2 | mod(next_ten_subframe,10)==7,1,'first'));
                
                user_state(subframe+subframe_elapse_from_current_subframe(j)-1+1:next_access_subframe,j)=STATE_ACTIVE;
            end
       end
       end
        
    end
   subframe=subframe+1;  
   
end
%fill RACH_Period complete user the afterwards user_state
total_actual_subframe=size(user_state,1);
for j=1:USER_NO
    last_state_defined_subframe=find(user_state(:,j)==STATE_COMPLETION | user_state(:,j)==STATE_DROP,1,'last');
    final_state=user_state(last_state_defined_subframe,j);
    user_state(last_state_defined_subframe:total_actual_subframe,j)=final_state;
end




%performance analysis
complete_success_user=find(user_complete==1);
complete_success_user_no=numel(complete_success_user);
complete_drop_user=find(user_complete==2);
complete_drop_user_no=numel(complete_drop_user);

overall_opp=access_subframe_no*PREAMBLE_NO;
collision_probability=sum(collision_preambles_no(1:access_subframe_no))/overall_opp;
success_probability=sum(success_preambles_no(1:access_subframe_no))/overall_opp;
idle_probability=sum(idle_preambles_no(1:access_subframe_no))/overall_opp;
for i=complete_success_user
    first_active_subframe(i)=find(user_state(:,i)==STATE_ACTIVE,1,'first');
    subframe_track=first_active_subframe(i);
    while user_state(subframe_track+1,i)==1
        subframe_track=subframe_track+1;
    end
    first_access_subframe(i)=subframe_track;
    complete_subframe(i)=find(user_state(:,i)==STATE_MSG34_SUCCESS,1,'last');
    user_delay(i)=complete_subframe(i)-first_access_subframe(i)+1;
end
access_success_probability=complete_success_user_no/USER_NO;
average_access_delay(loop)=sum(user_delay(complete_success_user))/complete_success_user_no;
for i=1:USER_NO
    preamble_transmission(i)=numel(find(~isnan(user_preamble(:,i))));
end

total_preamble_transmission(loop)=sum(preamble_transmission(complete_success_user));
average_preamble_transmission=sum(preamble_transmission(complete_success_user))/complete_success_user_no;
success_rate(loop)=sum(success_times)/total_preamble_transmission(loop);
collision_rate(loop)=sum(collision_times)/total_preamble_transmission(loop);
%get energy consumption of each device
for i=1:USER_NO
    active_before_access_period=numel(find(user_state(:,i)==STATE_ACTIVE))-preamble_transmission(i);
    RAR_period=numel(find(user_state(:,i)==STATE_RA_RESPONSE_WINDOW));
    backoff_period=numel(find(user_state(:,i)==STATE_BACKOFF));
    msg1_success_period=numel(find(user_state(:,i)==STATE_MSG1_SUCCESS));
    msg34_success_period=numel(find(user_state(:,i)==STATE_MSG34_SUCCESS));
    msg34_fail_period=numel(find(user_state(:,i)==STATE_MSG34_FAIL));
    EC(i)=preamble_transmission(i)/1000*Ptx+active_before_access_period/1000*Pidle+RAR_period/1000*Prx+backoff_period/1000*Pidle+msg1_success_period/1000*Prx+msg34_success_period/1000*Prx+msg34_fail_period/1000*Prx;
end
EC_sum(loop)=sum(EC);
loop=loop+1;
end
%{
display(sprintf('RACH_PERIOD    %d',RACH_PERIOD));
display(sprintf('user_no    %d',USER_NO));
display(sprintf('collision_probability    %d',collision_probability));
display(sprintf('success_probability    %d',success_probability));
display(sprintf('idle_probability    %d',idle_probability));
display(sprintf('access_success_probability    %d',access_success_probability));
display(sprintf('average_access_delay    %d',average_access_delay));
display(sprintf('average_preamble_transmission    %d',average_preamble_transmission));

%}


%{
figure;
plot(COV,transmission_times_total,'r',COV,repmat(total_preamble_transmission,1,numel(COV)),'b');
title('total transmission times vs. device #');
xlabel('number of devices');ylabel('total transmission times');legend('clustering','reference');
figure;
plot(COV,average_access_delay_cluster,'r',COV,repmat(average_access_delay,1,numel(COV)),'b');
title('average access delay vs. device #');
xlabel('number of devices');ylabel('average access delay');legend('clustering','reference');
%}

%%
figure;
scatter(COV,transmission_times_total,'r.');
hold on;
scatter(COV,total_preamble_transmission,'b*');
title('total transmission times vs. COV');
xlabel('COV');ylabel('total transmission times');legend('clustering','reference');
figure;
scatter(COV,average_access_delay_cluster,'r.');
hold on;
scatter(COV,average_access_delay,'b*');
title('average access delay vs. COV');
xlabel('COV');ylabel('average access delay');legend('clustering','reference');
figure;
scatter(COV,collision_cluster_rate,'r.');
hold on;
scatter(COV,collision_rate,'b*');
title('collision probability vs. COV');
xlabel('COV');ylabel('collision probability');legend('clustering','reference');
figure;
scatter(COV,success_cluster_rate,'r.');
hold on;
scatter(COV,success_rate,'b*');
title('success probability vs. COV.');
xlabel('COV');ylabel('success probability');legend('clustering','reference');
figure;
scatter(COV,EC_cluster_sum,'r.');
hold on;
scatter(COV,EC_sum,'b*');
title('energy consumption vs. COV');
xlabel('COV');ylabel('energy consumption');legend('clustering','reference');