#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Meta;
var Metaname;
var Env;
var FilterTimesheet;
var FilterProject;
var FilterTasks;
var Approve;
var ProcessingRowParams;
var Row;

Procedure Exec () export
	
	init ();
	approve ();

EndProcedure

Procedure init ()
	
	Meta = Metadata ();
	Metaname = Meta.FullName ();
	FilterTimesheet = new Structure ( "Timesheet" );
	FilterProject = new Structure ( "Project" );
	FilterTasks = new Structure ( "RoutePoint, BP" );
	Approve = Enums.Resolutions.Approve;
	ProcessingRowParams = new Structure ( "Row, Count" );
	ProcessingRowParams.Count = Parameters.Timesheets.Count ();
	Row = 1;
	
EndProcedure 

Procedure approve () 

	getData ();
	allTasks = Env.Tasks;
	allStatuses = Env.Statuses;
	for each timesheet in Parameters.Timesheets do
		processingRow ();
		FilterTimesheet.Timesheet = timesheet;
		tasksTimesheet = allTasks.Copy ( FilterTimesheet );
		statuses = allStatuses.FindRows ( FilterTimesheet );
		statusApproval = ( statuses.Count () > 0 and statuses [ 0 ].Approval );
		routePoint = getRoutePoint ( tasksTimesheet );
		object = timesheet.GetObject ();
		if ( object.DeletionMark
			or not statusApproval
			or routePoint <> "Approval" ) then
			Output.TimesheetNotApproved ( new Structure ( "Timesheet", timesheet ) );
			continue;
		endif;
		FilterTasks.RoutePoint = routePoint;
		allowed = getAllowed ( object, tasksTimesheet );
		write ( object, allowed );
	enddo;

EndProcedure

Procedure getData () 

	SQL.Init ( Env );
	sqlTasks ();
	sqlProjects ();
	sqlStatuses ();
	getTables ();
	addIndexes ();

EndProcedure

Procedure sqlTasks ()
	
	s = "
	|// #Tasks
	|select Tasks.Ref as Task, Tasks.BusinessProcess as BP, cast ( BusinessProcess as BusinessProcess.TimesheetApproval ).Timesheet as Timesheet,
	|	case when Tasks.RoutePoint = value ( BusinessProcess.TimesheetApproval.RoutePoint.Approval ) then ""Approval""
	|		when Tasks.RoutePoint = value ( BusinessProcess.TimesheetApproval.RoutePoint.Rework ) then ""Rework""
	|	end as RoutePoint
	|from Task.Task.TasksByExecutive ( ,
	|	not Executed
	|	and BusinessProcess refs BusinessProcess.TimesheetApproval
	|	and cast ( BusinessProcess as BusinessProcess.TimesheetApproval ).Timesheet in ( &Timesheets ) ) as Tasks
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlProjects ()
	
	s = "
	|// Projects
	|select Table.Ref as Timesheet, Table.Project as Project
	|into Projects
	|from Document.Timesheet.Month as Table
	|where Table.Ref in ( &Timesheets )
	|and Table.Ref.TableName = ""Month""
	|union
	|select Table.Ref, Table.Project
	|from Document.Timesheet.OneWeek as Table
	|where Table.Ref in ( &Timesheets )
	|and Table.Ref.TableName = ""OneWeek""
	|union
	|select Table.Ref, Table.Project
	|from Document.Timesheet.Other as Table
	|where Table.Ref in ( &Timesheets )
	|and Table.Ref.TableName = ""Other""
	|union
	|select Table.Ref, Table.Project
	|from Document.Timesheet.TwoWeeks as Table
	|where Table.Ref in ( &Timesheets )
	|and Table.Ref.TableName = ""TwoWeeks""
	|index by Table.Project
	|;
	|// #Projects
	|select allowed AllowedProjects.Ref as Project, Projects.Timesheet as Timesheet
	|from Catalog.Projects as AllowedProjects
	|	//
	|	//	Projects
	|	//
	|	join ( select distinct Projects.Project as Project, Projects.Timesheet as Timesheet
	|			from Projects as Projects ) as Projects
	|	on Projects.Project = AllowedProjects.Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlStatuses ()
	
	s = "
	|// #Statuses
	|select Statuses.Timesheet as Timesheet, 
	|	case when Statuses.Status = value ( Enum.TimesheetStatuses.Approval ) then true else false end as Approval
	|from InformationRegister.TimesheetStatuses as Statuses
	|where Statuses.Timesheet in ( &Timesheets )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables () 

	Env.Q.SetParameter ( "Timesheets", Parameters.Timesheets );
	SQL.Perform ( Env );

EndProcedure

Procedure addIndexes () 

	indexes = Env.Tasks.Indexes;
	indexes.Add ( "Timesheet" );
	indexes.Add ( "RoutePoint, BP" );
	indexes = Env.Projects.Indexes;
	indexes.Add ( "Timesheet" );
	indexes.Add ( "Project" );
	Env.Statuses.Indexes.Add ( "Timesheet" );

EndProcedure

Procedure processingRow () 

	ProcessingRowParams.Row = Row;
	Progress.Put ( Output.ProcessingRow ( ProcessingRowParams ), JobKey );

EndProcedure

Function getRoutePoint ( Table )
	
	if ( Table.Find ( "Approval", "RoutePoint" ) <> undefined ) then
		return "Approval";
	elsif ( Table.Find ( "Rework", "RoutePoint" ) <> undefined ) then
		return "Rework";
	else
		return "";
	endif;
	
EndFunction 

Function getAllowed ( Object, TasksTimesheet ) 

	allowedResolutions = new Map ();
	allowedTasks = new Array ();
	projects = Env.Projects.Copy ( FilterTimesheet );
	filterByTasks = ( TasksTimesheet.Count () > 0 );
	for each row in Object [ Object.TableName ] do
		FilterProject.Project = row.Project;
		if ( projects.FindRows ( FilterProject ).Count () = 0 ) then
			continue;
		elsif ( filterByTasks ) then
			FilterTasks.BP = row.TimesheetApproval;
			foundRows = TasksTimesheet.FindRows ( FilterTasks );
			if ( foundRows.Count () = 0 ) then
				continue;
			endif;	
			allowedTasks.Add ( foundRows [ 0 ].Task );
		endif;
		row.Resolution = Approve;
		allowedResolutions [ row.TimesheetApproval ] = Approve;
	enddo;
	return new Structure ( "Resolutions, Tasks", allowedResolutions, allowedTasks );

EndFunction

Procedure write ( Object, Allowed ) 

	properties = Object.AdditionalProperties;
	properties.Insert ( "Command", "ApproveTimesheet" );
	properties.Insert ( "Resolutions", Allowed.Resolutions );
	properties.Insert ( "Tasks", Allowed.Tasks );
	try
		Object.Write ( DocumentWriteMode.Posting );
	except
		logError ( ErrorDescription () );
	endtry;

EndProcedure

Procedure logError ( Error )
	
	Output.Error ( new Structure ( "Error", Error ) );
	WriteLogEvent ( Metaname, EventLogLevel.Error, Meta, , Error );
	
EndProcedure

#endif