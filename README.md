# Agile-heat-pump-scheduler
Algorithm to schedule a specific heat pump installation to operate in a way which minimises running costs on a particular day

This algorithm schedules our air source heat pump (ASHP) to operate in a way which minimises the electricity cost when running on a time-of-use tariff such as Octopus Agile or Intelligent Octopus Go. My motivation for sharing is that people will only willingly switch to heat pumps in large numbers if the running costs are substantially lower than mains gas, to offset the higher upfront cost. See https://www.linkedin.com/pulse/running-my-heat-pump-half-cost-gas-boiler-rachel-lee-g9k4e%3FtrackingId=SNamMLMKTDGrm%252BppsjrBlg%253D%253D/?trackingId=SNamMLMKTDGrm%2BppsjrBlg%3D%3D for an example of a good quality heat pump installation in the UK which is reported to be half the running cost of mains gas, which is encouraging. This algorithm should reduce running cost even further, so it has the potential to hasten ASHP adoption in the UK, if it is widely adopted. I suspect my algorithm works in much the same way as the algorithm built into the commercially available Homely Smart Thermostat, but I have a Misubishi Ecodan, which is not compatible with a Homely.

The idea is to answer questions such as - is it cheaper to heat at night when electricity is generally cheaper on an agile tariff, but it's also usually colder outside, so that the heat pump will be a bit less efficient? The schedule should keep the room temperature within a comfortable range throughout the day - we have it set to no higher than 20 degC and no colder than 18 degC in the lounge.

The algorithm is tailored to our specific heat pump & installation, but the code could be modified to accommodate a different make & model of heat pump or installation. 

I used the wonderful OpenEnergy heat pump monitoring system to estimate the heat loss and heat capacity coefficients for our 1930s 4-bed semi. The calculation is as described here (https://community.openenergymonitor.org/t/house-thermal-inertia-and-roomstat-setback-some-cautionary-notes/27995). Our heat loss coefficient is 0.325 kW/degC, and our heat capacity coefficient is 14.9 kWh/degC

![20250221_140657](https://github.com/user-attachments/assets/b44cec3c-c6cf-4ddf-8e39-74c0185ebfe6)

The OpenEnergy heat pump monitoring system was also used to estimate how much energy our radiators can emit at a particular flow temperature when the heating system is running in steady state – say after 2 hours at the same flow temperature. This number is a major factor in determining how efficiently your heat pump works, and how much heat it can actually pump out in practise. An alternative approach would be to estimate what your radiators emit using tables such as those from Purmo.com below - but you would need to be a bit careful. For example, most of our upstairs radiators are turned right down, because I can only sleep if the bedroom is quite cold. So it would be difficult to calculate how much heat our radiators can actually emit at a particular flow temperature using this theoretical approach. I prefer to measure it experimentally. That said, the experimental approach is quite time-consuming, so I only carried it out at one flow temperature. Our radiators emit about 4.5 kW with a flow temperature of 44.3 degC and a return temperature of 40.7 degC, when the room temperature is 19.3 degC (see conditions at 5:00 in the plot below). I used the approach set out here (https://www.purmo.com/docs/Purmo-technical-catalogue-radiators-full_PR_01_2014_EN_PL.pdf page 9) to model the steady state heat output by the radiators at other flow temperatures (I assumed a constant 5 degC difference between flow and return temperatures).

![image](https://github.com/user-attachments/assets/eab4ea65-6dc8-4296-936d-8b967f3ffd28)

I have modelled the performance of our Mitsubishi Ecodan 11.2 kW HP in terms of COP & heat output, for different flow temperatures and power settings, as external temperature varies, by interpolating the tables that Mitsubishi publish. (Ecodan_ATW_Databook_R32_Vol5.3_.pdf page 61 of 442 for our 11.2 kW model). This data is hard coded into Load_Mitsubishi_Ecodan_Perf_Matrix_V5.m . The data had to be slightly modified so that Matlab could interpolate it without crashing. (For example, you might expect that heat output would increase as the compressor power increases, with other variables kept the same. Most of the time that is the case. But for example heat output & COP are 10.1kW & 3.00 at nominal power on a -10 degC day with a flow temp of 25 degC. But at max power, the heat output remains at 10.1kW but the COP drops to 2.80. This would cause any interpolation routine to crash, so I modified the heat output by a tiny amount at max power to 10.11kW, which fixed the problem)

At the time the algorithm was written, we were on Agile, and we have solar panels, but no battery storage. Octopus pays me 15p/kWh for exports, so I use this as the cost of my solar if I feed it to the heat pump instead. I don’t have a storage battery yet, so the algorithm doesn’t account for this potential method of further reducing running costs. The algorithm runs on our PC at about 4pm every day, when the cost of Agile is released for the day ahead. It also reads in free forecasts for solar output from the solar panels on our roof (https://api.solcast.com.au) and outside temperature (https://api.open-meteo.com). You would need to set up accounts for Solcast & Open-Meteo, and generate your own API keys. Solcast needs to know the size, orientation & location etc of your solar panels. Open-Meteo just needs to know your location. I know roughly how much electricity will be used for other purposes around the house such as cooking, lights, computers etc at different times of the day (Open Energy again!), which eats into any solar that’s available. (In the absence of solar panels, just set up the input flag accordingly. In that case, there’s no benefit from specifying how much electricity will be used for other purposes around the house at different times of the day).

The plot below shows what the Ecodan should be capable of doing when the external temperature is 7.1 degC. The circular symbols show what steady state performance is possible with our radiators (I wasn’t joking when I said our installation was bad).

![image](https://github.com/user-attachments/assets/97d19fe9-7e66-4ba4-b24b-75f308c5e815)

When it’s colder outside, the performance drops, as expected

![image](https://github.com/user-attachments/assets/e021c793-2673-4fcd-913a-e24b6c55b896)

The algorithm weighs up all the different factors, and works out when the heat pump should run, and the optimal power output & flow temperature to minimise running cost, while keeping the room temperature between 18 and 20 degC. On Agile it usually works out cheapest for us to heat in the early hours of the morning, and in the early afternoon. But if it’s really cold, then the heat pump needs to run for longer, and the algorithm accounts for that.

The plot below shows what the algorithm comes up with on a cold day. The cost was getting a bit eye-watering on Agile, so we switched to Intelligent Octopus Go, now that our Nissan Leaf/Myenergi Zappi car charger combo is compatible. At some stage, I will need to modify the program to work with the new tariff.

![image](https://github.com/user-attachments/assets/4192758b-d826-4ad7-8efd-d24d6bb8b3f2)

The algorithm seems to model reality passably well. It does not account for water heating at the moment. I would like to add a term to account for passive solar gain on those sunny but cold days. The biggest discrepancy appears to be that the lounge cools down much more slowly in the evening than the model predicts, whilst being pretty accurate when it’s unoccupied. (I always thought my wife was hot in a colloquial sense, but maybe it’s not just metaphorical ….. she seems to produce more heat than an Olympic rowing eight at full power. Other explanations may be available, but I’m sticking with this one).

I am currently in the process of discovering that it’s one thing to calculate what you want the heat pump to do, and quite another to get it to actually do it! At the start of each heating period, the algorithm usually wants maximum COP, which is predicted to be at minimum compressor power and lowish flow temperature for our Ecodan. (Our heat pump installation is pretty crappy. The rads are too small, so the model says we can only run steady state with a flow temperature above about 43 degC. We don’t get much heat out of the rads at those ‘low’ temperatures). Left to its own devices, our Ecodan tends to ramp up to high power, overshoot the desired flow temperature by a country mile, and then it takes ages to coax the flow temperature down. If the flow temperature drops too quickly, then the HP shuts down and cycles. If I run in flow temperature mode, and constantly tweak the target flow temperature manually, I can get it to “soft start” at low power, without cycling, and it’s very efficient (relative to the low standards of our crappy installation in room temperature mode). But if nature calls, I return to find that it has cycled in my absence. I am trying to code up something in Home Assistant to automate the soft start, but it’s not reliable yet. The heat pump works really efficiently when it’s heating up the contents of our hot water tank in eco mode. I’m trying to do something similar in central heating mode, but at low compressor power. It feels like I want an extra control mode : a ‘compressor speed mode’ in addition to the normal Ecodan flow temperature mode, weather compensation mode and target room temperature mode. I just want to say, for example, run the compressor at 50% compressor speed (and let the flow temperature do what it wants. I would have thought that if you have small radiators it would eventually stabilise at a high flow temperature, and if you are lucky enough to have large rads it would stabilise at a lower flow temperature. But I don’t know enough about the internals of heat pumps to know whether that’s feasible.
