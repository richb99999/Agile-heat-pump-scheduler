Window_mins = 30;   % The Agile price window is 30 minutes long
% Currently only plan heating 24 hours in advance. I would like to plan a
% week ahead. This would entail estimating Agile prices further ahead
% eg see Guy Lipmans Agile Price forecast methodology, see ... 'https://github.com/gjlipman/smartmeter/tree/master/forecasts'
% and 'https://energy.guylipman.com/forecasts?region=B';
% I would also need to investigate getting a solar prediction 7 days in
% advance. I think getting an external temperature prediction 7 days in
% advance is no problem.
PlanPeriod_hours = 24;  
NumPlanPeriods = PlanPeriod_hours * 60 / Window_mins;
% LookupCalcFlag=0; % No longer used?
DiagnosticPlotFlag=0;
SolarFlag = 1;
% Installation specific Solcast data
SolcastSiteID = 'XXXXXXXXXXXXXXX';
SolcastAPIkey = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
% Installation specific house location for weather forecast
latitude = '52.9';
longitude = '-1.4';
% We will want to linearly interpolate the performance matrix to a finer
% mesh. The Ecodan flow temperature can be controlled in 0.5 degC
% increments.
Tflow_inc = 0.5;
% Set "chunk size" to 0.1 kWh when matching the heating requirement
HeatChunk_kWh = 0.1;
% Specify the heat emitted by the radiators at a datum operating point
RadHeatLossDatum = 4.5;  % kW
RadFlowTempDatum = 44.3; % degC
RadTempDropDatum = 3.6;  % degC
RadRoomTempDatum = 19.3; % degC
% Assume temperature drop through the radiators is always 5 degC 
RadTempDrop = 5.0; % degC
% Exponent for radiator (see https://www.purmo.com/docs/Purmo-technical-catalogue-radiators-full_PR_01_2014_EN_PL.pdf page 9)
RadExponent = 1.3358;
HouseRateHeatLoss_kW_per_degC = 0.195; % NEED TO VERIFY
HouseHeatCapacity_kWh_per_degC = 9.5; % NEED TO VERIFY
TintMax_degC = 20.0;    % Max permissible room temperature
TintMin_degC = 18.0;    % Min permissible room temperature
TintStart_degC = 18.5; % Room temperature at the start of the simulation
