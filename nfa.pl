%%%%	-*- Mode: Prolog -*-
%%%%	re-nfa.pl --

%%% Cristian Ferrari 810932

%% Progetto Prolog "Da Espressioni Regolari a NFA"

%%%% --------------------------------------------- %%%%%%%%

%% 1) is_regexp/1
%Vero quando RE è un'espressione regolare

%Caso base: atomic/1

is_regexp(RE) :-     %%might wanna error handle this one too idk
    nonvar(RE), 
    atomic(RE).

%Caso Base: compound 0 arity

is_regexp(RE) :-
    compound_name_arguments(RE, OP, _),
    not(is_operator(OP)).

%Caso base: compound/1

is_regexp(RE) :-	
    compound(RE),
    RE =.. [OP | _],
    not(is_operator(OP)).

%Caso base: epsilon 

is_regexp(epsilon).

%Caso Unione (OR)

is_regexp(RE) :- 
    RE =.. [or | R1],
    regular_exp(R1).

%Caso STAR (Chiusura di Kleene)

is_regexp(star(RE)) :- 
    is_regexp(RE).

%Caso Plus

is_regexp(plus(RE)) :- 
    is_regexp(RE).

%%is_regexp/1
%gestione lista rimanente dopo =..

is_regexp(RE) :- 
    RE =.. [seq | R1],
    regular_exp(R1).


%regular_exp/1 gestione coda lista dopo seq/or

regular_exp(R1) :- 
    is_regexp(R1).  

regular_exp([R1 | R2]) :- 
    is_regexp(R1), 
    regular_exp(R2).

%%%% --------------------------------------------

%% 2) nfa_regexp_comp

%Vero quando RE è compatibile in un automa che viene 
%inserito nella base di dati

nfa_regexp_comp(FA_Id, RE) :-	
    catch(check_id(FA_Id), Err, nfa_error(Err)),
    catch(check_id_exists(FA_Id), Err, nfa_error(Err)), %add check list
    is_regexp(RE),
    gensym(q, Iniziale),
    assert(nfa_initial(FA_Id, Iniziale)),
    gensym(q, Finale),
    assert(nfa_final(FA_Id, Finale)),
    nfa_regexp_comp(FA_Id, RE, Iniziale, Finale),
    reset_gensym(q), 
    !.

%Caso base, Singolo Simbolo:

nfa_regexp_comp(FA_Id, RE, Iniziale, Finale) :-
    atomic(RE),
    assert(nfa_delta(FA_Id, Iniziale, RE, Finale)).

%Caso compound/1

nfa_regexp_comp(FA_Id, RE, Iniziale, Finale) :-
    not(is_list(RE)),
    compound(RE),
    RE =.. [OP | _],
    not(is_operator(OP)),
    assert(nfa_delta(FA_Id, Iniziale, RE, Finale)).

%%Altri Operatori

%OR  --------------

nfa_regexp_comp(FA_Id, RE, Iniziale, Finale) :-
    RE =.. [or | Rs],
    or_handler(FA_Id, Rs, Iniziale, Finale).

%STAR -------------

nfa_regexp_comp(FA_Id, star(RE), Iniziale, Finale) :-
    assert(nfa_delta(FA_Id, Iniziale, epsilon, Finale)),
    gensym(q, S1),       
    assert(nfa_delta(FA_Id, Iniziale, epsilon, S1)),
    gensym(q, F1),
    assert(nfa_delta(FA_Id, F1, epsilon, S1)),
    assert(nfa_delta(FA_Id, F1, epsilon, Finale)),
    nfa_regexp_comp(FA_Id, RE, S1, F1).

%Plus ------------

nfa_regexp_comp(FA_Id, plus(RE), Iniziale, Finale) :- 
    nfa_regexp_comp(FA_Id, seq(RE, star(RE)), Iniziale, Finale).

%SEQ -------------

%Caso base Seq 1 argomento
nfa_regexp_comp(FA_Id, RE, Iniziale, Finale) :-
    RE =.. [seq, R1],
    nfa_regexp_comp(FA_Id, R1, Iniziale, Finale).

%Seq con 2 argomenti
nfa_regexp_comp(FA_Id, RE, Iniziale, Finale) :- 
    RE =.. [seq, R1, R2],          
    gensym(q, F1),
    nfa_regexp_comp(FA_Id, R1, Iniziale, F1),
    gensym(q, S1),
    assert(nfa_delta(FA_Id, F1, epsilon, S1)),
    nfa_regexp_comp(FA_Id, R2, S1, Finale),
    !.
%Seq 
nfa_regexp_comp(FA_Id, RE, Iniziale, Finale) :-
    RE =.. [seq, R1, R2 | R3],
    gensym(q, F1),
    nfa_regexp_comp(FA_Id, R1, Iniziale, F1),
    gensym(q, S1),
    gensym(q, F2),
    assert(nfa_delta(FA_Id, F1, epsilon, S1)),
    nfa_regexp_comp(FA_Id, R2, S1, F2),
    gensym(q, S2),
    assert(nfa_delta(FA_Id, F2, epsilon, S2)),
    nfa_regexp_comp(FA_Id, R3, S2, Finale),
    !.

%%Gestione caso liste
%List caso base
nfa_regexp_comp(FA_Id, [RE], Iniziale, Finale) :-
    nfa_regexp_comp(FA_Id, RE, Iniziale, Finale).

%List ricorsivo
nfa_regexp_comp(FA_Id, [RE | REs], Iniziale, Finale) :-
    gensym(q, F1),
    nfa_regexp_comp(FA_Id, RE, Iniziale, F1),
    gensym(q, S1),
    assert(nfa_delta(FA_Id, F1, epsilon, S1)),
    nfa_regexp_comp(FA_Id, REs, S1, Finale).

%%or_handler/4
%predicato di supporto per processare OR con 3 o più
%argomenti

or_handler(FA_Id, [RE], Iniziale, Finale) :-
    gensym(q, S1),
    assert(nfa_delta(FA_Id, Iniziale, epsilon, S1)),
    gensym(q, F1),
    assert(nfa_delta(FA_Id, F1, epsilon, Finale)),
    nfa_regexp_comp(FA_Id, RE, S1, F1).

or_handler(FA_Id, [R | Rs], Iniziale, Finale) :- 
    gensym(q, S1),
    assert(nfa_delta(FA_Id, Iniziale, epsilon, S1)),
    gensym(q, F1),
    assert(nfa_delta(FA_Id, F1, epsilon, Finale)),
    nfa_regexp_comp(FA_Id, R, S1, F1),      
    or_handler(FA_Id, Rs, Iniziale, Finale).

%%%% --------------------------------------------------------------

%%3) nfa_test/2
%Vero quando l'input per l'automa "FA_Id" viene
%consumato completamente e l'automa si trova in uno stato Finale

%Caso Base /2:

nfa_test(FA_Id, Input) :-
    catch(check_id(FA_Id), Err, nfa_error(Err)),
    catch(check_list(Input), Err, nfa_error(Err)),
    nfa_test_in(FA_Id, Input).

nfa_test_in(FA_Id, []) :-
    nfa_initial(FA_Id, Q),  %acquisire stato iniziale
    nfa_test_in(FA_Id, [], Q).

nfa_test_in(FA_Id, []) :-      %espilon transition
    nfa_initial(FA_Id, Q),
    nfa_delta(FA_Id, Q, X, Q2),
    X = epsilon, 
    nfa_test_in(FA_Id, [], Q2).

nfa_test_in(FA_Id, [X | Xs]) :-
    nfa_initial(FA_Id, Q),
    nfa_delta(FA_Id, Q, X, Q2),
    nfa_test_in(FA_Id, Xs, Q2).

nfa_test_in(FA_Id, [X | Xs]) :-
    nfa_initial(FA_Id, Q),
    Y = epsilon,          
    nfa_delta(FA_Id, Q, Y, Q2),
    nfa_test_in(FA_Id, [X | Xs], Q2).

%nfa_test/3 caso base
nfa_test_in(FA_Id, [], Stato) :-
    nfa_final(FA_Id, Stato),
    !.

nfa_test_in(FA_Id, [], Stato) :-      %epsilon transition input vuoto
    nfa_delta(FA_Id, Stato, X, Q2),
    X = epsilon, 
    nfa_test_in(FA_Id, [], Q2).

nfa_test_in(FA_Id, [X | Xs], Stato) :-  %epsilon transition
    nfa_delta(FA_Id, Stato, Y, Q2),
    Y = epsilon,
    nfa_test_in(FA_Id, [X | Xs], Q2).

nfa_test_in(FA_Id, [X | Xs], Stato) :-
    nfa_delta(FA_Id, Stato, X, Q2),
    nfa_test_in(FA_Id, Xs, Q2).
%%%% -------------------------------------------------

%%4) nfa_clear, nfa_clear(FA_Id)
%% nfa_clear/0 rimuove tutti gli automi salvati
%% nfa_clear/1 rimuove l'automa FA_Id

nfa_clear :-
    retractall(nfa_initial(_, _)),
    retractall(nfa_final(_, _)),
    retractall(nfa_delta(_, _, _, _)).

nfa_clear(FA_Id) :-   
    retractall(nfa_delta(FA_Id, _, _, _)),
    retractall(nfa_initial(FA_Id, _)),
    retractall(nfa_final(FA_Id, _)).

%% Utility: funzione per stampare gli nfa salvati
%%nfa_list/0 stampa tutti gli automi, nfa_list/1 stampa automa FA_Id

nfa_list :-
    listing(nfa_initial(_, _)),
    listing(nfa_final(_, _)),
    listing(nfa_delta(_, _, _, _)).

nfa_list(FA_Id) :-
    listing(nfa_initial(FA_Id, _)),
    listing(nfa_final(FA_Id, _)),
    listing(nfa_delta(FA_Id, _, _, _)).

%%gestione degli errori per input non validi

%%check_id/1
%verifica che FA_Id non sia una variabile

check_id(FA_Id) :-
    not(atomic(FA_Id)),
    throw('ID dell\'automa non valido'),
    fail.

check_id(FA_Id) :-
    atomic(FA_Id).

%%check_id_exists/1
%verifica che non esista gia un automa con lo stesso
%FA_Id controllando gli stati inziali esistenti

check_id_exists(FA_Id) :-
    nfa_initial(FA_Id, _),
    throw('ID automa gia esistente, usare ID diverso'),
    fail.

check_id_exists(FA_Id) :-
    not(nfa_initial(FA_Id, _)).

%%check_input/1
%Verifica che l'input di nfa_test sia una lista
check_list(Input) :-
    is_list(Input).

check_list(Input) :-
    not(is_list(Input)),
    throw('L\'Input deve essere una lista.'),
    fail.

%% nfa_error(nfa)
nfa_error(Err) :-
    print_message_lines(current_output, ' ',
			[begin(error, _), prefix('~NERROR: '), '~w' - [Err]]
		       ),
    fail.

% is_operator facts, usati per caso compound/1

is_operator(star).
is_operator(seq).
is_operator(or).
is_operator(plus).


:- dynamic nfa_initial/2.
:- dynamic nfa_final/2.
:- dynamic nfa_delta/4.


%%%%    End of file -- ER_NFA.pl --












