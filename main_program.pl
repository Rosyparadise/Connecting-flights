%Menu
run :-
	repeat,
	nl,write("Flight consultant"),nl,
	write("================="),nl,
	write("1 - Load flight table"),nl,
	write("2 - Flights between cities"),nl,
	write("3 - Best flight between cities"),nl,
	write("0 - Exit Program"),nl,nl,
	write("Choose (0-3): "),
	read(X),nl,
	(
		X=0,
		run(0);
		X=1,
		run(1);
		X=2,
		run(2);
		X=3,
		run(3);
		run(X)
	).

run(0) :- write("Thank you for using the program!").

run(1) :-
	nl,nl,write("Give me the name of the file that contains the flight table: "),
	read(FileName),nl,
	consult(FileName),
	%declare isConnected as multifile so prolog doesnt overwrite it if more than one files are loaded.
	multifile(isConnected/3),
	write("Flight table loaded."),nl,
	run.


run(2) :-
	nl,nl,write("Departure: "),read(Place1),nl,
	write("Arrival: "),read(Place2),nl,
	write("Day: "),read(Day),nl,nl,nl,
	write("From: "),write(Place1),write("  To: "),write(Place2),
	write("  Day: "),write(Day),nl,nl,
	%gather all output from route to AllRoute
	findall(Route-DeptTime-ArrTime-TotalLength,route(Place1,Place2,Day,Route,DeptTime,ArrTime,TotalLength),AllRoutes),
	writeRouteInfoHelper(AllRoutes),run.


run(3) :-
	nl,nl,write("Departure: "),read(Place1),nl,
	write("Arrival: "),read(Place2),nl,
	write("Day: "),read(Day),nl,nl,nl,
	write("From: "),write(Place1),write("  To: "),write(Place2),
	write("  Day: "),write(Day),nl,nl,
	best_route(Place1,Place2,Day,BestRoute,DeptTime,ArrTime,ShortestLength),
	write("Best route: "),nl,
	(
		%seperate cases where route is a list of flights and when route is a direct flight ( BestRoute is not a list).
		is_list(BestRoute),
		!,
		writeRouteInfo(BestRoute,DeptTime,ArrTime,ShortestLength);
		writeRouteInfo([BestRoute],DeptTime,ArrTime,ShortestLength)
	),
	run.

run(_) :-
	write("Please select a number between 0 and 3!"),nl,run.

%writeRouteInfoHelper passes each route combination to writeRouteInfo so it gets printed
%seperates cases where route is a list and when its not (direct flight)
writeRouteInfoHelper([]).
writeRouteInfoHelper([Route-DeptTime-ArrTime-TotalLength|TheRest]) :-
	write("Route: "),nl,
	(
		is_list(Route),
		!,
		writeRouteInfo(Route,DeptTime,ArrTime,TotalLength);
		writeRouteInfo([Route],DeptTime,ArrTime,TotalLength)
	),

	writeRouteInfoHelper(TheRest).

%takes a route result and prints it in an elegant way. Gets called to print each different route.
writeRouteInfo([],DeptTime,ArrTime,TotalLength) :-
	%transforms HOURS-MINUTES to HOURS:MINUTES just like the example output.
	DeptTime=..DeptTimeList,
	nth1(2,DeptTimeList,DeptTimeHours),
	nth1(3,DeptTimeList,DeptTimeMinutes),
	ArrTime=..TarrtimeList,
	nth1(2,TarrtimeList,TarrtimeHours),
	nth1(3,TarrtimeList,TarrtimeMinutes),
	write("Total Route:  Departure: "),write(DeptTimeHours),write(":"),write(DeptTimeMinutes),
	write("  Arrival: "),write(TarrtimeHours),write(":"),write(TarrtimeMinutes),
	write("  Flight length: "),write(TotalLength),write(" min"),nl,nl.
writeRouteInfo([CurrRoute|Alts],DeptTime,ArrTime,TotalLength) :-
	CurrRoute=..CurrRouteList,
	nth1(2,CurrRouteList,TPlace1),
	nth1(3,CurrRouteList,TPlace2),
	nth1(4,CurrRouteList,TFlightCode),
	nth1(5,CurrRouteList,TDeptTime),
	TDeptTime=..TDeptTimeList,
	nth1(2,TDeptTimeList,TDeptTimeHours),
	nth1(3,TDeptTimeList,TDeptTimeMinutes),
	nth1(6,CurrRouteList,Tarrtime),
	Tarrtime=..TarrtimeList,
	nth1(2,TarrtimeList,TarrtimeHours),
	nth1(3,TarrtimeList,TarrtimeMinutes),
	write("   "),write(TPlace1),write(" -> "),write(TPlace2),
	write(" ("),write(TFlightCode),write(")  "),
	write("Dep: "),write(TDeptTimeHours),write(":"),write(TDeptTimeMinutes),
	write("  arr: "),write(TarrtimeHours),write(":"),write(TarrtimeMinutes),nl,
	writeRouteInfo(Alts,DeptTime,ArrTime,TotalLength).
	% ^ transforms HOURS-MINUTES to HOURS:MINUTES just like the example output.



% seperates cases where there is a connecting flight and when more than one flight is needed.
route(Place1,Place2,Day,Route,DeptTime,ArrTime,TotalLength) :-
	isConnected(Place1,Place2,Flights),
		pickCorrectFlights(Flights,Route,Day,Place1,Place2),
		Route=..Temp,
		nth1(5,Temp,DeptTime),
		nth1(6,Temp,ArrTime),
		DeptTime=..Depttimelist,
		ArrTime=..ArrTimelist,
		nth1(2,Depttimelist,A),
		nth1(3,Depttimelist,B),
		nth1(2,ArrTimelist,X),
		nth1(3,ArrTimelist,Y),
		M is Y-B,
	    H is X-A,
	    TotalLength is H*60+M;
	findAllPathCombinations(Place1,Place2,[],Day,Route,DeptTime,ArrTime,TotalLength).

%finds all connected paths from place1 to place2 by checking the given data.
findAllPathCombinations(Place1,Place2,L,Day,Route,DeptTime,ArrTime,TotalLength):-
	isConnected(Place1,Place2,_),
	append([Place2,Place1],L,L1),
	length(L1,Len),
	LenFinal is Len - 1,
	reverse(L1,L2),
	length(Route,LenFinal),
	%passes on each connected path
	findValidFlights(L2,Route,DeptTime,ArrTime,TotalLength,1,Day,_).

findAllPathCombinations(Place1,Place2,L,Day,Route,DeptTime,ArrTime,TotalLength):-
%adds already visited places to a list (L) so there are no cycles
	not(Place1 = Place2),
	isConnected(Place1,X,_),
	not(member(X,L)),
	append([Place1],L,L1),
	findAllPathCombinations(X,Place2,L1,Day,Route,DeptTime,ArrTime,TotalLength).


%is called by findALlPathCombinations, giving it a possible solution.
%findValidFlights' job is to find the correct flights from point1 to point2 and if those are at least 40 minutes apart.
findValidFlights(L1,[Head|Tail],DeptTime,ArrTime,TotalLength,Counter,Day,ArrTimeToCalc):-
%in case it's the first time entering the predicate where there is no need to check if a flight is 40 minutes apart from another one.
	Counter=:=1,
	nth1(1,L1,Current),
	nth1(2,L1,Destination),
	isConnected(Current,Destination,AvailableFlights),
	pickCorrectFlights(AvailableFlights,CorrectFlight,Day,Current,Destination),
	Head=CorrectFlight,
	CorrectFlight=..Temp,
	nth1(5,Temp,DeptTime),
	nth1(6,Temp,ArrTimeToCalc),
	Counter1 is Counter+1,
	findValidFlights(L1,Tail,DeptTime,ArrTime,TotalLength,Counter1,Day,ArrTimeToCalc).

findValidFlights(L1,[Head|Tail],DeptTime,ArrTime,TotalLength,Counter,Day,ArrTimeToCalc):-
%in case the initial flight has already been chosen and now there needs to be the least a 40 minute gap between each flight
	Counter > 1,
	length(L1,Length),
	Counter1 is Counter+1,
	nth1(Counter,L1,Current),
	nth1(Counter1,L1,Destination),
	isConnected(Current,Destination,AvailableFlights),
	pickCorrectFlights(AvailableFlights,CorrectFlight,Day,Current,Destination),
	CorrectFlight=..Temp,
	nth1(5,Temp,TimeA),
	ArrTimeToCalc=..ArrTimeToCalcList,
	TimeA=..TimeAList,
	nth1(2,TimeAList,HourNEW),
	nth1(3,TimeAList,MinutesNEW),
	nth1(2,ArrTimeToCalcList,HourOLD),
	nth1(3,ArrTimeToCalcList,MinutesOLD),
	HoursDifference is HourNEW - HourOLD,
    MinutesDifference is MinutesNEW - MinutesOLD,
    TotalDifference is HoursDifference*60 + MinutesDifference,
    TotalDifference >= 40,
    Head=CorrectFlight,
    (
    Counter < Length-1,
    nth1(6,Temp,ArrTimeToCalc1),
    findValidFlights(L1,Tail,DeptTime,ArrTime,TotalLength,Counter1,Day,ArrTimeToCalc1);
    Counter =:= Length-1,
    nth1(6,Temp,ArrTime),
    DeptTime=..Depttimelist,
	ArrTime=..ArrTimelist,
	nth1(2,Depttimelist,A),
	nth1(3,Depttimelist,B),
	nth1(2,ArrTimelist,X),
	nth1(3,ArrTimelist,Y),
	M is Y-B,
    H is X-A,
    TotalLength is H*60+M).
    %there are two possibilities, the flight is neither the first or the last one,
    %in which case the predicate backtracks, or it's the final flight and the total length
    %is calculated.


%checks if the flight is available that specific day and gather all information before returning it to findValidFlights.
pickCorrectFlights(_,CorrectFlight,_,_,_) :- nonvar(CorrectFlight),!.

pickCorrectFlights([Head|Tail],CorrectFlight,Day,Place1,Place2) :-
	Head=..Flight,
	nth1(5,Flight,Days),
	Days=..Dayslist,
	member(Day,Dayslist),
	nth1(4,Flight,Flightcode),
	nth1(2,Flight,DeptTime),
	nth1(3,Flight,ArrTime),
	CorrectFlight=flight(Place1,Place2,Flightcode,DeptTime,ArrTime),
	pickCorrectFlights(Tail,CorrectFlight,Day,Place1,Place2).

pickCorrectFlights([_|Tail],CorrectFlight,Day,Place1,Place2) :-
	pickCorrectFlights(Tail,CorrectFlight,Day,Place1,Place2).




%seperates cases where best_route is a list of flights or a single connected flight.
best_route(Place1,Place2,Day,BestRoute,DeptTime,ArrTime,ShortestLength):-
	%gathers all output from route as to calculate the least TotalLength
	findall(Route-TotalLength, 	route(Place1,Place2,Day,Route,_,_,TotalLength), AllRoutes),
	list_min(AllRoutes,Result),
	Result=..FinalResult,
	nth1(2,FinalResult,BestRoute),
	(
		is_list(BestRoute),
		!,
		length(BestRoute,LenOfRoute),
		nth1(1,BestRoute,FirstFlight),
		FirstFlight=..FirstFlightList,
		nth1(5,FirstFlightList,DeptTime),
		nth1(LenOfRoute,BestRoute,FinalFlight),
		FinalFlight=..FinalFlightList,
		nth1(6,FinalFlightList,ArrTime);
		BestRoute=..BestRouteList,
		nth1(5,BestRouteList,DeptTime),
		nth1(6,BestRouteList,ArrTime)
	),
	nth1(3,FinalResult,ShortestLength).



%list_min is called to find the shortest length and return it along with the path.
list_min([Path-PathLength|Rest], MinPath-MinpathLength) :-
    	list_min(Rest, Path-PathLength, MinPath-MinpathLength).

list_min([], MinPath-MinpathLength, MinPath-MinpathLength).

list_min([Path-PathLength|Rest], PathPrev-PathLengthPrev, MinPath-MinpathLength) :-
    (PathLength<PathLengthPrev,
    list_min(Rest, Path-PathLength, MinPath-MinpathLength);
    list_min(Rest,PathPrev-PathLengthPrev,MinPath-MinpathLength)).