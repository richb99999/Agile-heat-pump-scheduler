% Generate heating plot and save to .jpg file
Total_elec = 0;
Total_cost = 0;
for t=1:NumPlanPeriods
    if NumChunksSuppied(1,t) == 0
        DisplayTflow_degC(1,t) = 0;
        DisplayCOP(1,t) = 0;
        DisplayElec_kWh(1,t) = 0;
        DisplayPricePerkWh(1,t) = 0;
    else
        DisplayTflow_degC(1,t) = PossTflow_degC(NumChunksSuppied(1,t),t);
        DisplayCOP(1,t) = PossCOP(NumChunksSuppied(1,t),t);
        DisplayElec_kWh(1,t) = PossElec_kWh(NumChunksSuppied(1,t),t);
        DisplayPricePerkWh(1,t) = PossPricePerkWh_p_per_kWh(NumChunksSuppied(1,t),t);
        Total_elec = Total_elec + PossElec_kWh(NumChunksSuppied(1,t),t);
        HouseHeatSupplied_kWh(1,t),PossPricePerkWh_p_per_kWh(NumChunksSuppied(1,t),t)
        Total_cost = Total_cost + HouseHeatSupplied_kWh(1,t) * PossPricePerkWh_p_per_kWh(NumChunksSuppied(1,t),t);
    end
end
Total_heat = sum(NumChunksSuppied) * HeatChunk_kWh;
AvCOP = Total_heat / Total_elec;
f4=figure;
f4.Position = [10 90 1690 890];
title(strcat('Cycle=',num2str(cycle,'%04.f'),' : Total heat=',num2str(Total_heat),'kWh : Total elec=',num2str(Total_elec),'kWh : Av COP=',num2str(AvCOP),' : Total cost=£',num2str(Total_cost/100,'%.2f')))
yyaxis left
plot(valid_from_datetime,Tint_degC,'m-','DisplayName','Internal temperature (LH ax)')
hold on
plot(valid_from_datetime,TintMin_degC*ones(1,NumPlanPeriods),'m--','DisplayName','Min internal temperature (LH ax)')
plot(valid_from_datetime,TintMax_degC*ones(1,NumPlanPeriods),'m--','DisplayName','Max internal temperature (LH ax)')
plot(valid_from_datetime,T_ext_forecast_degC,'b--','DisplayName','External temperature forecast (LH ax)')
stairs(valid_from_datetime,DisplayTflow_degC,'r--','DisplayName','Flow temperature (LH ax)')
ylabel('Temperature (degC)')
yyaxis right
stairs(valid_from_datetime,HouseHeatSupplied_kWh,'r-','DisplayName','Heat supplied (RH ax)')
stairs(valid_from_datetime,-HouseHeatLoss_kWh,'c-','DisplayName','House heat loss (RH ax)')
stairs(valid_from_datetime,DisplayCOP,'k-','DisplayName','COP (RH ax)')
stairs(valid_from_datetime,DisplayElec_kWh,'-','DisplayName','Electrical energy (RH ax)','Color',[0.9290 0.6940 0.1250])
stairs(valid_from_datetime,DisplayPricePerkWh,'g-','DisplayName','Price per kWh of heat (RH ax)')
stairs(valid_from_datetime,import_price,'g--','DisplayName','Grid electricity price (RH ax)')
stairs(valid_from_datetime,PV_kWh_forecast - house_elec_background,'-','DisplayName','Net solar energy forecast (RH ax)','Color',[0.8500 0.3250 0.0980])
ylabel('kWh, COP, pence / kWh')
legend('Location','eastoutside','Orientation','vertical')
saveas(f4,strcat('Iterations/Cycle',num2str(cycle,'%04.f')),'jpeg')
close all
