#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure DepartmentHeadResolutionOnCreateTask ( BusinessProcessRoutePoint, TasksBeingFormed, Cancel )
	
	setStatus ( BusinessProcessRoutePoint );
	setDepartment ( TasksBeingFormed );
	
EndProcedure

Procedure setStatus ( RoutePoint ) export
	
	record = InformationRegisters.InternalOrderStatuses.CreateRecordManager ();
	record.Document = InternalOrder;
	record.Status = getStatus ( RoutePoint );
	record.Write ();
	
EndProcedure 

Function getStatus ( RoutePoint )
	
	routePoints = BusinessProcesses.InternalOrder.RoutePoints;
	if ( RoutePoint = routePoints.DepartmentHeadResolution ) then
		return Enums.InternalOrderPoints.DepartmentHeadResolution;
	elsif ( RoutePoint = routePoints.Reject ) then
		return Enums.InternalOrderPoints.Reject;
	elsif ( RoutePoint = routePoints.Delivery ) then
		return Enums.InternalOrderPoints.Delivery;
	elsif ( RoutePoint = routePoints.Finish ) then
		return Enums.InternalOrderPoints.Finish;
	elsif ( RoutePoint = routePoints.Rework ) then
		return Enums.InternalOrderPoints.Rework;
	endif; 
	
EndFunction 

Procedure setDepartment ( Tasks )
	
	department = DF.Pick ( InternalOrder, "Department" );
	for each task in Tasks do
		task.Department = department;
	enddo; 
	
EndProcedure 

Procedure ResolutionSwitcher ( SwitchPoint, Result )
	
	resolution = DF.Pick ( InternalOrder, "Resolution" );
	if ( resolution = Enums.Resolutions.Approve ) then
		//@skip-warning
		Result = SwitchPoint.Cases.Allow;
	elsif ( resolution = Enums.Resolutions.Reject ) then
		//@skip-warning
		Result = SwitchPoint.Cases.Reject;
	elsif ( resolution = Enums.Resolutions.Rework ) then
		//@skip-warning
		Result = SwitchPoint.Cases.Rework;
	endif; 
	
EndProcedure

Procedure OnCreateTask ( BusinessProcessRoutePoint, TasksBeingFormed, Cancel )
	
	setStatus ( BusinessProcessRoutePoint );
	
EndProcedure

Procedure OnCreateTaskForUser ( BusinessProcessRoutePoint, TasksBeingFormed, Cancel )
	
	setStatus ( BusinessProcessRoutePoint );
	setUser ( TasksBeingFormed );
	
EndProcedure

Procedure setUser ( Tasks )
	
	creator = DF.Pick ( InternalOrder, "Creator" );
	for each task in Tasks do
		task.User = creator;
	enddo; 
	
EndProcedure 

Procedure DeliveryCheckExecutionProcessing ( BusinessProcessRoutePoint, Task, Result )
	
	Result = Documents.InternalOrder.DeliveryComplete ( InternalOrder );
	
EndProcedure

Procedure FinishOnComplete ( BusinessProcessRoutePoint, Cancel )
	
	setStatus ( BusinessProcessRoutePoint );
	
EndProcedure

#endif