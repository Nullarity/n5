#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var LastStage;
var LastLoop;

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( DeletionMark ) then
		removeRelations ();
		return;
	else
		if ( isRemoved () ) then
			Cancel = true;
			return;
		endif; 
	endif; 
	if ( not checkPeriod () ) then
		Cancel = true;
		return;
	endif;
	setPresentation ();
	
EndProcedure

Function checkPeriod ()
	
	if ( not Periods.Ok ( Start, Finish ) ) then
		Output.PeriodError ( , "Finish" );
		return false;
	endif; 
	return true;
	
EndFunction

Procedure removeRelations ()
	
	BP.RemoveTasks ( Ref, false );
	removeReferences ();
	
EndProcedure 

Procedure removeReferences ()
	
	list = getReferences ();
	for each reference in list do
		reference.GetObject ().SetDeletionMark ( true );
	enddo;
	
EndProcedure

Function getReferences ()
	
	s = "
	|select Tasks.Ref as Ref
	|from Task.UserTask as Tasks
	|where Tasks.Source = &Process
	|and not Tasks.DeletionMark
	|union all
	|select Commands.Ref
	|from BusinessProcess.Command as Commands
	|where Commands.Source = &Process
	|and not Commands.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Process", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction

Function isRemoved ()
	
	if ( IsNew () ) then
		return false;
	endif; 
	removed = DF.Pick ( Ref, "DeletionMark as DeletionMark" );
	if ( removed ) then
		Output.ProcessIsRemoved ();
		return true;
	endif; 
	return false;
	
EndFunction 

Procedure setPresentation ()
	
	Display = Description + ", " + Source + ", #" + Number;
	
EndProcedure

Procedure TaskBeforeCreateTasks ( RoutePoint, TasksList, StandardProcessing )
	
	StandardProcessing = false;
	list = oldTasks ();
	if ( list = undefined ) then
		newTasks ( TasksList, RoutePoint );
	else
		repeatTasks ( TasksList, list, RoutePoint );
	endif;
	
EndProcedure

Function oldTasks ()
	
	lastInfo ();
	if ( LastStage = undefined ) then
		return undefined;
	endif;
	s = "
	|select Tasks.Memo as Memo, Tasks.Display as Display, Tasks.Status as Status,
	|	Tasks.Creator as Creator, Tasks.Delegated as Delegated
	|from Task.UserTask as Tasks
	|where Tasks.Executed
	|and not Tasks.DeletionMark
	|and not Tasks.Autocompleted
	|and Tasks.BusinessProcess = &Ref
	|and Tasks.Stage = &Stage
	|and Tasks.Loop = &Loop
	|and Tasks.RoutePoint = value ( BusinessProcess.Command.RoutePoint.Checking )
	|and Tasks.Action = value ( Enum.Actions.Rework )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Stage", LastStage );
	q.SetParameter ( "Loop", LastLoop );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table );

EndFunction

Procedure lastInfo ()
	
	s = "
	|select top 1 Tasks.Stage as Stage, Tasks.Loop as Loop
	|from Task.UserTask as Tasks
	|where Tasks.Executed
	|and not Tasks.DeletionMark
	|and not Tasks.Autocompleted
	|and Tasks.BusinessProcess = &Ref
	|order by Tasks.Completed desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		LastStage = undefined;
		LastLoop = undefined;
	else
		data = table [ 0 ];
		LastStage = data.Stage;
		LastLoop = data.Loop;
	endif;
	
EndProcedure

Procedure repeatTasks ( TasksList, TasksRepeat, RoutePoint )
	
	point = BusinessProcesses.Command.PointToStatus ( RoutePoint );
	start = CurrentSessionDate ();
	finish = start + Enum.Hours1 ();
	loop = LastLoop + 1;
	for each row in TasksRepeat do
		obj = Tasks.UserTask.CreateTask ();
		obj.RoutePoint = RoutePoint;
		obj.Point = point;
		obj.Date = start;
		obj.Start = start;
		obj.Finish = finish;
		TaskForm.CalcDuration ( obj );
		obj.Reminder = Enums.Reminder._30m;
		obj.Stage = LastStage;
		obj.Loop = loop;
		delegated = row.Delegated;
		obj.Performer = ? ( delegated.IsEmpty (), row.Creator, delegated );
		obj.Creator = Creator;
		obj.BusinessProcess = Ref;
		obj.Source = Source;
		obj.Appearance = Appearance;
		obj.Memo = row.Memo;
		obj.Display = row.Display;
		obj.Status = row.Status;
		TasksList.Add ( obj );
	enddo;
	
EndProcedure

Procedure newTasks ( TasksList, RoutePoint )
	
	data = commandData ();
	noteCaption = Metadata.BusinessProcesses.Command.TabularSections.Performers.Attributes.Note.Presentation ();
	explanationCaption = Metadata.BusinessProcesses.Command.Attributes.Explanation.Presentation ();
	now = CurrentSessionDate ();
	point = BusinessProcesses.Command.PointToStatus ( RoutePoint );
	start = DatePicker.Humanize ( data.Fields.Start );
	finish = start + Enum.Hours1 ();
	for each row in data.Performers do
		obj = Tasks.UserTask.CreateTask ();
		obj.RoutePoint = RoutePoint;
		obj.Point = point;
		obj.Date = now;
		obj.Mandatory = row.Mandatory;
		obj.Start = start;
		obj.Finish = finish;
		TaskForm.CalcDuration ( obj );
		obj.Reminder = Enums.Reminder._30m;
		obj.Stage = row.Stage;
		performer = row.Performer;
		if ( performer = null ) then
			raise Output.PerformerUndefined ( new Structure ( "Role", row.Role ) );
		endif;
		obj.Creator = Creator;
		obj.Performer = performer;
		obj.BusinessProcess = Ref;
		obj.Source = Source;
		obj.Appearance = Appearance;
		parts = new Array ();
		parts.Add ( Description );
		note = row.Note;
		if ( note = "" ) then
			display = Description;
		else
			display = note;
			parts.Add ( noteCaption + ": " + note );
		endif;
		if ( Explanation <> "" ) then
			parts.Add ( explanationCaption + ": " + Explanation );
		endif;
		memo = StrConcat ( parts, "; " );
		obj.Memo = memo;
		obj.Display = display;
		TasksList.Add ( obj );
	enddo;
	
EndProcedure

Function commandData ()
	
	s = "
	|select top 1 Performers.Stage as Stage
	|into NextStages
	|from BusinessProcess.Command.Performers as Performers
	|	//
	|	// Tasks
	|	//
	|	left join Task.UserTask as Tasks
	|	on Tasks.BusinessProcess = Performers.Ref
	|	and Tasks.Stage = Performers.Stage
	|where Performers.Ref = &Ref
	|and Tasks.Ref is null
	|order by Performers.Stage
	|;
	|// @Fields
	|select
	|	case when LastTask.Completed is null then Commands.Start
	|		when LastTask.Completed < Commands.Start then Commands.Start
	|		else LastTask.Completed
	|	end as Start
	|from BusinessProcess.Command as Commands
	|	//
	|	// LastTask
	|	//
	|	left join (
	|		select top 1 Tasks.Completed as Completed
	|		from Task.UserTask as Tasks
	|		where Tasks.Executed
	|		and not Tasks.DeletionMark
	|		and not Tasks.Autocompleted
	|		and Tasks.BusinessProcess = &Ref
	|		order by Tasks.Completed desc
	|	) as LastTask
	|	on true
	|where Commands.Ref = &Ref
	|;
	|// #Performers
	|select Performers.Mandatory as Mandatory, Performers.Stage as Stage, Performers.Note as Note,
	|	case when Performers.Performer refs Enum.Roles then Performers.Performer else undefined end as Role,
	|	case when Performers.Performer refs Enum.Roles then BPRouter.User else Performers.Performer end as Performer
	|from BusinessProcess.Command.Performers as Performers
	|	//
	|	// BPRouter
	|	//
	|	left join (
	|		select distinct BPRouter.User as User, BPRouter.Role as Role
	|		from InformationRegister.BPRouter as BPRouter
	|		where BPRouter.Activity
	|		and BPRouter.Role in ( select Performer from BusinessProcess.Command.Performers where Ref = &Ref and Performer refs Enum.Roles )
	|	) as BPRouter
	|	on BPRouter.Role = Performers.Performer
	|	and Performers.Performer refs Enum.Roles
	|where Performers.Stage in ( select Stage from NextStages )
	|and Performers.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return SQL.Exec ( q );
	
EndFunction

Procedure IfPerformedConditionCheck ( RoutePoint, Performed )
	
	Performed = taskPerformed ();
	
EndProcedure

Function taskPerformed ()
	
	s = "
	|select top 1 1
	|from Task.UserTask as Tasks
	|where Tasks.Executed
	|and not Tasks.DeletionMark
	|and not Tasks.Autocompleted
	|and Tasks.BusinessProcess = &Ref
	|and Tasks.Stage = &Stage
	|and Tasks.Loop = &Loop
	|and Tasks.Action = value ( Enum.Actions.Resolve )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	lastInfo ();
	q.SetParameter ( "Stage", LastStage );
	q.SetParameter ( "Loop", LastLoop );
	return q.Execute ().IsEmpty ();
	
EndFunction

Procedure CheckingBeforeCreateTasks ( RoutePoint, TasksList, StandardProcessing )
	
	StandardProcessing = false;
	checking ( TasksList, RoutePoint );
	
EndProcedure

Procedure checking ( TasksList, RoutePoint )
	
	point = BusinessProcesses.Command.PointToStatus ( RoutePoint );
	start = CurrentSessionDate ();
	finish = start + Enum.Hours1 ();
	for each row in findCompleted () do
		obj = Tasks.UserTask.CreateTask ();
		obj.RoutePoint = RoutePoint;
		obj.Point = point;
		obj.Date = start;
		obj.Start = start;
		obj.Finish = finish;
		TaskForm.CalcDuration ( obj );
		obj.Reminder = Enums.Reminder._30m;
		obj.Stage = LastStage;
		obj.Loop = LastLoop;
		obj.Performer = Creator;
		obj.Creator = row.Performer;
		obj.BusinessProcess = Ref;
		obj.Source = Source;
		obj.Appearance = Appearance;
		obj.Memo = row.Memo;
		obj.Display = row.Display;
		obj.Status = row.Status;
		TasksList.Add ( obj );
	enddo;
	
EndProcedure

Function findCompleted ()
	
	s = "
	|select Tasks.Memo as Memo, Tasks.Display as Display, Tasks.Status as Status, Tasks.Performer as Performer
	|from Task.UserTask as Tasks
	|where Tasks.Executed
	|and not Tasks.DeletionMark
	|and not Tasks.Autocompleted
	|and Tasks.BusinessProcess = &Ref
	|and Tasks.Stage = &Stage
	|and Tasks.Loop = &Loop
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	lastInfo ();
	q.SetParameter ( "Stage", LastStage );
	q.SetParameter ( "Loop", LastLoop );
	return q.Execute ().Unload ();
	
EndFunction

Procedure IfNextStageConditionCheck ( RoutePoint, Result )
	
	lastInfo ();
	Result = stageExists ();

EndProcedure

Function stageExists ()
	
	s = "
	|select top 1 1
	|from BusinessProcess.Command.Performers as Performers
	|where Performers.Stage > &Stage
	|and Performers.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Stage", LastStage );
	q.SetParameter ( "Ref", Ref );
	return not q.Execute ().IsEmpty ();
	
EndFunction

Procedure IfControllingNeededConditionCheck ( RoutePoint, Result )
	
	Result = Control;
	
EndProcedure

Procedure ApplyDecisionSwitchProcessing ( SwitchPoint, Result )
	
	statuses = getActions ();
	if ( statuses.Find ( Enums.Actions.Reject ) <> undefined ) then
		//@skip-warning
		Result = SwitchPoint.Cases.Terminate;
	elsif ( statuses.Find ( Enums.Actions.Rework ) <> undefined ) then
		//@skip-warning
		Result = SwitchPoint.Cases.Repeat;
	else
		//@skip-warning
		Result = SwitchPoint.Cases.Continue;
	endif;
	
EndProcedure

Function getActions ()
	
	s = "
	|select distinct Tasks.Action as Action
	|from Task.UserTask as Tasks
	|where Tasks.Executed
	|and not Tasks.DeletionMark
	|and not Tasks.Autocompleted
	|and Tasks.BusinessProcess = &Ref
	|and Tasks.Stage = &Stage
	|and Tasks.Loop = &Loop
	|and Tasks.RoutePoint = value ( BusinessProcess.Command.RoutePoint.Checking )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	lastInfo ();
	q.SetParameter ( "Stage", LastStage );
	q.SetParameter ( "Loop", LastLoop );
	return q.Execute ().Unload ().UnloadColumn ( "Action" );
	
EndFunction

Procedure IfLastTaskConditionCheck ( BusinessProcessRoutePoint, Result )
	
	lastInfo ();
	Result = not stageExists ();
	
EndProcedure

#endif