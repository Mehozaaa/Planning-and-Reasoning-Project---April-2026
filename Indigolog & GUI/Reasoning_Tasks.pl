%setup files
user:file_search_path(indigolog, './indigolog-main/indigolog-main').
:- [indigolog('config')].
:- [indigolog('eval/eval_bat')].
:- [indigolog('interpreters/indigolog')].
:- style_check(-discontiguous).
:- style_check(-singleton).

:- ensure_loaded('shems_bat.pl').
:- ensure_loaded('shems_controller.pl').

%utilities
%check if an action is legal
legal_history([]).
legal_history([Act | Rest]) :-
    legal_history(Rest),
    poss(Act, Cond),         
    eval(Cond, Rest, true).   

%generate a plan of fixed lenght
generate_plan(0, []).
generate_plan(Len, [Act|Rest]) :-
    Len > 0,
    Len1 is Len - 1,
    generate_plan(Len1, Rest),
    prim_action(Act).

%legality check
%charge solar after cloud cover, result false
test_legality :-
    writeln('task 1: legality'),
    History1a = [cloud_cover_start],
    write('query: poss(charge_solar, '), write(History1a), writeln(')'),
    poss(charge_solar, Cond1a),
    ( eval(Cond1a, History1a, true) -> 
        writeln('result: true') 
    ; 
        writeln('result: false') 
    ),
    nl,

    %run washer after charge grid and turn on fridge, the result is false
    History1b = [turn_on_fridge, charge_grid],
    write('query: poss(run_washer, '), write(History1b), writeln(')'),
    poss(run_washer, Cond1b),
    ( eval(Cond1b, History1b, true) -> 
        writeln('result: true') 
    ; 
        writeln('result: false')
    ),
    nl.

%projection check
%given the action list check the states
test_projection :-
    writeln('task 2: projection'),
    ActionList = [advance_time, run_hvac, charge_solar, charge_grid],
    write('history: '), writeln(ActionList),
    nl,

    % check if the battery level is 10
    Eval2a = (battery_level = 10),
    write('query: eval('), write(Eval2a), writeln(')'),
    ( eval(Eval2a, ActionList, true) -> 
        writeln('result: true') 
    ; 
        writeln('result: false') 
    ),
    nl,

    %check if the time is 9
    Eval2b = (time_of_day = 9),
    write('query: eval('), write(Eval2b), writeln(')'),
    ( eval(Eval2b, ActionList, true) -> 
        writeln('result: true') 
    ; 
        writeln('result: false') 
    ),
    nl.

%task 3 planning
%search a path that  bring to the goal state
test_planning :-
    writeln('task 3: planning'),
    Goal = and(washer_done, fridge_on),
    MaxDepth = 5,
    write('query: plan_search(goal: '), write(Goal), writeln(')'),
    
    (   between(1, MaxDepth, PlanLength),
        generate_plan(PlanLength, Plan),
        legal_history(Plan),
        eval(Goal, Plan, true)
    ->  
        writeln('result: true'),
        reverse(Plan, ExecPlan),
        write('plan_found: '), writeln(ExecPlan)
    ;   
        writeln('result: false')
    ),
    nl.

%execution
run_tests :-
    initialize(evaluator),
    nl,
    test_legality,
    test_projection,
    test_planning.