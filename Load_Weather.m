% Read weather forecast of ambient temperature, 2m above ground from https://api.open-meteo.com
% This call generates up to 7 full days of data, at hourly intervals.
% Some values may be NaN.
WeatherAPI1=strcat('https://api.open-meteo.com/v1/forecast?latitude=',latitude,'&longitude=',longitude,'&hourly=temperature_2m&models=ukmo_seamless');
Data1 = webread(WeatherAPI1);
num1=size(Data1.hourly.temperature_2m,1);
for i=1:num1
    datetime_scratch(1,i)=datetime(Data1.hourly.time(i),'InputFormat','yyyy-MM-dd''T''HH:mm',format='yyyy-MM-dd''T''HH:mm:ss''Z',TimeZone='UTC');
    T_ext_forecast_scratch(1,i)=Data1.hourly.temperature_2m(i);
end
T_ext_forecast_degC=interp1(datetime_scratch,T_ext_forecast_scratch,valid_from_datetime);
if DiagnosticPlotFlag == 1
    f3=figure;
    f3.Position = [10 90 1690 890];
    plot(datetime_scratch,T_ext_forecast_scratch)
    hold on
    plot(valid_from_datetime,T_ext_forecast_degC,'ko')
    TitleText = sprintf('%s %s %s %s %s %s','Temperature forecast from api.open-meteo.com and interpolation to next',num2str(PlanPeriod_hours),'hours (',num2str(Window_mins),'minute intervals )');
    title(TitleText)
    ylabel('temperature 2m (degC)')
    saveas(f3,'T_external_forecast_interpolation.jpg','jpeg')
end
clear Data1 datetime_scratch T_ext_forecast_scratch;
close all