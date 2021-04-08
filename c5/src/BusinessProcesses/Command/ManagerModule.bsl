#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Display" );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Data.Display;
	
EndProcedure

Function PointToStatus ( RoutePoint ) export
	
	points = BusinessProcesses.Command.RoutePoints;
	if ( RoutePoint = points.Task ) then
		return Enums.CommandPoints.Task;
	elsif ( RoutePoint = points.Checking ) then
		return Enums.CommandPoints.Checking;
	elsif ( RoutePoint = points.Finish ) then
		return Enums.CommandPoints.Finish;
	endif; 
	
EndFunction 

Function StatusToPoint ( Status ) export
	
	points = BusinessProcesses.Command.RoutePoints;
	if ( Status = Enums.CommandPoints.Task ) then
		return points.Task;
	elsif ( Status = Enums.CommandPoints.Checking ) then
		return points.Checking;
	elsif ( Status = Enums.CommandPoints.Finish ) then
		return points.Finish;
	endif; 
	
EndFunction 

#endif