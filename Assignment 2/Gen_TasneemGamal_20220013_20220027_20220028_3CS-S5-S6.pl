%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Task 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
explore_path(Current, Grid, Visited, Result, Path, R, C) :-
    valid_moves(Current, R, C, Grid, Visited, Moves),
    Moves = [], !,
    (nth0(Current, Grid, 'P') -> Result = 1, Path = [Current]; Result = 0, Path = []).

explore_path(Current, Grid, Visited, Result, Path, R, C) :-
    valid_moves(Current, R, C, Grid, Visited, Moves),
    collect_results(Moves, Grid, [Current | Visited], R, C, Results),
    select_best_path(Results, MaxResult, BestPath),
    (
        MaxResult \= 0 ->
            (nth0(Current, Grid, 'P') ->
                Result is MaxResult + 1,
                Path = [Current | BestPath]
            ;
                Result = MaxResult,
                Path = [Current | BestPath]
            )
        ;
            (nth0(Current, Grid, 'P') ->
                Result is MaxResult + 1,
                Path = [Current]
            ;
                Result = MaxResult,
                Path = []
            )
    ).

valid_moves(Current, R, C, Grid, Visited, Moves):-
    findall(Next, (
        move(Current, Next, R, C),
        nth0(Next, Grid, Cell),
        Cell \= 'O',
        \+ member(Next, Visited)
    ), Moves).

collect_results([], _, _, _, _, []).
collect_results([Move | Rest], Grid, Visited, R, C, [[Result, Path] | Results]):-
    explore_path(Move, Grid, Visited, Result, Path, R, C),
    collect_results(Rest, Grid, Visited, R, C, Results).

select_best_path([[Result, Path]], Result, Path).
select_best_path([[Result1, Path1] | Rest], BestResult, BestPath):-
    select_best_path(Rest, CurrentResult, CurrentPath),
    ( Result1 > CurrentResult ->
        BestResult = Result1,
        BestPath = Path1
    ;
        BestResult = CurrentResult,
        BestPath = CurrentPath
    ).

move(Current, Next, R, C):-
    move_left(Current, Next, C);
    move_right(Current, Next, C);
    move_up(Current, Next, C);
    move_down(Current, Next, R, C).

move_up(Current, Next, C):-
    Next is Current - C,
    Next >= 0.

move_down(Current, Next, R, C):-
    Next is Current + C,
    Max is R * C,
    Next < Max.

move_left(Current, Next, C):-
    Col is Current mod C,
    Col > 0,
    Next is Current - 1.

move_right(Current, Next, C):-
    Col is Current mod C,
    Col < C - 1,
    Next is Current + 1.

list_length([], 0).
list_length([_ | T], Length):-
    list_length(T, L1),
    Length is L1 + 1.

convert_to_grid(Grid, R, C):-
    display_rows(Grid, R, C, 0).

display_rows(_, R, _, R):- nl.
display_rows(Grid, R, C, Row):-
    display_row(Grid, C, Row, 0),
    nl,
    NextRow is Row + 1,
    display_rows(Grid, R, C, NextRow).

display_row(_, C, _, C).
display_row(Grid, C, Row, Col):-
    Index is Row * C + Col,
    nth0(Index, Grid, Element),
    write(Element), write(' '),
    NextCol is Col + 1,
    display_row(Grid, C, Row, NextCol).

print_steps(Grid, [Last], R, C):-
    update_grid(Last, Grid, 'D', NewGrid),
    write("Final:"), nl, nl,
    convert_to_grid(NewGrid, R, C).

print_steps(Grid, [Step, Next | Rest], R, C):-
    update_grid(Step, Grid, '*', TempGrid),
    update_grid(Next, TempGrid, 'D', NewGrid),
    (
        Rest \= [] ->
            convert_to_grid(NewGrid, R, C),
            nl
        ; true
    ),
    print_steps(NewGrid, [Next | Rest], R, C).

update_grid(0, [_ | T], Value, [Value | T]).
update_grid(Index, [H | T], Value, [H | R]):-
    Index > 0,
    I1 is Index - 1,
    update_grid(I1, T, Value, R).

find_drone_path(Grid, R, C):-
    list_length(Grid, Length),
    Length =:= R * C,
    explore_path(0, Grid, [], _, Path, R, C),
    write("Drone Route:"), nl, nl,
    convert_to_grid(Grid, R, C),
    (
        Path \= [] ->
            write("Steps:"), nl, nl,
            print_steps(Grid, Path, R, C)
        ;
            write("Final: "), nl, nl,
            convert_to_grid(Grid, R, C)
    ),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Task 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
is_member(X, [X|_]).
is_member(X, [_|Xs]) :-
    is_member(X, Xs).

find_min([X], X).
find_min([X|Xs], Min) :-
    find_min(Xs, M),
    ( X =< M -> Min = X ; Min = M ).

extract_element(X, [X|Xs], Xs).
extract_element(X, [Y|Ys], [Y|Zs]) :-
    extract_element(X, Ys, Zs).

append_list([], L, L).
append_list([X|Xs], Ys, [X|Zs]) :-
    append_list(Xs, Ys, Zs).

delete_element([X|Xs], X, Xs).
delete_element([Y|Ys], X, [Y|Zs]) :-
    X \= Y,
    delete_element(Ys, X, Zs).

a_star_search([], _, _, _, _, _, _) :-
    write("No path found."), nl, !.

a_star_search(Open, Closed, InitialGrid, Rows, Cols, N, MaxEnergy) :-
    get_best_state(Open, [State, Parent, PathCost, Heuristic, TotalCost, Energy], RemainingOpen),
    (   \+ is_member('P', State)
    ->  write("Cost (Number of moves): "), write(PathCost), nl,
        write("Final grid:"), nl,
        print_grid(State, Cols),
        reconstruct_path(State, Parent, Closed, Cols, Path),
        nl,nl,
        twoD_to_oneD(Path, LinearPath, Rows, Cols),
        write("Steps: "),nl,nl,
        print_steps(InitialGrid, LinearPath, Rows, Cols)
    ;   findall(
            [ChildState, State, NewPathCost, ChildHeuristic, NewTotalCost, NewEnergy],
            (
                generate_move(State, ChildState, Collected, Cols, N, Energy, NewEnergy, MaxEnergy),
                \+ state_in_closed(ChildState, NewEnergy, Closed),
                NewPathCost is PathCost + 1,
                calculate_heuristic(ChildState, Cols, ChildHeuristic),
                NewTotalCost is NewPathCost + ChildHeuristic
            ),
            Children
        ),
        integrate_children(Children, RemainingOpen, NewOpen),
        append_list(Closed, [[State, Parent, PathCost, Heuristic, TotalCost, Energy]], NewClosed),
        a_star_search(NewOpen, NewClosed, InitialGrid, Rows, Cols, N, MaxEnergy)
    ).

get_best_state(Open, Best, Remaining) :-
    find_min_state(Open, Best),
    delete_element(Open, Best, Remaining).

find_min_state([X], X) :- !.
find_min_state([X, Y | T], Min) :-
    X = [_, _, _, _, FX, _],
    Y = [_, _, _, _, FY, _],
    ( FX =< FY -> find_min_state([X|T], Min) ; find_min_state([Y|T], Min) ).

integrate_children([], Open, Open).
integrate_children([[S,P,PC,H,TC,E]|T], Open, Out) :-
    (   extract_element([S,_,_,_,OldTC,E], Open, OpenRest), OldTC > TC
    ->  integrate_children(T, [[S,P,PC,H,TC,E]|OpenRest], Out)
    ;   is_member([S,_,_,_,ExistingTC,E], Open), ExistingTC =< TC
    ->  integrate_children(T, Open, Out)
    ;   integrate_children(T, [[S,P,PC,H,TC,E]|Open], Out)
    ).

state_in_closed(S, E, Closed) :-
    is_member([S,_,_,_,_,E], Closed).

generate_move(State, NewState, Collected, Cols, N, Energy, NewEnergy, MaxEnergy) :-
    Energy > 0,
    nth0(CurrentPos, State, 'D'),
    ( move_down(CurrentPos, NextPos, Cols, N)
    ; move_left(CurrentPos, NextPos, Cols, _)
    ; move_right(CurrentPos, NextPos, Cols, _)
    ; move_up(CurrentPos, NextPos, Cols, _)
    ),
    NextPos >= 0,
    NextPos < N,
    nth0(NextPos, State, Cell),
    Cell \= 'O',
    TempEnergy is Energy - 1,
    ( Cell = 'R' -> NewEnergy = MaxEnergy ; NewEnergy = TempEnergy ),
    ( Cell = 'P' -> Collected = 1 ; Collected = 0 ),
    replace_element(CurrentPos, State, '*', TempState),
    replace_element(NextPos, TempState, 'D', NewState).

move_up(I, J, Cols, _) :- 
    J is I - Cols,
    I >= Cols.
move_down(I, J, Cols, N) :-
    J is I + Cols,
    Limit is N - Cols,
    I < Limit.
move_right(I, J, Cols, _) :- 
    J is I + 1,
    I mod Cols =\= Cols - 1.
move_left(I, J, Cols, _) :- 
    J is I - 1,
    I mod Cols =\= 0.

replace_element(0, [_|T], V, [V|T]).
replace_element(I, [H|T], V, [H|R]) :-
    I > 0,
    I1 is I - 1,
    replace_element(I1, T, V, R).

calculate_heuristic(State, Cols, H) :-
    nth0(DronePos, State, 'D'),
    findall(Distance,
        ( nth0(PPos, State, 'P'), manhattan_distance(DronePos, PPos, Cols, Distance) ),
        Distances
    ),
    ( Distances = [] -> H = 0 ; find_min(Distances, H) ).

manhattan_distance(Pos1, Pos2, Cols, Distance) :-
    Row1 is Pos1 // Cols, 
    Col1 is Pos1 mod Cols,
    Row2 is Pos2 // Cols, 
    Col2 is Pos2 mod Cols,
    DRow is abs(Row1 - Row2),
    DCol is abs(Col1 - Col2),
    Distance is DRow + DCol.

reconstruct_path(State, null, _, Cols, [CurrentXY]) :-
    get_position(State, Cols, CurrentXY).
reconstruct_path(State, Parent, Closed, Cols, Path) :-
    get_position(State, Cols, CurrentXY),
    member([ParentState, GrandParent, _, _, _, _], Closed),
    ParentState == Parent,
    reconstruct_path(ParentState, GrandParent, Closed, Cols, ParentPath),
    append(ParentPath, [CurrentXY], Path).

get_position(State, Cols, [X,Y]) :-
    nth0(Pos, State, 'D'),
    X is Pos // Cols,
    Y is Pos mod Cols.

twoD_to_oneD([], [], _, _).
twoD_to_oneD([[X,Y]|Rest], [Linear|Res], Rows, Cols):-
    twoD_to_oneD(Rest, Res, Rows, Cols),
    Linear is X*Cols + Y.

print_grid(State, Cols) :-
    ( State = [] -> true
    ;   length(Row, Cols),
        append(Row, Rest, State),
        print_row(Row),
        print_grid(Rest, Cols)
    ).

print_row([]) :- nl.
print_row([H|T]) :-
    write(H), write(' '),
    print_row(T).

solve_with_energy(Grid, Rows, Cols, MaxEnergy) :-
    list_length(Grid, N),
    N =:= Rows * Cols,
    calculate_heuristic(Grid, Cols, H),
    C = 0,
    TotalCost is C + H,
    E = MaxEnergy,
    a_star_search([[Grid, null, C, H, TotalCost, E]], [], Grid, Rows, Cols, N, MaxEnergy),
    !.
    
