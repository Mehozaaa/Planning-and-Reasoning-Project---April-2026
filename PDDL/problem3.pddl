(define (problem shems_problem_3)
  (:domain shems_domain)

  (:objects 
    battery - battery
    heater - device  ;hvac
    electric_oven washing_machine - device ;shiftable load
    fridge lights - device       ;critical load
  )

  (:init
    (= (time) 8)  ;initial time
    (sunny)     
    (grid_available)

    ;costs
    (= (total_cost) 0)
    (= (grid_cost) 10)   
    (= (grid_cost_peak) 30)
    (= (grid_cost_offpeak) 10)
    (= (degradation_cost) 2)

    ;battery
    (= (battery_charge battery) 15)
    (= (max_capacity battery) 10)
    (= (charge_rate battery) 4)
    (= (min_soc battery) 2)

    ;oven
    (not (task_completed electric_oven))
    (= (energy_consumption electric_oven) 4)
    (= (power electric_oven) 3)     
    (= (deadline electric_oven) 14)  
    (not (critical electric_oven))
    (not (hvac electric_oven))
    (= (hvac_temp_step electric_oven) 0)

  ;washing machine
    ;(not (task_completed washing_machine));task to complete
    (= (energy_consumption washing_machine) 20) ;energy needed to complete the task
    (= (power washing_machine) 2)    ;power needed for the task
    (= (deadline washing_machine) 12)   ;deadline to complete the task
    ;(not (critical washing_machine))  
    ;(not (hvac washing_machine))
    (= (hvac_temp_step washing_machine) 0)

    ;hvac
    (hvac heater)
    (not (critical heater))
    (= (energy_consumption heater) 2) ;energy needed
    (= (power heater) 2)           ;power used
    (= (hvac_temp_step heater) 3)   ;increased temperature per step
    (= (deadline heater) 24)        


    ;fridge
    (critical fridge)
    (not (on fridge)) 
    (= (power fridge) 1)  ;power used
    (= (energy_consumption fridge) 0) 
    (not (hvac fridge))
    (= (hvac_temp_step fridge) 0)

    ;lights
    (critical lights)
    (not (on lights))
    (= (power lights) 1)
    (= (energy_consumption lights) 0) 
    (not (hvac lights))
    (= (hvac_temp_step lights) 0)

    ;power limits
    (= (current_power_load) 0)
    (= (base_power_load) 0)
    (= (max_power_limit) 5)  

    ;hvac parameters
    (= (indoor_temp) 15) ;starting temperature
    (= (comfort_min) 20)  ;min temp
    (= (comfort_max) 24) ;max tenp
    (= (temp_drift) -1)  ;temp loss from the house 
  )

  (:goal (and
    (task_completed electric_oven)
    (task_completed washing_machine)
    (on lights)
    (on fridge)
    (>= (indoor_temp) (comfort_min))
    (<= (indoor_temp) (comfort_max))
  ))

  (:metric minimize (total_cost))
)