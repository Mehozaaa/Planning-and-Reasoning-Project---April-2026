(define (problem shems_problem_1)
  (:domain shems_domain)
    ;define objects needed
  (:objects 
    battery - battery
    washing_machine lights - device
  )
;define initial state
  (:init
    (= (time) 8)  ;starting time
    (sunny)      
    (grid_available)  
    
    (= (total_cost) 0) ;cost to minimize
    (= (grid_cost) 15)    ;basic cost
    (= (grid_cost_peak) 15) 
    (= (grid_cost_offpeak) 15)
    (= (degradation_cost) 2)

    (= (battery_charge battery) 1) ;starting charge of the battery
    (= (max_capacity battery) 5) ;max capacity
    (= (charge_rate battery) 2)    ; rate per step
    (= (min_soc battery) 1)   ;min soc
    (= (base_power_load) 0)

    ;(not (task_completed washing_machine));task to complete
    (= (energy_consumption washing_machine) 3) ;energy needed to complete the task
    (= (power washing_machine) 2)    ;power needed for the task
    (= (deadline washing_machine) 18)   ;deadline to complete the task
    ;(not (critical washing_machine))  
    ;(not (hvac washing_machine))
    ;lights
    (critical lights)
    (not (on lights))
    (= (power lights) 1)
    (= (energy_consumption lights) 0)
    (not (hvac lights))
    (= (hvac_temp_step lights) 0)

    (= (current_power_load) 0);starting power load
    (= (max_power_limit) 6) 
;variables not needed fot this instance
    (= (indoor_temp) 20)
    (= (comfort_min) 18)
    (= (comfort_max) 22)
    (= (temp_drift) 0)
    (= (hvac_temp_step washing_machine) 0)
  )

  ;goal
  (:goal (and
    (task_completed washing_machine)
    (on lights)
  ))

  (:metric minimize (total_cost))
)
