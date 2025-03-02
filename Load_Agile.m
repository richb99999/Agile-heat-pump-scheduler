% Read Octopus Agile price for the next 24 hours. If any values are not
% available yet, then use the price for the same time period in the previous 24 hours.
AgileAPI1='https://api.octopus.energy/v1/products/AGILE-24-10-01/electricity-tariffs/E-1R-AGILE-24-10-01-B/standard-unit-rates/?period_from='; 
AgileAPI2='&period_to=';
DateTimeNow=datetime('now',format='yyyy-MM-dd''T''HH:mm:ss''Z',TimeZone='UTC');
DateTimeFuture=DateTimeNow+hours(24);
DateTimePast=DateTimeNow-hours(24);
DateStrNow=string(DateTimeNow);
DateStrFuture=string(DateTimeFuture);
DateStrPast=string(DateTimePast);
api = strcat(AgileAPI1,DateStrNow,AgileAPI2,DateStrFuture);
Data1 = webread(api);
api = strcat(AgileAPI1,DateStrPast,AgileAPI2,DateStrNow);
Data2 = webread(api);
num1=min(Data1.count,NumPlanPeriods);
for i=1:num1
    valid_from_datetime(1,num1+1-i)=datetime(Data1.results(i).valid_from,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z',format='yyyy-MM-dd''T''HH:mm:ss''Z',TimeZone='UTC');
    valid_to_datetime(1,num1+1-i)=datetime(Data1.results(i).valid_to,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z',format='yyyy-MM-dd''T''HH:mm:ss''Z',TimeZone='UTC');
    import_price(1,num1+1-i)=Data1.results(i).value_inc_vat;
end
% 
num2=Data2.count;
for i=2:48-num1+1
    valid_from_datetime(1,48+2-i)=datetime(Data2.results(i).valid_from,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z',format='yyyy-MM-dd''T''HH:mm:ss''Z',TimeZone='UTC')+hours(24);
    valid_to_datetime(1,48+2-i)=datetime(Data2.results(i).valid_to,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z',format='yyyy-MM-dd''T''HH:mm:ss''Z',TimeZone='UTC')+hours(24);
    import_price(1,48+2-i)=Data2.results(i).value_inc_vat;
end
clear Data1 Data2;