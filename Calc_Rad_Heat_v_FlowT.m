function [TflowArray_degC,HeatArray_kW] = Calc_Rad_Heat_v_FlowT(TflowStart_degC,TflowStop_degC,TflowInc_degC,Tdrop_degC,Troom_degC,RadIndex,HeatRef_kW,TflowRef_degC,TdropRef_degC,TroomRef_degC)
% Calculate the heat emitted by the rediators as a function of the flow
% temperature. The formulas come from chrome-extension://efaidnbmnnnibpcajpcglclefindmkaj/https://www.purmo.com/docs/Purmo-technical-catalogue-radiators-full_PR_01_2014_EN_PL.pdf
% Calc the heat emitted for flow temperatures between TflowStart_degC and TflowStop_degC, with an increment of TflowInc_degC.
% Tdrop_degC is the temperature drop through the radiators (assumed to be a fixed number)
% Troom_degC is the room temperature.
% RadIndex is experimentally determined for each radiator type.
% HeatRef_kW is my estimate of the heat emitted by our radiators at a reference condition.
% TflowRef_deg is the flow temperature at the reference condition
% TdropRef_degC is the temperature drop through the radiators at the reference condition
% TroomRef_degC is the room temperature at the reference condition.
dtRef = TdropRef_degC/log((TflowRef_degC-TroomRef_degC)/(TflowRef_degC-TdropRef_degC-TroomRef_degC));
TflowArray_degC = TflowStart_degC:TflowInc_degC:TflowStop_degC ;
for n=1:size(TflowArray_degC,2)
    dtArray(1,n) = Tdrop_degC/log((TflowArray_degC(1,n)-Troom_degC)/(TflowArray_degC(1,n)-Tdrop_degC-Troom_degC));
    HeatArray_kW(1,n) = HeatRef_kW*(dtArray(1,n)/dtRef)^RadIndex;
end

