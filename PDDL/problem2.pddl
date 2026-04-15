(define (problem shems_problem_2)
  (:domain shems_domain)

  (:objects 
    battery - battery
    dishwasher ev_car lights - device
  )

  (:init
    (= (time) 8)            ;starting time
    (sunny)
    (grid_available)

    (= (total_cost) 0)
    (= (grid_cost) 10)       ;initial grid cost
    (= (grid_cost_peak) 30)  ; Peak grid cost
    (= (grid_cost_offpeak) 10);lowest grid cost
    (= (degradation_cost) 2)

    ;battery
    (= (battery_charge battery) 10)
    (= (max_capacity battery) 13)
    (= (charge_rate battery) 3)
    (= (min_soc battery) 3)

    ;dishwasher
    ;(not (task_completed dishwasher))
    (= (energy_consumption dishwasher) 4)
    (= (power dishwasher) 2)
    (= (deadline dishwasher) 20)
    ;(not (hvac dishwasher))
    ;(not (critical dishwasher))
    (= (hvac_temp_step dishwasher) 0)

    ;ev car
    ;(not (task_completed ev_car))
    (= (energy_consumption ev_car) 15)
    (= (power ev_car) 4)
    (= (deadline ev_car) 24) 
    ;(not (hvac ev_car))
    ;(not (critical ev_car))
    (= (hvac_temp_step ev_car) 0)
    ;lights
    (critical lights)
    (not (on lights))
    (= (power lights) 1)
    (= (energy_consumption lights) 0)
    (not (hvac lights))
    (= (hvac_temp_step lights) 0)

    ;constraints
    (= (current_power_load) 0)
    (= (base_power_load) 0)
    (= (max_power_limit) 6)

;variables npt needed for this instance
    (= (indoor_temp) 20)
    (= (comfort_min) 18)
    (= (comfort_max) 22)
    (= (temp_drift) 0)
  )

  (:goal (and
    (task_completed dishwasher)
    (task_completed ev_car)
    (on lights)
  ))

  (:metric minimize (total_cost))
)
