% --- shems_controller.pl ---

proc(control_home,
    if(hours_passed = 24,
        ?(true), % STOP: If 24 hours have passed, exit the loop
        [
            % 1. Critical Loads (Now they check if battery > 4)
            if(and(neg(fridge_on), battery_level > 4), turn_on_fridge, ?(true)),
            if(and(neg(lights_on), battery_level > 4), turn_on_lights, ?(true)),

            % 2. Heating
            if(and(indoor_temp < 21, battery_level > 4), run_hvac, ?(true)),

            % 3. Shiftable Loads
            if(and(neg(washer_done), battery_level > 9), run_washer, ?(true)),
            if(and(neg(oven_done), battery_level > 9), run_oven, ?(true)),
            
            % 4. Charging
            if(and(sunny, battery_level < 21), charge_solar, ?(true)),
            if(and(neg(sunny), and(battery_level < 16, grid_price < 30)), charge_grid, ?(true)),
            
            % 5. Advance time and run the loop again!
            advance_time,
            control_home
        ]
    )
).