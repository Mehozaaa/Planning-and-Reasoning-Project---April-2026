(define (domain shems_domain)
  (:requirements 
      :strips :typing :fluents :equality 
      :disjunctive-preconditions :negative-preconditions 
      :conditional-effects
  )

  (:types 
      device battery - object
  )

  (:predicates 
      (on ?d - device)             ; device is active/consuming
      (task_completed ?d - device) ; goal state for tasks
      (sunny)                      ; allows solar charging
      (grid_available)             ; allows grid usage
      (critical ?d - device)       ; critical load flag
      (hvac ?d - device)           ; flag for HVAC devices
      (battery_charged_this_step)  ;predicates to no execute multiple actions in the same step
      (hvac_used_this_step)
  )

  (:functions
      (battery_charge ?b - battery)    ; current charge level
      (max_capacity ?b - battery)      ; max battery capacity
      (charge_rate ?b - battery)       ; charge gained per step
      (min_soc ?b - battery)    ; minimum state of charge (safety)
      (degradation_cost)               ; cost per battery use cycle

      (energy_consumption ?d - device) ; energy needed for task
      (power ?d - device)              ; power rating (kW) for load limit

      (total_cost)                     ; main metric to minimize
      (grid_cost)                      ; dynamic current grid cost
      (grid_cost_peak)                 ; constant: high price
      (grid_cost_offpeak)              ; constant: low price

      (current_power_load)             ; sum of active devices power
      (base_power_load)                 ;to track power load of critical loads
      (max_power_limit)                ; max grid power (blackout limit)

      (time)                           ; logical time step 
      (deadline ?d - device)           ; max time step to complete task

      (indoor_temp)                    ; current room temp
      (comfort_min)                    ; target min temp
      (comfort_max)                    ; target max temp
      (temp_drift)                     ; passive temp change per step
      (hvac_temp_step ?d - device)     ; active temp change per step
  )

  ;to advance the time
  (:action advance_time
      :parameters ()
      :precondition (and 
          (< (time) 24) ;to avoid infinite loops 
      )
      :effect (and
          (increase (time) 1)
          (assign (current_power_load) (base_power_load)) ;reset power load of shiftable devices
            ;reset this variables each time step
          (not (battery_charged_this_step))
          (not (hvac_used_this_step))
          ;update cost based on hour
          (when (and (>= (time) 9) (< (time) 20))
                (assign (grid_cost) (grid_cost_peak)))
          (when (or (< (time) 9) (>= (time) 20))
                (assign (grid_cost) (grid_cost_offpeak)))
            ;assume that the house doestn't maintain the same temperature during time
          (increase (indoor_temp) (temp_drift))
      )
  )

  (:action charge_battery_solar ;action to charge the battery using the sun
      :parameters (?b - battery)
      :precondition (and 
          (sunny) 
          (< (battery_charge ?b) (max_capacity ?b))
          (not (battery_charged_this_step))
      )
      :effect (and
            (battery_charged_this_step) ;activate the flag
            ;check for overcharging
          (when (<= (+ (battery_charge ?b) (charge_rate ?b)) (max_capacity ?b))
              (increase (battery_charge ?b) (charge_rate ?b)))
          (when (> (+ (battery_charge ?b) (charge_rate ?b)) (max_capacity ?b))
              (assign (battery_charge ?b) (max_capacity ?b)))
      )
  )

  (:action charge_battery_grid 
      :parameters (?b - battery)
      :precondition (and
          (grid_available)
          (< (battery_charge ?b) (max_capacity ?b))
          (<= (+ (current_power_load) 1) (max_power_limit)) ;assuming 1Kw of load for charging the battery
          (not (battery_charged_this_step))
      )
      :effect (and
            (increase (current_power_load) 1)
            (battery_charged_this_step)
        ;check overcharging
          (when (<= (+ (battery_charge ?b) (charge_rate ?b)) (max_capacity ?b))
              (increase (battery_charge ?b) (charge_rate ?b)))
          (when (> (+ (battery_charge ?b) (charge_rate ?b)) (max_capacity ?b))
              (assign (battery_charge ?b) (max_capacity ?b)))

          (when (and (>= (time) 9) (< (time) 20))
              (increase (total_cost) (* (charge_rate ?b) (grid_cost_peak))))
            (when (or (< (time) 9) (>= (time) 20))
              (increase (total_cost) (* (charge_rate ?b) (grid_cost_offpeak))))
      )
  )



  ;action to use the batery only if it's sufficient to complete the task
  (:action run_device_battery 
      :parameters (?d - device ?b - battery)
      :precondition (and
          (not (task_completed ?d))
          (<= (time) (deadline ?d)) ;in time
          (>= (battery_charge ?b) (energy_consumption ?d)) ;the charge of the battery is sufficient
          (>= (- (battery_charge ?b) (energy_consumption ?d)) (min_soc ?b));and should be higher than soc
          (<= (+ (current_power_load) (power ?d)) (max_power_limit))
      )
      :effect (and
          (task_completed ?d)
          (increase (current_power_load) (power ?d))
          (decrease (battery_charge ?b) (energy_consumption ?d))
          (increase (total_cost) (degradation_cost)) 
      )
  )

  ;action to use the grid if the battery is not sufficient
  (:action run_device_grid 
      :parameters (?d - device ?b - battery) 
      :precondition (and
          (not (task_completed ?d))
          (grid_available)
          (<= (time) (deadline ?d))
          (<= (+ (current_power_load) (power ?d)) (max_power_limit))
          (or ;
              (< (battery_charge ?b) (energy_consumption ?d))
              (< (- (battery_charge ?b) (energy_consumption ?d)) (min_soc ?b))
          )
      )
      :effect (and
          (task_completed ?d)
          (increase (current_power_load) (power ?d))
          (when (and (>= (time) 9) (< (time) 20))
              (increase (total_cost) (* (energy_consumption ?d) (grid_cost_peak))))
        (when (or (< (time) 9) (>= (time) 20))
              (increase (total_cost) (* (energy_consumption ?d) (grid_cost_offpeak))))
      )
  )

  ;use at first battery and then grud
  (:action run_device_mixed 
      :parameters (?d - device ?b - battery)
      :precondition (and
          (not (task_completed ?d))
          (<= (time) (deadline ?d))
          (< (battery_charge ?b) (energy_consumption ?d)) 
          (> (battery_charge ?b) 0)                       ;it's not empty
          (<= (+ (current_power_load) (power ?d)) (max_power_limit))
          (grid_available)
      )
      :effect (and
      (task_completed ?d)
      ;pay only the difference plus degradation
      (increase (current_power_load) (power ?d))
      (when (and (>= (time) 9) (< (time) 20))
            (increase (total_cost) (+ (* (- (energy_consumption ?d) (battery_charge ?b)) (grid_cost_peak)) (degradation_cost))))
        (when (or (< (time) 9) (>= (time) 20))
            (increase (total_cost) (+ (* (- (energy_consumption ?d) (battery_charge ?b)) (grid_cost_offpeak)) (degradation_cost))))
      (assign (battery_charge ?b) (min_soc ?b))
    )
  )

;actions to switch on and off critical loads
  (:action switch_on_critical
      :parameters (?d - device)
      :precondition (and
          (critical ?d)
          (not (on ?d))
          (<= (+ (current_power_load) (power ?d)) (max_power_limit))
      )
      :effect (and
          (on ?d)
          (increase (current_power_load) (power ?d))
          (increase (base_power_load) (power ?d))
      )
  )

  (:action switch_off_critical
      :parameters (?d - device)
      :precondition (and (on ?d) (critical ?d))
      :effect (and 
          (not (on ?d))
          (decrease (current_power_load) (power ?d))
          (decrease (base_power_load) (power ?d))
      )
  )

  
  ;action to run hvac using grid
  (:action run_hvac_grid 
      :parameters (?d - device ?b - battery) 
      :precondition (and
          (hvac ?d)
          (grid_available)
          (not (hvac_used_this_step)) 
          (<= (+ (current_power_load) (power ?d)) (max_power_limit));legality check
          (<= (+ (indoor_temp) (hvac_temp_step ?d)) (comfort_max))
          ;battery check
          (or
              (< (battery_charge ?b) (energy_consumption ?d))
              (< (- (battery_charge ?b) (energy_consumption ?d)) (min_soc ?b))
          )
      )
      :effect (and
        (hvac_used_this_step)
        (increase (current_power_load) (power ?d))    
          (increase (indoor_temp) (hvac_temp_step ?d))
          (when (and (>= (time) 9) (< (time) 20))
              (increase (total_cost) (* (energy_consumption ?d) (grid_cost_peak))))
        (when (or (< (time) 9) (>= (time) 20))
              (increase (total_cost) (* (energy_consumption ?d) (grid_cost_offpeak))))
      )
  )

  (:action run_hvac_battery ;action to run hvac using grid
      :parameters (?d - device ?b - battery)
      :precondition (and
          (hvac ?d)
          (not (hvac_used_this_step))
          (>= (battery_charge ?b) (energy_consumption ?d))
          (>= (- (battery_charge ?b) (energy_consumption ?d)) (min_soc ?b))
          (<= (+ (current_power_load) (power ?d)) (max_power_limit))
          (<= (+ (indoor_temp) (hvac_temp_step ?d)) (comfort_max))
      )
      :effect (and
      (hvac_used_this_step)
        (increase (current_power_load) (power ?d))
          (increase (indoor_temp) (hvac_temp_step ?d))
          (decrease (battery_charge ?b) (energy_consumption ?d))
          (increase (total_cost) (degradation_cost))
      )
  )

  (:action run_hvac_mixed; to run hvac with both battery and grid
    :parameters (?d - device ?b - battery)
    :precondition (and
      (hvac ?d)
      (not (hvac_used_this_step))
      (< (battery_charge ?b) (energy_consumption ?d));battery not empty but not sufficient
      (> (battery_charge ?b) 0)
      (grid_available)
      (<= (+ (current_power_load) (power ?d)) (max_power_limit))
      
      (<= (+ (indoor_temp) (hvac_temp_step ?d)) (comfort_max))
    )
    :effect (and
    (hvac_used_this_step)
    (increase (indoor_temp) (hvac_temp_step ?d))
    (increase (current_power_load) (power ?d))
    ;pay only the difference plus degradation
    (when (and (>= (time) 9) (< (time) 20))
      (increase (total_cost) (+ (* (- (energy_consumption ?d) (battery_charge ?b)) (grid_cost_peak)) (degradation_cost))))  
        (when (or (< (time) 9) (>= (time) 20))
      (increase (total_cost) (+ (* (- (energy_consumption ?d) (battery_charge ?b)) (grid_cost_offpeak)) (degradation_cost))))
    (assign (battery_charge ?b) (min_soc ?b))
    )
  )
)