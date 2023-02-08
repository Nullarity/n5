#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var PassedRoutePoint;
var PreviousExecutor;
var NextApprovalUser;

Procedure ApprovalBeforeCreateTasks ( BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing )
	
	StandardProcessing = false;
	createApprovalTasks ( TasksBeingFormed );
	
EndProcedure

Procedure createApprovalTasks ( TasksBeingFormed )
	
	usersArray = getApprovalUsers ();
	for each user in usersArray do
		task = Tasks.Task.CreateTask ();
		task.BusinessProcess = Ref;
		task.Date = CurrentSessionDate ();
		task.RoutePoint = BusinessProcesses.TimesheetApproval.RoutePoints.Approval;
		task.User = user;
		task.Description = "" + task.RoutePoint;
		task.Write ();
		TasksBeingFormed.Add ( task );
	enddo; 
	
EndProcedure 

Function getApprovalUsers ()
	
	usersArray = new Array ();
	if ( PassedRoutePoint = BusinessProcesses.TimesheetApproval.RoutePoints.IsExistsNext ) then
		usersArray.Add ( NextApprovalUser );
		return usersArray;
	endif;
	q = new Query ();
	if ( PassedRoutePoint = BusinessProcesses.TimesheetApproval.RoutePoints.Rework ) then
		s = "
		|select TimeResolutions.User as User
		|from InformationRegister.TimeResolutions as TimeResolutions
		|where TimesheetApproval = &TimesheetApproval
		|";
		q.SetParameter ( "TimesheetApproval", Ref );
	else
		s = "
		|select min ( Priority ) as Priority
		|into MinimalPriority
		|from Catalog.Projects.ApprovalList as ApprovalList
		|where ApprovalList.Ref = &Project
		|;
		|select ApprovalList.User as User
		|from Catalog.Projects.ApprovalList as ApprovalList
		|	join MinimalPriority as MinimalPriority
		|	on MinimalPriority.Priority = ApprovalList.Priority
		|where ApprovalList.Ref = &Project
		|";
		q.SetParameter ( "Project", Project );
	endif;
	q.Text = s;
	usersArray = q.Execute ().Unload ().UnloadColumn ( "User" );
	return usersArray;
	
EndFunction 

Procedure ApprovalBeforeExecute ( BusinessProcessRoutePoint, Task, Cancel )
	
	markParallelTaskAsExecuted ( BusinessProcessRoutePoint );
	
EndProcedure

Procedure markParallelTaskAsExecuted ( RoutePoint )
	
	table = getParallelTasks ( RoutePoint );
	for each row in table do
		obj = row.Task.GetObject ();
		obj.Executed = true;
		obj.Write ();
	enddo; 
	
EndProcedure 

Function getParallelTasks ( RoutePoint )
	
	s = "
	|select Tasks.Ref as Task
	|from Task.Task as Tasks
	|where Tasks.RoutePoint = &RoutePoint
	|and Tasks.BusinessProcess = &BP
	|and Tasks.User <> &Executor
	|";
	q = new Query ( s );
	q.SetParameter ( "BP", Ref );
	q.SetParameter ( "RoutePoint", RoutePoint );
	q.SetParameter ( "Executor", SessionParameters.User );
	return q.Execute ().Unload ();
	
EndFunction

Procedure ApprovalOnExecute ( BusinessProcessRoutePoint, Task, Cancel )
	
	PreviousExecutor = DF.Pick ( Task, "User" );
	
EndProcedure

Procedure SwitchByResolutionSwitchProcessing ( SwitchPoint, Result )
	
	resolution = getResolution ();
	if ( resolution = Enums.Resolutions.Approve ) then
		//@skip-warning
		Result = SwitchPoint.Cases.Approve;
	elsif ( resolution = Enums.Resolutions.Rework ) then
		//@skip-warning
		Result = SwitchPoint.Cases.Rework;
	else
		//@skip-warning
		Result = SwitchPoint.Cases.Reject;
	endif; 
	
EndProcedure

Function getResolution ()
	
	p = new Structure ( "TimesheetApproval", Ref );
	return InformationRegisters.TimeResolutions.Get ( p ).Resolution;
	
EndFunction 

Procedure ReworkOnCreateTask ( BusinessProcessRoutePoint, TasksBeingFormed, Cancel )
	
	setExecutorByTimesheet ( TasksBeingFormed );
	
EndProcedure

Procedure setExecutorByTimesheet ( Tasks )
	
	for each task in Tasks do
		task.User = DF.Pick ( task.BusinessProcess, "Timesheet.Creator" );
	enddo; 
	
EndProcedure 

Procedure IsExistsNextConditionCheck ( BusinessProcessRoutePoint, Result )
	
	getNextApprovalUser ();
	PassedRoutePoint = BusinessProcessRoutePoint;
	Result = NextApprovalUser <> undefined;
	
EndProcedure

Procedure getNextApprovalUser ()
	
	s = "
	|select top 1 ApprovalList.Priority as Priority
	|into CurrentPriority
	|from Catalog.Projects.ApprovalList as ApprovalList
	|where ApprovalList.Ref = &Project
	|and ApprovalList.User = &PreviousExecutor
	|;
	|select top 1 ApprovalList.User as User
	|from Catalog.Projects.ApprovalList as ApprovalList
	|	join CurrentPriority as CurrentPriority
	|	on CurrentPriority.Priority < ApprovalList.Priority
	|where ApprovalList.Ref = &Project
	|order by ApprovalList.Priority
	|";
	q = new Query ( s );
	q.SetParameter ( "Project", Project );
	q.SetParameter ( "PreviousExecutor", PreviousExecutor );
	table = q.Execute ().Unload ();
	NextApprovalUser = ? ( table.Count () = 0, undefined, table [ 0 ].User );
	
EndProcedure 

Procedure ReworkOnExecute ( BusinessProcessRoutePoint, Task, Cancel )
	
	PassedRoutePoint = BusinessProcessRoutePoint;
	
EndProcedure

#endif