% Read solar forecast from https://api.solcast.com.au
% This call generates up to 72 days of data, at 30 minute intervals.
% Some values may be NaN
SolarAPI=strcat('https://api.solcast.com.au/rooftop_sites/',SolcastSiteID,'/forecasts?format=json&api_key=',SolcastAPIkey);
Data = webread(SolarAPI);
num1 = size(Data.forecasts,1);
for i=1:num1
    datetime_scratch(1,i) = datetime(Data.forecasts(i).period_end,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''.0000000Z',format='yyyy-MM-dd''T''HH:mm:ss''Z',TimeZone='UTC')-minutes(30);
    PV_kW_forecast_scratch(1,i) = Data.forecasts(i).pv_estimate;
end
PV_kW_forecast = interp1(datetime_scratch,PV_kW_forecast_scratch,valid_from_datetime);
PV_kWh_forecast = PV_kW_forecast * Window_mins / 60; % Convert power (kW) to energy (kWh) based on the duration of the Agile cost period (30 minutes currently in the UK)
if DiagnosticPlotFlag == 1
    f4=figure;
    f4.Position = [10 90 1690 890];
    plot(datetime_scratch,PV_kW_forecast_scratch)
    hold on
    plot(valid_from_datetime,PV_kW_forecast,'ko')
    plot(valid_from_datetime,PV_kWh_forecast,'ro')
    TitleText = sprintf('%s %s %s %s %s %s','PV forecast from https://api.solcast.com.au and interpolation to next',num2str(PlanPeriod_hours),'hours (',num2str(Window_mins),'minute intervals )');
    title(TitleText)
    ylabel('Power (kW) or Energy (kWh)')
    saveas(f4,'PV_forecast_interpolation.jpg','jpeg')
end
clear Data datetime_scratch PV_kW_forecast_scratch;
close all