:-consult(league_data).

is_member(X, [X|_]).

is_member(X, [_|Tail]) :-
    is_member(X, Tail).

size(0, []).
size(X, [_|Tail]) :-
    size(X2, Tail),
    X is 1 + X2.

append(X, [], [X]).
append(X, [H|T], [H|Res]) :-
    append(X, T, Res).    

%%%%%%%%%%%%%%%%%%%% Task 1 %%%%%%%%%%%%%%%%%%%%
%players_in_team(Team, Player)

players_in_team(Team, Players):- 
    get_players(Team, Players, []).

get_players(Team, [Player | Tail], Visited) :-
    player(Player, Team, _),
    \+ is_member(Player, Visited),
    !,
    get_players(Team, Tail, [Player | Visited]).

get_players(Team, [], Visited).

%%%%%%%%%%%%%%%%%%%% Task 2 %%%%%%%%%%%%%%%%%%%%
team_count_by_country(Country, N) :-
    count_by_country(Country, [], List),
    size(N, List),
    !.

count_by_country(Country, Cur, Ans) :-
    team(Name, Country, _),        
    \+ is_member(Name, Cur),      
    append(Name, Cur, Nxt),        
    count_by_country(Country, Nxt, Ans). 

count_by_country(_, Ans, Ans).

%%%%%%%%%%%%%%%%%%%% Task 3 %%%%%%%%%%%%%%%%%%%%
most_successful_team(T) :-
    team(T, _, N),
    \+ (team(_, _, M), M > N),
    !.
    
%%%%%%%%%%%%%%%%%%%% Task 4 %%%%%%%%%%%%%%%%%%%%
%matches_of_team(Team, L).

matches_of_team(Team, Matches):- 
    get_matches(Team, Matches, []).

get_matches(Team, [(Team, Opponent, Score1, Score2) | Tail], Visited) :-
    match(Team, Opponent, Score1, Score2),
    \+ is_member((Team, Opponent, Score1, Score2), Visited),
    !,
    get_matches(Team, Tail, [(Team, Opponent, Score1, Score2) | Visited]).

get_matches(Team, [(Opponent, Team, Score1, Score2) | Tail], Visited) :-
    match(Opponent, Team, Score1, Score2),
    \+ is_member((Opponent, Team, Score1, Score2), Visited),
    !,
    get_matches(Team, Tail, [(Opponent, Team, Score1, Score2) | Visited]).

get_matches(Team, [], Visited).

%%%%%%%%%%%%%%%%%%%% Task 5 %%%%%%%%%%%%%%%%%%%%

num_matches_of_team(Team, N):-
   matches_of_team(Team, List),
   size(N, List).

%%%%%%%%%%%%%%%%%%%% Task 6 %%%%%%%%%%%%%%%%%%%%
top_scorer(P):-
    goals(P, N),
    \+ (goals(_, M), M > N),
    !. 

%%%%%%%%%%%%%%%%%%%% Task 7 %%%%%%%%%%%%%%%%%%%%
%most_common_position_in_team(Team, Pos).

% Get Positions of the Team
positions_in_team(Team, Positions) :-
    get_positions(Team, Positions, []).

get_positions(Team, [Position | Tail], Visited) :-
    player(_, Team, Position),
    \+ is_member(Position, Visited),
    !,
    get_positions(Team, Tail, [Position | Visited]).

get_positions(Team, [], Visited).

% Count each position
count_pos(_, [], 0).

count_pos(Position, [Position | Tail], Count) :-
    count_pos(Position, Tail, SubCount),
    Count is SubCount + 1.

count_pos(Position, [_ | Tail], Count) :-
    count_pos(Position, Tail, Count).

% Get the most frequent
most_frequent_pos(_, [], _, Common, Common).

most_frequent_pos(Team, [Position | Tail], MaxCount, MostCommon, MostCommon) :-
    positions_in_team(Team, Positions),
    count_pos(Position, Positions, Count),
    Count > MaxCount,
    !,
    most_frequent_pos(Team, Tail, Count, Position, MostCommon).

most_frequent_pos(Team, [Position | Tail], MaxCount, MostCommon, MostCommon) :-
    positions_in_team(Team, Positions),
    count_pos(Position, Positions, Count),
    \+ Count > MaxCount,
    !,
    most_frequent_pos(Team, Tail, MaxCount, MostCommon, MostCommon).


most_common_position_in_team(Team, MostCommon) :-
    positions_in_team(Team, Positions),
    most_frequent_pos(Team, Positions, 0, _, MostCommon).