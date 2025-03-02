% Load user configurable parameters & constants
Load_User_Configuarables
% Read Octopus Agile price for the next 24 hours. If any values are not
% available yet, then use the price for the same time period in the previous 24 hours.
Load_Agile
% Read weather forecast of ambient temperature, 2m above ground from https://api.open-meteo.com
Load_Weather
% Read solar forecast from https://api.solcast.com.au
if SolarFlag == 1
    Load_Solar
else
    PV_kWh_forecast = zeros(1,NumPlanPeriods);
end
export_price = ones(1,NumPlanPeriods) * 15.0;
% House background electricity consumption is approx 0.2kW.
% GET BETTER DATA FROM EMONPI
house_elec_background = ones(1,NumPlanPeriods) * 0.2 * Window_mins / 60; 
% Load Mitsubishi Ecodan 11.2kW Performance Matrix on a coarse mesh
Load_Mitsubishi_Ecodan_Perf_Matrix
Elec_kW_coarse = HP_Power_kW_coarse ./ COP_coarse;
% Set up the coarse mesh parameters
Setup_Coarse_Mesh
% Calculate the heat emitted by the rediators as a function of the flow
% temperature (fine mesh)
[RadT_degC,RadPower_kW] = Calc_Rad_Heat_v_FlowT(Tflow_coarse(1),Tflow_coarse(fMax_coarse),Tflow_inc,RadTempDrop,0.5*(TintMax_degC+TintMin_degC),RadExponent,RadHeatLossDatum,RadFlowTempDatum,RadTempDropDatum,RadRoomTempDatum);
% Find the maximum heat that the radiators can conceivably supply
HeatMax_kWh=max(RadPower_kW, [], 'all')*Window_mins/60;
% Set up a uniform heat supplied scale
hMax=ceil(HeatMax_kWh/HeatChunk_kWh)+1;
PossHeat = [1:hMax]' * HeatChunk_kWh;
% Linearly interpolate from the coarse mesh, to obtain the HP performance
% during each future time period, based on the forecast external
% temperature. We want the performance on a mesh which is finely spaced in
% terms of flow temperature, but retains the coarse mesh spacing in terms
% of HP power setting s.
P=griddedInterpolant({f_coarse,s_coarse,e_coarse},HP_Power_kW_coarse);
C=griddedInterpolant({f_coarse,s_coarse,e_coarse},COP_coarse);
Tflow_fine = RadT_degC;
Text_fine = T_ext_forecast_degC;
f_fine = interp1(Tflow_coarse,f_coarse,Tflow_fine);
e_fine = interp1(Text_coarse,e_coarse,Text_fine);
num_f_fine = size(f_fine,2);
PossHeat_kWh=NaN(hMax,NumPlanPeriods);
PossCOP=NaN(hMax,NumPlanPeriods);
PossTflow_degC=NaN(hMax,NumPlanPeriods);
PossElec_kWh=NaN(hMax,NumPlanPeriods);
PossPricePerkWh_p_per_kWh=NaN(hMax,NumPlanPeriods);
for t=1:NumPlanPeriods
    HP_Power_kW = P({f_fine,s_coarse,e_fine(t)});
    COP = C({f_fine,s_coarse,e_fine(t)});
    Elec_kW = HP_Power_kW ./ COP;
    % For each flow temperature, work out the heat pump power setting s at 
    % which the heat output matches the heat loss from the radiators
    for f=1:num_f_fine
        fMatch(1,f) = f_fine(1,f);
        if sum(isnan(HP_Power_kW(f,:))) >= 1
            sMatch(1,f) = NaN;
        else
            sMatch(1,f) = interp1(HP_Power_kW(f,:),s_coarse,RadPower_kW(f));
        end
    end
    MatchT_degC = RadT_degC;
    MatchHP_Power_kW = P(fMatch,sMatch,e_fine(t)*ones(1,num_f_fine));
    MatchCOP = C(fMatch,sMatch,e_fine(t)*ones(1,num_f_fine));
    MatchElec_kW = MatchHP_Power_kW ./ MatchCOP;
    % interp1 cannot cope with NaNs in the arrays it's interpolating FROM
    % (It CAN cope with NaNs in the arrays it's interpolating TO)
    sMatch_no_NaN = [];
    sMatch_no_NaN = sMatch(not(isnan(sMatch)));
    fMatch_no_NaN = [];
    fMatch_no_NaN = fMatch(not(isnan(sMatch)));
    MatchT_degC_no_NaN = [];
    MatchT_degC_no_NaN = MatchT_degC(not(isnan(sMatch)));
    MatchHP_Power_kW_no_NaN = [];
    MatchHP_Power_kW_no_NaN = MatchHP_Power_kW(not(isnan(MatchHP_Power_kW)));
    % Linearly interpolate to find fPoss and sPoss corresponding to PossHeat
    sPoss = interp1(MatchHP_Power_kW_no_NaN*Window_mins/60,sMatch_no_NaN,PossHeat);
    fPoss = interp1(sMatch_no_NaN,fMatch_no_NaN,sPoss);
    PossHeat_kWh(:,t) = PossHeat';
    PossCOP(:,t) = C(fPoss,sPoss,e_fine(t)*ones(hMax,1));
    PossTflow_degC(:,t) = interp1(fMatch_no_NaN , MatchT_degC_no_NaN , fPoss);
    PossElec_kWh(:,t) = PossHeat_kWh(:,t) ./ PossCOP(:,t);
    for h=1:hMax
        if PossElec_kWh(h,t) <= PV_kWh_forecast(t) - house_elec_background(t)
            PossPricePerkWh_p_per_kWh(h,t) = export_price(t) ./ PossCOP(h,t);
        else
            PossPricePerkWh_p_per_kWh(h,t) = ( ...
                ( max(PV_kWh_forecast(t) - house_elec_background(t),0) * export_price(t) + ...
                (PossElec_kWh(h,t) - max(PV_kWh_forecast(t) - house_elec_background(t),0) ) * import_price(t)) ...
                / PossElec_kWh(h,t)) ./ PossCOP(h,t);
        end
    end
    if DiagnosticPlotFlag == 1
        % Plot the coarse mesh data
        f2=figure;
        f2.Position = [910 90 890 890];
        % Subplot 1 is lines of constant flow temp against heat output for the heat pump
        subplot(3,1,1)
        title(strcat(string(valid_from_datetime(t),'yyyy-MM-dd'' ''HH:mm:ss''Z'),' External Temperature=',' ',num2str(T_ext_forecast_degC(t)),'degC'))
        axis([0 16 20 65])
        ylabel('Flow Temperature (degC)')
        hold on
        HP_Power_kW_coarse_int = P({f_coarse,s_coarse,e_fine(t)});
        COP_coarse_int = C({f_coarse,s_coarse,e_fine(t)});
        Elec_kW_coarse_int = HP_Power_kW_coarse_int ./ COP_coarse_int;
        for f=1:fMax_coarse
            plot(HP_Power_kW_coarse_int(f,:),Tflow_coarse(f)*ones(1,sMax_coarse),'-+')
        end
        plot(RadPower_kW,RadT_degC,'k-')
        plot(MatchHP_Power_kW,MatchT_degC,'ko');
        plot(PossHeat'*60/Window_mins,PossTflow_degC(:,t),'rx');
        % Subplot 2 is COP along lines of constant flow temperature, as a function of heat output for the heat pump
        subplot(3,1,2)
        axis([0 16 0 10])
        ylabel('COP')
        hold on
        for f=1:fMax_coarse
            plot(HP_Power_kW_coarse_int(f,:),COP_coarse_int(f,:),'-+')
        end
        plot(MatchHP_Power_kW,MatchCOP,'ko')
        plot(PossHeat'*60/Window_mins,PossCOP(:,t),'rx');
        % Subplot 3 is electricity consumed along lines of constant flow temperature, as a function of heat output for the heat pump
        subplot(3,1,3)
        axis([0 16 0 7])
        xlabel('Heat Power (kW)')
        ylabel('Electrical Power (kW)')
        hold on
        for f=1:fMax_coarse
            plot(HP_Power_kW_coarse_int(f,:),Elec_kW_coarse_int(f,:),'-+')
        end
        plot(MatchHP_Power_kW,MatchElec_kW,'ko')
        plot(PossHeat'*60/Window_mins,PossElec_kWh(:,t)*60/Window_mins,'rx');
        saveas(f2,strcat('Diagnostic_plots/',string(valid_from_datetime(t),'yyyy_MM_dd_HH_mm_ss'),'Z_External_Temperature=',replace(num2str(T_ext_forecast_degC(t)),'.','_'),'degC'),'jpeg')
        close all
    end
end

% House temperature modelling
Tint_degC=zeros(1,NumPlanPeriods);
HouseHeatLoss_kWh=zeros(1,NumPlanPeriods);
HouseHeatSupplied_kWh=zeros(1,NumPlanPeriods);
NumChunksSuppied=zeros(1,NumPlanPeriods);
Tint_degC(1,1) = TintStart_degC;
HouseHeatLoss_kWh(1,1)= Window_mins / 60 * HouseRateHeatLoss_kW_per_degC * (Tint_degC(1,1) - T_ext_forecast_degC(1,1));
for i=2:NumPlanPeriods
    Tint_degC(1,i) = Tint_degC(1,i-1) + (HouseHeatSupplied_kWh(1,i-1) - HouseHeatLoss_kWh(1,i-1)) / HouseHeatCapacity_kWh_per_degC;
    HouseHeatLoss_kWh(1,i) = Window_mins / 60 * HouseRateHeatLoss_kW_per_degC * (Tint_degC(1,i) - T_ext_forecast_degC(1,i));
end
cycle=0;
if DiagnosticPlotFlag == 1
    Generate_Heat_Plot
end
% CHECK. Could this while loop never finish
while Tint_degC(1,NumPlanPeriods) < min(Tint_degC(1,1),TintMax_degC)
    cycle = cycle + 1;
    for t=1:NumPlanPeriods
        if NumChunksSuppied(t) == 0
            [CheapestAdditionalHeat(t),hCheapestAdditionalHeat(t)] = min(PossPricePerkWh_p_per_kWh(1:hMax,t));
        else
            [CheapestAdditionalHeat(t),hCheapestAdditionalHeat(t)] = min(PossPricePerkWh_p_per_kWh(NumChunksSuppied(t)+1:hMax,t));
        end
    end
    tFirst = find(Tint_degC > TintMax_degC,1,'last') + 1;
    if isempty(tFirst)
        tFirst = 1;
    end
    tLast = find(Tint_degC < TintMin_degC,1,'first') - 1;
    if isempty(tLast)
        tLast = NumPlanPeriods;
    end
    ind=[];
    [MinPrice,ind] = min(CheapestAdditionalHeat(tFirst:tLast));
    t_min = ind + tFirst - 1;
    NumChunksSuppied(t_min) = NumChunksSuppied(t_min) + hCheapestAdditionalHeat(t_min);
    HouseHeatSupplied_kWh = NumChunksSuppied*HeatChunk_kWh;
    Tint_degC(1,1) = TintStart_degC;
    HouseHeatLoss_kWh(1,1)=0.5*HouseRateHeatLoss_kW_per_degC*(Tint_degC(1,1)-T_ext_forecast_degC(1,1));
    for i=2:NumPlanPeriods
        Tint_degC(1,i) = Tint_degC(1,i-1) + (HouseHeatSupplied_kWh(1,i-1) - HouseHeatLoss_kWh(1,i-1)) / HouseHeatCapacity_kWh_per_degC;
        HouseHeatLoss_kWh(1,i)=0.5*HouseRateHeatLoss_kW_per_degC*(Tint_degC(1,i)-T_ext_forecast_degC(1,i));
    end
    if DiagnosticPlotFlag == 1
        Generate_Heat_Plot
    end
end
Generate_Heat_Plot