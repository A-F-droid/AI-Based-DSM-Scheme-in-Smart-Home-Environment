%% Initialize Parameters
clearvars -except v1 v2;
startCode=tic;
d=datestr(rem(now,1))
% format long g
format bank

global PNCL_set PNCL_max Pd_e pvpluswind P_FC_min  Pd_h alpha beta shut_down P_FC_max ... 
P_FC_ramp_U P_FC_ramp_D p_fc_i_minus_1 time_start W_init eff_ch eff_dch W_max ...
W_min W_ch_max W_dch_max T C_b C_gas_b C_U_b C_U_s MU MU1 w_i_1 ...
gen soc_max soc_min ev_bin ev_w_i ev_cap var ev_charging_ub...
ev_w_f ncl NM FC BT TF EV pev_main SCH Pw Pv
rng(1)

iterations=1;
cases=14;
% eff_charging(1:10,1)=1;
% eff_charging(11:20,1)=.927;
% 
% eff_discharging(1:10,1)=1;
% eff_discharging(11:20,1)=.971;

% cross=rand(iterations,cases);
% cross=round(cross*10)/10;
% mut=.1+(.3-.1)*rand(iterations,cases);
% mut=round(mut*10)/10;
Net_Cost_Random= zeros(iterations,cases);
Random_Powers=cell(iterations,cases);
Random_Powers_Battery=cell(iterations,cases);
Random_Costs=cell(iterations,cases);
Random_GADATA=cell(iterations,cases);
Random_states=cell(iterations,cases);
for iter=1:iterations
    startIterations(iter)=tic;
for n=1:14
%     gaDat.FieldD=[];
    gaDat=[];
    iter 
    n
    startCases(n)=tic;
    %% DEFAULT VALUES
ElectricVehicle='';  %'OFF'
% EV_scheduling='';
WIND='';
PV='';
RES='';
NonCriticalLoad = '';
FUELCELL=''; %ON
BATTERY=''; %OFF 
NET_METERING = '';   % or 'OFF'
TARRIF='';
EV_scheduling='';
EV=0; FC=0; BT=0; %not connected
TF=0;             %constant tariff    
SCH=0;            %NO scheduling

switch n

case 1   % Base
    % Nothing ON
    TARRIF='VARIABLE';

case 2   % Case 1
    RES='ON';
    TARRIF='VARIABLE';

case 3   % Case 2
    RES='ON';
    BATTERY='ON';
    TARRIF='VARIABLE';

case 4   % Case 3
    RES='ON';
    FUELCELL='ON';
    BATTERY='ON';
    TARRIF='VARIABLE';

case 5   % Case 4
    RES='ON';
    FUELCELL='ON';
    BATTERY='ON';
    TARRIF='VARIABLE';
    NonCriticalLoad = 'yes';

case 6   % Case 5
    RES='ON';
    FUELCELL='ON';
    BATTERY='ON';
    TARRIF='VARIABLE';
    ElectricVehicle='ON';
    NonCriticalLoad = 'yes';

case 7   % Case 6
    RES='ON';
    FUELCELL='ON';
    BATTERY='ON';
    TARRIF='VARIABLE';
    ElectricVehicle='ON';
    EV_scheduling='YES';
    NonCriticalLoad = 'yes';

case 8   % Base
    % Nothing ON
    TARRIF='VARIABLE';
    NET_METERING = 'ON';

case 9   % Case 1
    RES='ON';
    TARRIF='VARIABLE';
    NET_METERING = 'ON';

case 10   % Case 2
    RES='ON';
    BATTERY='ON';
    TARRIF='VARIABLE';
    NET_METERING = 'ON';

case 11   % Case 3
    RES='ON';
    FUELCELL='ON';
    BATTERY='ON';
    TARRIF='VARIABLE';
    NET_METERING = 'ON';

case 12   % Case 4
    RES='ON';
    FUELCELL='ON';
    BATTERY='ON';
    TARRIF='VARIABLE';
    NonCriticalLoad = 'yes';
    NET_METERING = 'ON';

case 13   % Case 5
    RES='ON';
    FUELCELL='ON';
    BATTERY='ON';
    TARRIF='VARIABLE';
    ElectricVehicle='ON';
    NonCriticalLoad = 'yes';
    NET_METERING = 'ON';

case 14   % Case 6
    RES='ON';
    FUELCELL='ON';
    BATTERY='ON';
    TARRIF='VARIABLE';
    ElectricVehicle='ON';
    EV_scheduling='YES';
    NonCriticalLoad = 'yes';
    NET_METERING = 'ON';

end
% end
% for a=1:3
% ElectricVehicle='ON';  %'OFF'
% FUELCELL='ON'; %ON
% BATTERY='aON'; %OFF 
% TARRIF='VARIABLE';
%% Loading Electrical (P_e_L) and Heading (P_h_L) Loads 
load('Demand_Electric_and_Heating');    
%Demands
Pd_e_Normalized=P_e_L/1.8;
Pd_h_Normalized=P_h_L/2;

Pd_e=Pd_e_Normalized*1.8;
Pd_h=Pd_h_Normalized*2;
%% TARRIF
TF = strcmp(TARRIF,'VARIABLE');
if TF==1
    load('Electricity_tarrif(1 .9 .78 ).mat');
    load('MU1.mat');
    MU = electricity_tarrif_per_hour; %ones(1,24)';
    MU1 = MU1;
else MU=ones(24,1);
end
%% LOAD PV AND WIND
load('PV_Power');
load('Wind_Power');

Pw=Wind_Power;
Pv=PV_Power;
RES_ON = strcmp(RES,'ON');

if (RES_ON)
    pvpluswind= Pv + Pw;
else
    pvpluswind = zeros(24,1);
end



% %% Uncertainty
% scenarios = 50*iter;
% 
% sigma_load = 0.08;
% sigma_res  = 0.20;
% 
% Pd_s  = zeros(24,scenarios);
% RES_s = zeros(24,scenarios);
% 
% Pd_s(:,1)  = 0.9 * Pd_e;     % low load
% RES_s(:,1) = 1.2 * pvpluswind;  % high RES
% 
% Pd_s(:,2)  = 1.2 * Pd_e;     % high load
% RES_s(:,2) = 0.6 * pvpluswind;  % low RES
% 
% Pd_s(:,3)  = 1.0 * Pd_e;     % normal
% RES_s(:,3) = 1.0 * pvpluswind;
% 
% Pd_s(:,4)  = 1.3 * Pd_e;     % extreme load
% RES_s(:,4) = 0.4 * pvpluswind;  % extreme low RES
% 
% for s = 5:scenarios
% 
%     Pd_s(:,s)  = Pd_e .* (1 + sigma_load*randn(24,1));
%     RES_s(:,s) = pvpluswind .* (1 + sigma_res*randn(24,1));
% 
%     % No negative renewable
%     RES_s(RES_s(:,s)<0,s) = 0;
% end
NM = strcmp(NET_METERING,'ON');
%% Non Critical Load
ncl= strcmp(NonCriticalLoad,'yes');
if ncl == 1
    lb_appliances = [18 8 6];
    ub_appliances = [23 19 10]; % note WM upper = 20-1
else 
    lb_appliances = [];
    ub_appliances = [];
end

%% FUEL CELL
FC= strcmp(FUELCELL,'ON');
if FC==1
    % Fuel Cell Data
    alpha = 0.15;       %Fuel cell cold startup cost, ? ($)
    beta=0.05;          %Fuel cell hot startup cost, ? ($)
    shut_down = 0.00;   %Fuel cell shutdown cost ($)
    P_FC_max = 1.2;     % 4 Maximum limit of fuel cell power,
    P_FC_min = 0.05;    %Minimum limit of fuel cell power,
    P_FC_ramp_U=.75;%.75;%1.25;  %*.63--2.5 Upper limit of ramp rate of fuel cell,
    P_FC_ramp_D =.9;%.9;%1.5;  %*.75--- 3 Lower limit of ramp rate of fuel cell,
    time_start = 0.75;  %Fuel cell startup time (hr)
    p_fc_i_minus_1= .5*P_FC_max;
    lb_fc(1,1:24)=P_FC_min;
    ub_fc(1,1:24)=P_FC_max;
else
    
    lb_fc=[];
    ub_fc=[];
end
BT = strcmp(BATTERY,'ON');
if BT==1
    % Battery Data
    W_init = 0.00;      %Initial energy in battery,
    W_max=3;       %Maximum energy in battery (kWh),
    W_min =	0.00;       %Minimum energy in battery (kWh),
    eff_ch = 1;%.927;%eff_charging(iter);%.927; %1;      %Charging efficiency of battery (p.u),
    eff_dch =1; %.971;;%eff_discharging(iter);%.971; %1;     %Discharging efficiency of battery  (p.u.),
    W_ch_max =-.75;%/eff_ch;   %Upper limit of battery charging rate (kW),
    W_dch_max = 2.25;%*eff_dch;   %Upper limit of battery discharging rate (kW),
    C_b = 0.00;         %Operation and maintenance cost of battery ($/kW), 
    %Upper and Lower Limit of battery
    lb_b(1,1:24)=W_ch_max;
    ub_b(1,1:24)=W_dch_max;
    w_i_1=0;
    soc_max = 1;
    soc_min = 0;

else
    lb_b=[];
    ub_b=[];
end


%% EV
EV = strcmp(ElectricVehicle,'ON');
SCH=strcmp(EV_scheduling,'YES');

if (EV==1)
    ev_to=7;
    ev_ti=17;
    ev_cap=16;
    ev_w_f=ev_cap;
    mi2km=1.60934400579467;
    distance=60*mi2km; 
    ev_range_per_charge=62*mi2km;
    ev_eff=ev_range_per_charge/ev_cap;
    ev_w_i=ev_w_f-distance/ev_eff;
    ev_charging_ub=3.3;
    ev_charging_lb=0;
    ev_bin=ones(24,1);
    for i=(ev_to+1):ev_ti
        ev_bin(i)=0;
    end
    var=0;
    for i=1:24
        if ev_bin(i)==1
            var=var+1;
        end
    end
    if SCH==1
        ub_ev(1,1:var)= ev_charging_ub;
        lb_ev(1,1:var)= ev_charging_lb;
    elseif SCH==0
        
        pev_main=zeros(24,1); 
        w_i_minus_1=ev_w_i;
        w=zeros(24,1);
        for i=(ev_ti+1):24
            pev_main(i)=ev_charging_ub;
            w(i)=w_i_minus_1+pev_main(i);
            if w(i)>ev_w_f
                pev_main(i)=ev_w_f-w_i_minus_1;
                w(i)=w_i_minus_1+pev_main(i);break
            else
                w_i_minus_1=w(i);
            end
        end
        if round(sum(pev_main)+ev_w_i)<ev_w_f
            for i=1:(ev_to)  
                pev_main(i)=ev_charging_ub;
                w(i)=w_i_minus_1+pev_main(i);
                if w(i)>ev_w_f
                    pev_main(i)=ev_w_f-w_i_minus_1;
                    w(i)=w_i_minus_1+pev_main(i);break
                else w_i_minus_1=w(i);
                end
            end
        end
        
        
        ub_ev=[];
        lb_ev=[];
        var=0;
    end
            
        
else
    ub_ev=[];
    lb_ev=[];
    var=0;
end

%% MIX
T = 1.00;           %Length of time interval (hr),
C_gas_b = 0.05;     %Cost of purchasing natural gas ($/kW), 
C_U_b = 0.13;       %Cost of purchasing electricity from utility ($/kW), 
C_U_s = 0.07;
% Initial Parameters
Tini=1;
Tfinal=24;
num=(Tini:Tfinal)';
gen=0;              % To count Generations for debug


lb = [lb_ev lb_b lb_fc lb_appliances];
ub = [ub_ev ub_b ub_fc ub_appliances];
gaDat.FieldD=[lb; ub];

    
    
%% Basic GA parameters

% Parameters that could be defined by user, in other case, there is a default value
% gaDat.MAXGEN={gaDat.NVAR*20+10}; % Number of generation, gaDat.NVAR*20+10 by default
% gaDat.NIND={gaDat.NVAR*50} ;   % Size of the population, gaDat.NVAR*50 by default
if ~isempty(gaDat.FieldD)

    gaDat.alfa=1;                % Parameter for linear crossover, 0 by default
    gaDat.Pc= .5;%cross(iter,n);                % Crossover probability, 0.9 by default
    gaDat.Pm=.1;%mut(iter,n);                % Mutation probability, 0.1 by default
    gaDat.Objfun='cost_fun';
    % gaDat.MAXGEN=1500;
    % gaDat.NIND=5000;
    gaDat.MAXGEN=2000;
    gaDat.NIND = 500;

    addpath('C:\Users\as comp\Downloads\1st paper')
    %gaDatOutput=ga(gaDat);
    gaDatOutput = igwo(gaDat);
    %gwoDat = gaDat;       % reuse same bounds/settings
    %gwoDat.Objfun = 'cost_fun';

    %gwoDatOutput = gwo(gwoDat);
    %gaDatOutput.xmin = gwoDatOutput.xmin;
    rmpath('C:\Users\as comp\Downloads\1st paper')

else

    gaDatOutput.xmin = [];
    gaDatOutput.trace = [];

end

%% RESULTS
[NET_TOTAL_COST, xmin_fixed] = cost_fun(gaDatOutput.xmin);

%%  Battery calculations
offset = 3;
if BT==1
    pb_wrt_battery=xmin_fixed(var + 1:var + 24)';
%     soc_i_minus_1=0;
    w_battery=zeros(24,1);
    pb_wrt_grid=zeros(24,1);
    for i=1:24
        if pb_wrt_battery(i)<0
            eff_b=1/eff_ch;
        else
            eff_b=eff_dch;
        end
        w_battery(i,1)= w_i_1 - pb_wrt_battery(i);
        pb_wrt_grid(i,1)=pb_wrt_battery(i)*eff_b;
        w_i_1=w_battery(i);
    end
    SOC_Battery=w_battery./W_max*100;
    All_Powers_Battery=table(pb_wrt_battery,pb_wrt_grid,w_battery,SOC_Battery);
else
    pb_wrt_battery=zeros(24,1);
    pb_wrt_grid=zeros(24,1);
    SOC_Battery=zeros(24,1);
     All_Powers_Battery=0;
end

    %% FC calculations
if FC==1
    P_fc_el = xmin_fixed(var + 25:var + 48)';
PLR = P_fc_el ./P_FC_max;
rTE=zeros(24,1);
eff_fc=zeros(24,1);
for i=Tini:Tfinal
    
        if PLR(i)<0.05
            rTE(i)=0.6816; %FC system thermal to electric ratio,rTE, with stack not running
            eff_fc(i)=0.2716;
        else
            eff_fc(i)=0.9033 .* PLR(i).^5 - 2.9996 .* PLR(i).^4 + 3.6503 .* PLR(i).^3-2.0704.*PLR(i).^2+0.4623.*PLR(i)+0.3747;

            rTE(i)=1.0785 .* PLR(i).^4 - 1.9739 .* PLR(i).^3 + 1.5005 .* PLR(i).^2 - 0.2817 .* PLR(i) + 0.6838;
        end
end

else
    P_fc_el=zeros(24,1);
    rTE=zeros(24,1);
    eff_fc=ones(24,1);
end

%% Non Critical Load
if ncl ==1
    t_iron = round(xmin_fixed(var + 49));
    t_wm   = round(xmin_fixed(var + 50));
    t_pump = round(xmin_fixed(var + 51));

    P_sched = zeros(24,1);

    P_sched(t_iron) = P_sched(t_iron) + 1.0;

    P_sched(t_wm)   = P_sched(t_wm) + 0.8;
    P_sched(t_wm+1) = P_sched(t_wm+1) + 0.8;

    P_sched(t_pump) = P_sched(t_pump) + 1.2;
else
    P_sched = zeros(24,1);
end
%% EV calculations

if EV==1
    pev=zeros(24,1);
    count=0;
    Power_EV=zeros(24,1);
    W_ev=zeros(24,1);
     if SCH==1
        pev_var=xmin_fixed( 1:var)';
        for i=1:24
            if ev_bin(i)==1
                count=count+1;
                Power_EV(i,1)=pev_var(count);
                pev(i,1)=pev_var(count);
            else
                Power_EV(i,1)=0;
                pev(i,1)=NaN;
            end
        end
           
        w_i_minus_1=0;
        SOC_ev=zeros(24,1);
        pev(ev_ti,1)=ev_w_i;
        for i=(ev_ti):24
            W_ev(i,1)= (pev(i)+w_i_minus_1);
            SOC_ev(i,1)= W_ev(i,1)/ev_cap*100;
            w_i_minus_1=W_ev(i,1);
        end
        for i=1:(ev_to) 
             W_ev(i,1)= (pev(i)+w_i_minus_1);
             SOC_ev(i,1)= W_ev(i,1)/ev_cap*100;
             w_i_minus_1=W_ev(i,1);
        end
        
    elseif SCH==0
        pev_var=pev_main;
        for i=1:24
            if ev_bin(i)==1
                Power_EV(i,1)=pev_var(i);
                pev(i,1)=pev_var(i);
            else
                Power_EV(i,1)=0;
                pev(i,1)=NaN;
            end
        end
              
        w_i_minus_1=0;
        SOC_ev=zeros(24,1);
        pev(ev_ti,1)=ev_w_i;
        for i=(ev_ti):24
            W_ev(i,1)= (pev(i)+w_i_minus_1);
            SOC_ev(i,1)= W_ev(i,1)/ev_cap*100;
            w_i_minus_1=W_ev(i,1);
        end
        for i=1:(ev_to) 
            W_ev(i,1)= (pev(i)+w_i_minus_1);
            SOC_ev(i,1)= W_ev(i,1)/ev_cap*100;
            w_i_minus_1=W_ev(i,1);
        end
    end
else
    Power_EV=zeros(24,1);
    SOC_ev=zeros(24,1);
    W_ev=zeros(24,1);
end




%% 
    P_utility_raw = Pd_e + P_sched + Power_EV ...
                - P_fc_el - pb_wrt_grid - pvpluswind;

if NM == 1
    P_utility = P_utility_raw;
else
    for i=1:24
        if P_utility_raw(i)<0
            pb_wrt_grid(i) = pb_wrt_grid(i) + P_utility_raw(i);
        end
    end
    P_utility = max(0 , P_utility_raw);
end
    

P_fc_h= P_fc_el .* rTE;
P_boiler=Pd_h - P_fc_h;
all_powers = [num Pd_e P_sched pvpluswind Power_EV SOC_ev P_fc_el pb_wrt_battery pb_wrt_grid P_utility Pd_h P_fc_h P_boiler ];
all_powers_TABLE = table(num, Pd_e, P_sched, pvpluswind, Power_EV,SOC_ev, P_fc_el, pb_wrt_battery, pb_wrt_grid ,SOC_Battery,P_utility, Pd_h ,P_fc_h, P_boiler);
% all_powers_TABLE.Properties.VariableNames = {'Number' 'ElectricalDemand' 'EV_Power' 'Fuel Cell Electrical'};

%% Calculation of COSTS
BoilerGas_cost=T*C_gas_b.*P_boiler;
FC_cost=T*C_gas_b*P_fc_el./eff_fc;

Utility_cost = zeros(24,1);

buy_idx  = P_utility > 0;
sell_idx = P_utility <= 0;
    
Utility_cost(buy_idx)  = C_U_b .* MU(buy_idx) .* P_utility(buy_idx) * T;
Utility_cost(sell_idx) = C_U_s .* MU1(sell_idx) .* P_utility(sell_idx) * T;
Total_Cost_perHour = BoilerGas_cost + FC_cost + Utility_cost;

% all_costs = [num BoilerGas_cost FC_cost Utility_cost Total_Cost_perHour];
all_costs_TABLE = table(num, BoilerGas_cost, FC_cost, Utility_cost, Total_Cost_perHour);


Net_Cost_Random(iter,n)= NET_TOTAL_COST
Random_Powers{iter,n}=all_powers_TABLE;
Random_Powers_Battery{iter,n}=All_Powers_Battery;
Random_Costs{iter,n}=all_costs_TABLE;
Random_GADATA{iter,n}=gaDatOutput;
Random_states{iter,n}=[EV TF FC BT];
% formatSpec = string('Workspace is: %d %d');
eval(sprintf('save workspaces%d-%d.mat',iter,n));
tm_1_case(n)=toc(startCases(n))/60;
datestr(rem(now,1))
end
tm_all_cases(iter)=toc(startIterations(iter))/60;
end
[minunumCOST,AT_NO]=min(Net_Cost_Random);
minunumCOST_AT_NO=[AT_NO ;minunumCOST];

%% Writing Tables

% warning('off','MATLAB:xlswrite:AddSheet')
% xlswrite('Powers_and_Costs.xlsx',Net_Cost_Random','Net_Cost');
% xlswrite('Powers_and_Costs.xlsx',minunumCOST_AT_NO,'Net_Cost','B1') 
% 
% for s=3:3
%     
%     my_sheet_powers = sprintf( 'POWER%s',num2str(s) );
%     my_sheet_costs = sprintf( 'COSTS%s',num2str(s) );
%     writetable(Random_Powers{1,s},'Powers_and_Costs.xlsx','Sheet',my_sheet_powers,'Range','A1');
%     writetable(Random_Costs{1,s},'Powers_and_Costs.xlsx','Sheet',my_sheet_costs,'Range','A1');
% end
tm_ALL=toc(startCode)/60;
datestr(rem(now,1))


