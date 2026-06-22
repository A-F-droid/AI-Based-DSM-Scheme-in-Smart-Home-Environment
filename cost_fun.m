   function[ Net_cost, x]=cost_fun(x)
   global Pd_e pvpluswind Pd_h Pd_e P_FC_min  Pd_h alpha beta shut_down P_FC_max ... 
P_FC_ramp_U P_FC_ramp_D p_fc_i_minus_1...
time_start W_init eff_ch eff_dch W_max ...
W_min P_b_ch_max P_b_dch_max T C_b C_gas_b C_U_b C_U_s MU MU1 ...
gen soc_max soc_min w_i_1... 
ev_bin ev_w_i ev_cap ev_cap var ev_charging_ub...
ev_w_f ncl NM FC BT TF EV SCH pev_main  Pw Pv


% gen=gen+1
% p_fc_i_minus_1= 0;%.95*P_FC_max;
x1=[];
offset = 3;







%% EV
if EV==1
    if SCH==1
        pev_var=x(1: var)';
        w_ev_i_minus_1=ev_w_i;
        soc_ev=zeros(var,1);
        w_ev_space_avail=ev_w_f-ev_w_i;
        num=randperm(var);
        no=0;
        if sum(pev_var)>w_ev_space_avail
            while sum(pev_var)> w_ev_space_avail
                no=no+1;
                pev_var(num(no))=0;
            end
        pev_var(num(no))=w_ev_space_avail-sum(pev_var); %or ev_w_f-(sum(pev_var)+ev_w_i)

        elseif sum(pev_var)<w_ev_space_avail
            while sum(pev_var)<w_ev_space_avail
                no=no+1;
                pev_var(num(no))=ev_charging_ub;
            end
            pev_var(num(no))=w_ev_space_avail -(sum(pev_var)-pev_var(num(no))); % or ev_w_f -(sum(pev_var)-pev_var(num(no))+ev_w_i);
        end
            var_count=0;
            pev=zeros(24,1);
            for i=1:24
                if ev_bin(i)==1
                    var_count=var_count+1;
                    pev(i,1)=pev_var(var_count);
                else
                    pev(i,1)=0;
                end
            end
            x1=[pev_var'];
    elseif SCH==0
        pev=pev_main;
    end
else
    pev=zeros(24,1);
end



%% BATTERY
% if BT==1
%     pb=x(var+25:var+48)';
%     soc_i_minus_1_current=soc_i_minus_1;
%     soc=zeros(1,24);
%     for i=1:24
%         if pb(i)<0
%             eff_b=eff_ch;
%         else
%             eff_b=1/eff_dch;
%         end
%         soc(i)= soc_i_minus_1_current - pb(i)*eff_b/W_max;
%         if soc(i)>soc_max
%             pb(i)=(soc_max-soc_i_minus_1_current)*W_max/eff_b;
%             soc(i)= soc_i_minus_1_current - pb(i)*eff_b/W_max;
%         elseif soc(i)<soc_min
%             pb(i)= (soc_i_minus_1_current - soc_min)*W_max/eff_b;
%             soc(i)= soc_i_minus_1_current - pb(i)*eff_b/W_max;
%         end
%         soc_i_minus_1_current=soc(i);
%     end
%     x1=[x1 pb'];
% else
%     pb=zeros(24,1);
% %     pb=[];
% end
if BT==1
    pb=x( var + 1: var + 24)';
    w_i_minus_1=w_i_1;
    w=zeros(1,24);
    p_ul=zeros(24,1); 
    for i=1:24
        w(i)= w_i_minus_1 - pb(i);
        if w(i)>W_max
            pb(i)=(W_max-w_i_minus_1);
            w(i)= w_i_minus_1 - pb(i);
        elseif w(i)<W_min
            pb(i)= (w_i_minus_1 - W_min);
            w(i)= w_i_minus_1 - pb(i);
        end
        
%         if pb(i)<0
%             p_ul(i)=Pd_e(i)+pev(i)-pfc(i)-pb(i)/eff_ch;
%             if p_ul(i)<0
%                 if (w(i)+abs(p_ul(i)))<W_max 
%                     pb(i)=pb(i)+p_ul(i)*eff_ch;
%                     w(i)=w(i)+abs(p_ul(i));
%                     if pb(i) < W_ch_max
%                         pfc(i)=pfc(i)-(W_ch_max-pb(i));
%                         pb(i)=W_ch_max;
%                         w(i)=w(i)-(W_ch_max-pb(i));
%                     end
%                     p_ul(i)=0;
%                 else
% 
%                 end
% 
%             end
%     else
%         p_ul(i)=Pd_e(i)+pev(i)-pfc(i)-pb(i)*eff_dch;
%     end
        
        
        
        w_i_minus_1=w(i);
        
        
        
        
    end
     x1=[x1 pb'];
else
    pb=zeros(24,1);
    eff_ch=1;
    eff_dch=1;
%     pb=[];
end


%% 

% p_ul=zeros(24,1);    
% for i=1:24
%     if pb(i)<0
%         p_ul(i)=Pd_e(i)+pev(i)-pfc(i)-pb(i)/eff_ch;
%         if p_ul(i)<0
%             if (W_max-w(i)) > abs(p_ul(i))
%                 pb(i)=pb(i)+p_ul(i,1)*eff_ch;
%                 if pb(i)
%                 end
% %                 w(i)=sum(pb(1:i));
%                 p_ul(i,1)=0;
%             else
%                 
%             end
%             
%         end
%     else
%         p_ul(i,1)=Pd_e(i)+pev(i)-pfc(i)-pb(i)*eff_dch;
%     end
% end
% x1=[x1 pb'];
%
%% FUEL CELL
if FC==1
    %%%%%%%%%%%%%%%%%% for constraints%%%%%%%%%%%%%%
    pfc=x( var + 25: var + 48)';
    p_fc_i_minus_1_current= p_fc_i_minus_1;
    for i=1:24
        if pfc(i) < p_fc_i_minus_1_current - P_FC_ramp_D;
            pfc(i) = p_fc_i_minus_1_current - P_FC_ramp_D;
        elseif pfc(i) > p_fc_i_minus_1_current + P_FC_ramp_U;
            pfc(i) = p_fc_i_minus_1_current + P_FC_ramp_U;
        end
        p_fc_i_minus_1_current=pfc(i);
    end
    x1=[x1 pfc'];
    %%%%%%%%%%%%%%%%%%%%%%%% FOR PLR AND EFF %%%%%%%%%
    PLR=pfc./P_FC_max;
    rTE=zeros(24,1);          %Variables prelocating
    eff_fc=zeros(24,1);
    for i=1:24
        if PLR(i)<0.05
            rTE(i)=0.6816; %FC system thermal to electric ratio,rTE,
            eff_fc(i)=0.2716;
        else
            eff_fc(i)=0.9033 .* PLR(i).^5 - 2.9996 .* PLR(i).^4 + 3.6503 .* PLR(i).^3-2.0704.*PLR(i).^2+0.4623.*PLR(i)+0.3747;
            rTE(i)=1.0785 .* PLR(i).^4 - 1.9739 .* PLR(i).^3 + 1.5005 .* PLR(i).^2 - 0.2817 .* PLR(i) + 0.6838;
        end
    end
 else
    pfc=zeros(24,1);
    rTE=zeros(24,1);          
    eff_fc=ones(24,1);
end
%% Non Critical Load
% Appliance scheduling
if ncl ==1
    t_iron = round(x(var + 49));
    t_wm   = round(x(var + 50));
    t_pump = round(x(var + 51));
    x1 = [x1 t_iron t_wm t_pump];
    P_sched = zeros(24,1);

    % Iron (1 hr)
    P_sched(t_iron) = P_sched(t_iron) + 1.0;

    % Washing Machine (2 hrs)
    P_sched(t_wm)   = P_sched(t_wm) + 0.8;
    P_sched(t_wm+1) = P_sched(t_wm+1) + 0.8;

    % Pump (1 hr)
    P_sched(t_pump) = P_sched(t_pump) + 1.2;
else
    P_sched = zeros(24,1);
end
export_penalty_factor = 2;
excess_penalty = zeros(24,1);

for i=1:24
    
    if pb(i)<0
        p_ul(i,1)=Pd_e(i) + P_sched(i)-pvpluswind(i)+pev(i)-pfc(i)-pb(i)/eff_ch;
    else
        p_ul(i,1)=Pd_e(i) + P_sched(i)-pvpluswind(i)+pev(i)-pfc(i)-pb(i)*eff_dch;
    end
end

% No export allowed
if NM == 0
    p_ul(p_ul < 0) = 0;
end


x = x1;
% p_ul=Pd_e+pev-pfc-pb;

%For heating load Power Calculations
P_fc_h= pfc .* rTE;
P_boiler =  Pd_h - P_fc_h;

% Cost Calculaitons
BoilerGas_cost = T * C_gas_b .* P_boiler; % Gas Costs
C_FC = T* C_gas_b * pfc ./eff_fc;
C_U = zeros(24,1);

buy_idx  = p_ul > 0;
sell_idx = p_ul <= 0;

% Always pay for buying
C_U(buy_idx) = C_U_b .* MU(buy_idx) .* p_ul(buy_idx) * T;
C_U(sell_idx) = C_U_s .* MU1(sell_idx) .* p_ul(sell_idx) * T;

all_cost = C_FC + C_U + BoilerGas_cost + abs(pb).*0.03 + excess_penalty;

lam=zeros(1,24);
for i=1:24
    lam(i)=max([0 ...
    P_fc_h(i)-Pd_h(i)]);
    all_cost(i)= all_cost(i) + 1000000*lam(i);
end

Net_cost = sum(all_cost);       %8 gives approximate value
