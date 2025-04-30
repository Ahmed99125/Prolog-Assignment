% Rewritten Drone Pathfinding Implementation
% This implementation uses more modular approaches and cleaner predicate organization

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TASK 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main entry point for Task 1 - finding a drone path without energy constraints
find_drone_path(Grid, Rows, Cols) :-
    % Validate grid size
    grid_size_valid(Grid, Rows, Cols),
    
    % Find drone starting position (always 'D')
    nth0(StartPos, Grid, 'D'),
    
    % Find the optimal path
    pathfind(StartPos, Grid, [], Path, Rows, Cols),
    
    % Display results
    write('Drone Route:'), nl, nl,
    display_grid(Grid, Rows, Cols),
    
    % Print steps if path was found
    (Path \= [] -> 
        write('Steps:'), nl, nl,
        visualize_path(Grid, Path, Rows, Cols)
    ;
        write('Final: '), nl, nl,
        display_grid(Grid, Rows, Cols)
    ),
    !.

% Validate grid dimensions
grid_size_valid(Grid, Rows, Cols) :-
    length(Grid, Size),
    Size =:= Rows * Cols.

% Recursive path-finding algorithm
pathfind(Current, Grid, Visited, Path, Rows, Cols) :-
    % Base case - endpoint check
    (valid_moves(Current, Rows, Cols, Grid, Visited, []) ->
        % No more valid moves
        (nth0(Current, Grid, 'P') -> 
            Path = [Current]  % Found a package
        ; 
            Path = []         % Dead end with no package
        )
    ;
        % Get all valid moves from current position
        valid_moves(Current, Rows, Cols, Grid, Visited, ValidMoves),
        
        % Explore all possible paths from this position
        find_all_paths(ValidMoves, Grid, [Current|Visited], Rows, Cols, AllPaths),
        
        % Select the best path based on package count
        select_best_path(AllPaths, BestPathResult),
        
        % Construct final path with current position
        (nth0(Current, Grid, 'P') ->
            % Found a package at current position
            (BestPathResult = [_, BestPath], BestPath \= [] ->
                Path = [Current|BestPath]
            ;
                Path = [Current]
            )
        ;
            % No package at current position
            (BestPathResult = [Count, BestPath], Count > 0 ->
                Path = [Current|BestPath]
            ;
                Path = []
            )
        )
    ).

% Get valid moves from current position (non-obstacles, unvisited)
valid_moves(Current, Rows, Cols, Grid, Visited, ValidMoves) :-
    findall(NextPos, (
        % Generate all possible moves
        (move_left(Current, NextPos, Cols);
         move_right(Current, NextPos, Cols);
         move_up(Current, NextPos, Cols);
         move_down(Current, NextPos, Rows, Cols)),
        
        % Check if position is valid and not visited
        nth0(NextPos, Grid, Cell),
        Cell \= 'O',
        \+ member(NextPos, Visited)
    ), ValidMoves).

% Move in all four directions
move_left(Current, Next, Cols) :-
    Col is Current mod Cols,
    Col > 0,
    Next is Current - 1.

move_right(Current, Next, Cols) :-
    Col is Current mod Cols,
    Col < Cols - 1,
    Next is Current + 1.

move_up(Current, Next, Cols) :-
    Next is Current - Cols,
    Next >= 0.

move_down(Current, Next, Rows, Cols) :-
    Next is Current + Cols,
    Max is Rows * Cols,
    Next < Max.

% Explore all possible paths from a list of moves
find_all_paths([], _, _, _, _, []).
find_all_paths([Move|Moves], Grid, Visited, Rows, Cols, [[Count, Path]|Paths]) :-
    % Recursively find path from this move
    pathfind(Move, Grid, Visited, Path, Rows, Cols),
    
    % Count packages in this path
    count_packages_in_path(Path, Grid, Count),
    
    % Explore remaining moves
    find_all_paths(Moves, Grid, Visited, Rows, Cols, Paths).

% Count packages in a path
count_packages_in_path([], _, 0).
count_packages_in_path([Pos|Rest], Grid, Count) :-
    count_packages_in_path(Rest, Grid, RestCount),
    (nth0(Pos, Grid, 'P') ->
        Count is RestCount + 1
    ;
        Count = RestCount
    ).

% Select path with most packages collected
select_best_path([], [0, []]) :- !.  % No paths
select_best_path([[Count, Path]], [Count, Path]) :- !.  % Single path
select_best_path([[Count1, Path1], [Count2, Path2]|Rest], Best) :-
    % Compare first two paths
    (Count1 >= Count2 ->
        select_best_path([[Count1, Path1]|Rest], Best)
    ;
        select_best_path([[Count2, Path2]|Rest], Best)
    ).


generate_adjacent_position(Pos, NextPos, Rows, Cols) :-
    % Move left
    (Col is Pos mod Cols, Col > 0, NextPos is Pos - 1);
    
    % Move right
    (Col is Pos mod Cols, Col < Cols - 1, NextPos is Pos + 1);
    
    % Move up
    (NextPos is Pos - Cols, NextPos >= 0);
    
    % Move down
    (NextPos is Pos + Cols, MaxPos is Rows * Cols, NextPos < MaxPos).

% Display the grid
display_grid(Grid, Rows, Cols) :-
    display_grid_rows(Grid, 0, Rows, Cols).

display_grid_rows(_, Row, Rows, _) :- Row >= Rows, nl, !.
display_grid_rows(Grid, Row, Rows, Cols) :-
    display_grid_row(Grid, Row, 0, Cols),
    nl,
    NextRow is Row + 1,
    display_grid_rows(Grid, NextRow, Rows, Cols).

display_grid_row(_, _, Col, Cols) :- Col >= Cols, !.
display_grid_row(Grid, Row, Col, Cols) :-
    Index is Row * Cols + Col,
    get_cell(Grid, Index, Element),
    write(Element), write(' '),
    NextCol is Col + 1,
    display_grid_row(Grid, Row, NextCol, Cols).

% Helper to get a cell value safely
get_cell(Grid, Index) :-
    nth0(Index, Grid, Element), Element.

get_cell(Grid, Index, Element) :-
    nth0(Index, Grid, Element).

% Visualize the path on the grid
visualize_path(Grid, [Last], Rows, Cols) :-
    update_cell(Grid, Last, 'D', FinalGrid),
    write('Final:'), nl, nl,
    display_grid(FinalGrid, Rows, Cols).

visualize_path(Grid, [Step, Next|Rest], Rows, Cols) :-
    update_cell(Grid, Step, '*', TempGrid),
    update_cell(TempGrid, Next, 'D', NextGrid),
    
    % Only display intermediate steps if there are more steps
    (Rest \= [] ->
        display_grid(NextGrid, Rows, Cols),
        nl
    ; true),
    
    visualize_path(NextGrid, [Next|Rest], Rows, Cols).

% Update a grid cell
update_cell([_|Tail], 0, Value, [Value|Tail]).
update_cell([Head|Tail], Index, Value, [Head|NewTail]) :-
    Index > 0,
    NewIndex is Index - 1,
    update_cell(Tail, NewIndex, Value, NewTail).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TASK 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main entry point for Task 2 - solving with energy constraints
solve_with_energy(Grid, Rows, Cols, MaxEnergy) :-
    % Validate grid size
    grid_size_valid(Grid, Rows, Cols),
    
    % Initialize A* search
    calculate_heuristic_cost(Grid, Cols, InitialHeuristic),
    astar_search([
        % Format: [State, Parent, PathCost, Heuristic, TotalCost, Energy]
        [Grid, none, 0, InitialHeuristic, InitialHeuristic, MaxEnergy]
    ], [], Grid, Rows, Cols, MaxEnergy),
    !.

% A* search algorithm implementation
astar_search([], _, _, _, _, _) :-
    write('No solution found.'), nl, !.

astar_search(OpenList, ClosedList, InitialGrid, Rows, Cols, MaxEnergy) :-
    % Get the most promising state
    extract_best_state(OpenList, [CurrentState, Parent, PathCost, _, _, Energy], RemainingOpen),
    
    % Check if goal reached (no packages left)
    (\+ member('P', CurrentState) ->
        % Solution found
        write('Cost (Number of moves): '), write(PathCost), nl,
        write('Final grid:'), nl,
        display_grid_by_cols(CurrentState, Cols),
        
        % Reconstruct and display path
        reconstruct_solution_path(CurrentState, Parent, ClosedList, Cols, Path),
        nl, nl,
        convert_coordinates_to_indices(Path, LinearPath, Rows, Cols),
        write('Steps: '), nl, nl,
        visualize_path(InitialGrid, LinearPath, Rows, Cols)
    ;
        % Generate all possible moves from current state
        findall(
            [NewState, CurrentState, NewPathCost, NewHeuristic, NewTotalCost, NewEnergy],
            (
                apply_move(CurrentState, NewState, _, Cols, Rows*Cols, Energy, NewEnergy, MaxEnergy),
                \+ state_exists_in_closed(NewState, NewEnergy, ClosedList),
                NewPathCost is PathCost + 1,
                calculate_heuristic_cost(NewState, Cols, NewHeuristic),
                NewTotalCost is NewPathCost + NewHeuristic
            ),
            ChildStates
        ),
        
        % Add current state to closed list and merge child states into open list
        merge_states(ChildStates, RemainingOpen, NewOpenList),
        append_lists(ClosedList, [[CurrentState, Parent, PathCost, _, _, Energy]], NewClosedList),
        
        % Continue search
        astar_search(NewOpenList, NewClosedList, InitialGrid, Rows, Cols, MaxEnergy)
    ).

% Extract the state with lowest cost from open list
extract_best_state(OpenList, BestState, Remaining) :-
    find_min_cost_state(OpenList, BestState),
    delete_from_list(OpenList, BestState, Remaining).

% Find state with minimum cost
find_min_cost_state([State], State) :- !.
find_min_cost_state([State1, State2|Rest], MinState) :-
    State1 = [_, _, _, _, Cost1, _],
    State2 = [_, _, _, _, Cost2, _],
    (Cost1 =< Cost2 -> 
        find_min_cost_state([State1|Rest], MinState)
    ; 
        find_min_cost_state([State2|Rest], MinState)
    ).

% Merge new states into open list
merge_states([], OpenList, OpenList).
merge_states([[State,Parent,PathCost,H,TotalCost,Energy]|Rest], OpenList, Result) :-
    % Try to find existing state with same state and energy
    (remove_from_list([State,_,_,_,OldCost,Energy], OpenList, TempOpen),
     OldCost > TotalCost ->
        % Found better path to same state
        merge_states(Rest, [[State,Parent,PathCost,H,TotalCost,Energy]|TempOpen], Result)
    ; 
        % Check if state already exists with better cost
        (member([State,_,_,_,ExistingCost,Energy], OpenList),
         ExistingCost =< TotalCost ->
            % Existing path is better
            merge_states(Rest, OpenList, Result)
        ;
            % Add new state
            merge_states(Rest, [[State,Parent,PathCost,H,TotalCost,Energy]|OpenList], Result)
        )
    ).

% Apply a move to generate a new state
apply_move(State, NewState, Collected, Cols, GridSize, Energy, NewEnergy, MaxEnergy) :-
    % Only move if energy available
    Energy > 0,
    
    % Find drone position
    nth0(DronePos, State, 'D'),
    
    % Generate a valid move
    (move_direction(DronePos, NextPos, Cols, GridSize, down);
     move_direction(DronePos, NextPos, Cols, GridSize, left);
     move_direction(DronePos, NextPos, Cols, GridSize, right);
     move_direction(DronePos, NextPos, Cols, GridSize, up)),
    
    % Check if position is valid
    NextPos >= 0, NextPos < GridSize,
    
    % Check if cell is not an obstacle
    nth0(NextPos, State, CellContent),
    CellContent \= 'O',
    
    % Calculate energy after move
    TempEnergy is Energy - 1,
    
    % Handle recharge stations
    (CellContent = 'R' -> 
        NewEnergy = MaxEnergy 
    ; 
        NewEnergy = TempEnergy
    ),
    
    % Check if package was collected
    (CellContent = 'P' -> 
        Collected = 1 
    ; 
        Collected = 0
    ),
    
    % Update grid with new drone position
    update_cell(State, DronePos, '*', TempState),
    update_cell(TempState, NextPos, 'D', NewState).

% Move in specific directions
move_direction(Pos, NewPos, Cols, GridSize, down) :-
    NewPos is Pos + Cols,
    NewPos < GridSize.

move_direction(Pos, NewPos, Cols, _, left) :-
    NewPos is Pos - 1,
    Pos mod Cols =\= 0.

move_direction(Pos, NewPos, Cols, _, right) :-
    NewPos is Pos + 1,
    (Pos + 1) mod Cols =\= 0.

move_direction(Pos, NewPos, Cols, _, up) :-
    NewPos is Pos - Cols,
    NewPos >= 0.

% Calculate Manhattan distance heuristic
calculate_heuristic_cost(State, Cols, Heuristic) :-
    % Find drone position
    nth0(DronePos, State, 'D'),
    
    % Find all packages
    findall(Distance,
        (nth0(PackagePos, State, 'P'),
         calculate_manhattan_distance(DronePos, PackagePos, Cols, Distance)),
        Distances),
    
    % Minimum distance to nearest package, or 0 if no packages left
    (Distances = [] -> 
        Heuristic = 0 
    ; 
        min_list(Distances, Heuristic)
    ).

% Calculate Manhattan distance between two positions
calculate_manhattan_distance(Pos1, Pos2, Cols, Distance) :-
    Row1 is Pos1 // Cols,
    Col1 is Pos1 mod Cols,
    Row2 is Pos2 // Cols,
    Col2 is Pos2 mod Cols,
    RowDiff is abs(Row1 - Row2),
    ColDiff is abs(Col1 - Col2),
    Distance is RowDiff + ColDiff.

% Display grid by columns (helper for Task 2)
display_grid_by_cols(Grid, Cols) :-
    (Grid = [] -> true
    ;
        take_first_n(Grid, Cols, Row),
        drop_first_n(Grid, Cols, Rest),
        display_row(Row),
        display_grid_by_cols(Rest, Cols)
    ).

% Display a single row
display_row([]) :- nl.
display_row([Cell|Rest]) :-
    write(Cell), write(' '),
    display_row(Rest).

% Reconstruct solution path for visualization
reconstruct_solution_path(State, none, _, Cols, [CurrentPos]) :-
    get_drone_position(State, Cols, CurrentPos).

reconstruct_solution_path(State, Parent, ClosedList, Cols, Path) :-
    get_drone_position(State, Cols, CurrentPos),
    member([ParentState, GrandParent, _, _, _, _], ClosedList),
    ParentState == Parent,
    reconstruct_solution_path(ParentState, GrandParent, ClosedList, Cols, ParentPath),
    append_lists(ParentPath, [CurrentPos], Path).

% Get drone position as [Row, Col] coordinates
get_drone_position(State, Cols, [Row, Col]) :-
    nth0(Pos, State, 'D'),
    Row is Pos // Cols,
    Col is Pos mod Cols.

% Convert [Row, Col] coordinates to linear indices
convert_coordinates_to_indices([], [], _, _).
convert_coordinates_to_indices([[Row, Col]|Rest], [Index|Indices], _, Cols) :-
    Index is Row * Cols + Col,
    convert_coordinates_to_indices(Rest, Indices, _, Cols).

% Check if state exists in closed list
state_exists_in_closed(State, Energy, ClosedList) :-
    member([State, _, _, _, _, Energy], ClosedList).

% Helper functions
append_lists([], L, L).
append_lists([X|Xs], Ys, [X|Zs]) :-
    append_lists(Xs, Ys, Zs).

delete_from_list([X|Xs], X, Xs).
delete_from_list([Y|Ys], X, [Y|Zs]) :-
    X \= Y,
    delete_from_list(Ys, X, Zs).

remove_from_list(X, [X|Xs], Xs).
remove_from_list(X, [Y|Ys], [Y|Zs]) :-
    remove_from_list(X, Ys, Zs).

min_list([X], X).
min_list([X|Xs], Min) :-
    min_list(Xs, TempMin),
    Min is min(X, TempMin).

take_first_n(_, 0, []) :- !.
take_first_n([X|Xs], N, [X|Ys]) :-
    N > 0,
    N1 is N - 1,
    take_first_n(Xs, N1, Ys).

drop_first_n(Xs, 0, Xs) :- !.
drop_first_n([_|Xs], N, Ys) :-
    N > 0,
    N1 is N - 1,
    drop_first_n(Xs, N1, Ys).

% Test cases for Task 2
% solve_with_energy(['D','.','P','O','.','O','O','P','P','.','.','R'],3,4,9).
% solve_with_energy(['D','.','P','.','O','.','O','.','.','P','.','.','O','P','.','P','O','R','.','.','.','.','P','O','.'],5,5,9).
% solve_with_energy(['D', '.', '.', '.', '.', '.', 'P', '.', '.', 'R', '.', 'P', '.', '.', '.', '.'],4,4,4).