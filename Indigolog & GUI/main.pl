% --- main.pl ---

user:file_search_path(indigolog, './indigolog-main/indigolog-main'). %config the path for indigolog
:- [indigolog('config')].
:- [indigolog('eval/eval_bat')].
:- [indigolog('interpreters/indigolog')].
:- style_check(-discontiguous).
:- style_check(-singleton).
%load other files
:- [SHEMS_BAT].
:- [SHEMS_Controller].

start :-
    writeln('Load completed'),
    writeln('Run controller SHEMS'),
    indigolog(control_home). %launch the interpreter defined in shems_controller
