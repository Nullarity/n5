#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure HeadShouldApprove ( BusinessProcessRoutePoint, Result )
	
	data = DF.Values ( SalesOrder, "Customer.ApproveSalesOrders as A1, Creator.ApproveSalesOrders as A2" );
	Result = data.A1 or data.A2;
	
EndProcedure

Procedure DepartmentHeadResolutionOnCreateTask ( BusinessProcessRoutePoint, TasksBeingFormed, Cancel )
	
	setStatus ( BusinessProcessRoutePoint );
	setDepartment ( TasksBeingFormed );
	
EndProcedure

Procedure setStatus ( RoutePoint ) export
	
	record = InformationRegisters.SalesOrderStatuses.CreateRecordManager ();
	record.Document = SalesOrder;
	record.Status = getStatus ( RoutePoint );
	record.Write ();
	
EndProcedure 

Function getStatus ( RoutePoint )
	
	routePoints = BusinessProcesses.SalesOrder.RoutePoints;
	if ( RoutePoint = routePoints.DepartmentHeadResolution ) then
		return Enums.SalesOrderPoints.DepartmentHeadResolution;
	elsif ( RoutePoint = routePoints.Reject ) then
		return Enums.SalesOrderPoints.Reject;
	elsif ( RoutePoint = routePoints.Shipping ) then
		return Enums.SalesOrderPoints.Shipping;
	elsif ( RoutePoint = routePoints.Finish ) then
		return Enums.SalesOrderPoints.Finish;
	elsif ( RoutePoint = routePoints.Rework ) then
		return Enums.SalesOrderPoints.Rework;
	elsif ( RoutePoint = routePoints.Invoicing ) then
		return Enums.SalesOrderPoints.Invoicing;
	endif; 
	
EndFunction 

Procedure setDepartment ( Tasks )
	
	department = DF.Pick ( SalesOrder, "Department" );
	for each task in Tasks do
		task.Department = department;
	enddo; 
	
EndProcedure 

Procedure ResolutionSwitcher ( SwitchPoint, Result )
	
	resolution = DF.Pick ( SalesOrder, "Resolution" );
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
	
	Documents.Shipment.Create ( SalesOrder );
	setStatus ( BusinessProcessRoutePoint );
	
EndProcedure

Procedure OnCreateTaskForUser ( BusinessProcessRoutePoint, TasksBeingFormed, Cancel )
	
	setStatus ( BusinessProcessRoutePoint );
	setUser ( TasksBeingFormed );
	
EndProcedure

Procedure setUser ( Tasks )
	
	creator = DF.Pick ( SalesOrder, "Creator" );
	for each task in Tasks do
		task.User = creator;
	enddo; 
	
EndProcedure 

Procedure CheckServices ( BusinessProcessRoutePoint, Result )
	
	Result = servicesOnly ();
	
EndProcedure

Function servicesOnly ()
	
	s = "
	|select top 1 false as Services
	|from Document.SalesOrder.Items as Items
	|where Items.Ref = &SalesOrder
	|union all
	|select top 1 true
	|from Document.SalesOrder.Services as Services
	|where Services.Ref = &SalesOrder
	|";
	q = new Query ( s );
	q.SetParameter ( "SalesOrder", SalesOrder );
	table = q.Execute ().Unload ();
	return table.Count () = 1 and table [ 0 ].Services;
	
EndFunction 

Procedure ShippingCheckExecutionProcessing ( BusinessProcessRoutePoint, Task, Result )
	
	Result = Documents.SalesOrder.ShippingComplete ( SalesOrder );
	
EndProcedure

Procedure FinishOnComplete ( BusinessProcessRoutePoint, Cancel )
	
	setStatus ( BusinessProcessRoutePoint );
	
EndProcedure

Procedure CheckShipment ( BusinessProcessRoutePoint, Result )
	
	Result = DF.Pick ( SalesOrder, "Department.Shipments" );

EndProcedure

#endif