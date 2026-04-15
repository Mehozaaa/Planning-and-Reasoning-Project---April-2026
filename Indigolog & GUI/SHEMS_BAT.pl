% --- shems_bat.pl ---

load_devices([gui]).
load_device(gui, _, []).

how_to_execute(run_washer,      gui, run_washer).
how_to_execute(run_oven,        gui, run_oven).
how_to_execute(turn_on_fridge,  gui, turn_on_fridge).
how_to_execute(turn_on_lights,  gui, turn_on_lights).
how_to_execute(run_hvac,        gui, run_hvac).
how_to_execute(charge_solar,    gui, charge_solar).
how_to_execute(charge_grid,     gui, charge_grid).
how_to_execute(advance_time,    gui, advance_time).

translate_exog(cloud_cover_start, cloud_cover_start).
translate_exog(cloud_cover_end,   cloud_cover_end).
translate_exog(price_spike_start, price_spike_start).
translate_exog(price_spike_end,   price_spike_end).

em_address(localhost, 5004).
controller_address(localhost, 5005).

exog_events([]).

:- dynamic(fluent/2).
:- dynamic(proc/2).
:- dynamic(cache/1).

:- discontiguous causes_true/3.
:- discontiguous causes_false/3.
:- discontiguous causes_val/4.

cache(battery_level).
cache(grid_price).
cache(indoor_temp).
cache(time_of_day).
cache(hours_passed).
cache(washer_done).
cache(oven_done).
cache(sunny).
cache(fridge_on).
cache(lights_on).
cache(price_spike_active).

prim_action(charge_solar). 
prim_action(charge_grid).
prim_action(run_washer).
prim_action(run_oven).   
prim_action(turn_on_fridge). 
prim_action(turn_on_lights).
prim_action(run_hvac).
prim_action(advance_time).

exog_action(price_spike_start). 
exog_action(price_spike_end).
exog_action(cloud_cover_start). 
exog_action(cloud_cover_end).

fun_fluent(battery_level).
fun_fluent(grid_price).
fun_fluent(indoor_temp).
fun_fluent(time_of_day).
fun_fluent(hours_passed).

rel_fluent(washer_done).
rel_fluent(oven_done).
rel_fluent(sunny).
rel_fluent(fridge_on).
rel_fluent(lights_on).
rel_fluent(price_spike_active). 

% PRECONDITIONS (Added battery constraint for Fridge and Lights)
poss(turn_on_fridge,  and(neg(fridge_on), battery_level > 4)).
poss(turn_on_lights,  and(neg(lights_on), battery_level > 4)).
poss(run_washer, and(neg(washer_done), battery_level > 9)).
poss(run_oven,   and(neg(oven_done), battery_level > 9)).
poss(run_hvac,   battery_level > 4).
poss(charge_solar, and(sunny, battery_level < 21)).
poss(charge_grid,  battery_level < 16).
poss(advance_time, neg(hours_passed = 24)).
poss(A, true) :- exog_action(A). 

% BOOLEAN EFFECTS
causes_true(turn_on_fridge,  fridge_on, true).
causes_true(turn_on_lights,  lights_on, true).
causes_true(run_washer, washer_done, true).
causes_true(run_oven, oven_done, true).

causes_true(cloud_cover_end,    sunny, true).
causes_false(cloud_cover_start, sunny, true).
causes_true(price_spike_start, price_spike_active, true).
causes_false(price_spike_end,  price_spike_active, true).

% --- SUN CYCLE LOGIC ---
causes_false(advance_time, sunny, time_of_day = 18). % Sun sets at 6 PM 
causes_true(advance_time, sunny, time_of_day = 7).   % Sun rises at 7 AM

% GRID PRICE EFFECTS
causes_val(price_spike_start, grid_price, 30, true).
causes_val(price_spike_end, grid_price, 20, and(time_of_day > 7, time_of_day < 20)).
causes_val(price_spike_end, grid_price, 10, or(time_of_day < 8, time_of_day > 19)).

% TABLE TRANSITIONS (To avoid math crashes)
next_time(0,1). next_time(1,2). next_time(2,3). next_time(3,4). next_time(4,5). next_time(5,6).
next_time(6,7). next_time(7,8). next_time(8,9). next_time(9,10). next_time(10,11). next_time(11,12).
next_time(12,13). next_time(13,14). next_time(14,15). next_time(15,16). next_time(16,17). next_time(17,18).
next_time(18,19). next_time(19,20). next_time(20,21). next_time(21,22). next_time(22,23). next_time(23,0).

next_hour(0,1). next_hour(1,2). next_hour(2,3). next_hour(3,4). next_hour(4,5). next_hour(5,6).
next_hour(6,7). next_hour(7,8). next_hour(8,9). next_hour(9,10). next_hour(10,11). next_hour(11,12).
next_hour(12,13). next_hour(13,14). next_hour(14,15). next_hour(15,16). next_hour(16,17). next_hour(17,18).
next_hour(18,19). next_hour(19,20). next_hour(20,21). next_hour(21,22). next_hour(22,23). next_hour(23,24).
next_hour(24,25).

causes_val(advance_time, time_of_day, NewTime, time_of_day = OldTime) :- next_time(OldTime, NewTime).
causes_val(advance_time, hours_passed, NewH, hours_passed = OldH) :- next_hour(OldH, NewH).

hvac_heat(15,18). hvac_heat(16,19). hvac_heat(17,20). hvac_heat(18,21). hvac_heat(19,22).
hvac_heat(20,23). hvac_heat(21,24). hvac_heat(22,25). hvac_heat(23,25). hvac_heat(24,25). hvac_heat(25,25).
causes_val(run_hvac, indoor_temp, NewTemp, indoor_temp = OldTemp) :- hvac_heat(OldTemp, NewTemp).

bat_sub5(25,20). bat_sub5(20,15). bat_sub5(15,10). bat_sub5(10,5). bat_sub5(5,0). bat_sub5(0,0).
bat_sub10(25,15). bat_sub10(20,10). bat_sub10(15,5). bat_sub10(10,0). bat_sub10(5,0). bat_sub10(0,0).
bat_add5(0,5). bat_add5(5,10). bat_add5(10,15). bat_add5(15,20). bat_add5(20,25). bat_add5(25,25).
bat_add10(0,10). bat_add10(5,15). bat_add10(10,20). bat_add10(15,25). bat_add10(20,25). bat_add10(25,25).

% BATTERY EFFECTS (Added cost of 5 for Fridge and Lights)
causes_val(turn_on_fridge, battery_level, NewBat, battery_level = OldBat) :- bat_sub5(OldBat, NewBat).
causes_val(turn_on_lights, battery_level, NewBat, battery_level = OldBat) :- bat_sub5(OldBat, NewBat).
causes_val(run_hvac, battery_level, NewBat, battery_level = OldBat) :- bat_sub5(OldBat, NewBat).
causes_val(run_washer, battery_level, NewBat, battery_level = OldBat) :- bat_sub10(OldBat, NewBat).
causes_val(run_oven, battery_level, NewBat, battery_level = OldBat) :- bat_sub10(OldBat, NewBat).
causes_val(charge_solar, battery_level, NewBat, battery_level = OldBat) :- bat_add5(OldBat, NewBat).
causes_val(charge_grid, battery_level, NewBat, battery_level = OldBat) :- bat_add10(OldBat, NewBat).

% INITIAL STATE
initially(battery_level, 0).
initially(grid_price, 20).
initially(indoor_temp, 18).
initially(time_of_day, 8).
initially(hours_passed, 0).
initially(sunny, true).
initially(fridge_on, false).
initially(lights_on, false).
initially(washer_done, false).
initially(oven_done, false).
initially(price_spike_active, false).