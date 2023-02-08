#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var IsNew;
var SubordinatedTask;

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	IsNew = IsNew ();
	removeReminder ();
	if ( DataExchange.Load
		or DeletionMark ) then
		return;
	endif;
	setReminderDate ();
	setCompleted ();
	
EndProcedure

Procedure removeReminder ()
	
	if ( IsNew ) then
		return;
	endif; 
	Jobs.Remove ( Ref );
	
EndProcedure 

Procedure setReminderDate ()
	
	if ( Reminder = Enums.Reminder.None ) then
		return;
	endif; 
	ReminderDate = Enums.Reminder.GetDate ( Start, Reminder );
	
EndProcedure 

Procedure setCompleted ()
	
	if ( Executed ) then
		Completed = CurrentSessionDate ();
	endif;
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	updateTasks ();
	if ( DeletionMark ) then
		return;
	endif;
	if ( remindMe () ) then
		TasksReminder.Write ( ThisObject );
	endif; 
	
EndProcedure

Procedure updateTasks ()
	
	if ( Source = undefined ) then
		return;
	endif;
	lockTasks ();
	data = getTasks ();
	saveTask ( data.PerformerTasks, Performer, false );
	if ( SubordinatedTask ) then
		saveTask ( data.CreatorTasks, Creator, true );
	endif;

EndProcedure

Procedure lockTasks ()
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.Tasks");
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Source", Source );
	lock.Lock ();
	
EndProcedure

Function getTasks ()
	
	s = "
	|// #PerformerTasks
	|//
	|// Action:
	|// 1: Push or Update task
	|// 2: Complete task
	|// 3: Delete task
	|select 1 as Action, Tasks.Task as Task, Tasks.Status as Status, null as FinalStatus, Tasks.Progress as Progress, 0 as FinalProgress
	|from (
	|	select top 1 Tasks.Ref as Task, Tasks.Status as Status, Tasks.Progress as Progress
	|	from Task.UserTask as Tasks
	|	where Tasks.Source = &Source
	|	and Tasks.Performer = &Performer
	|	and not Tasks.Executed
	|	and not Tasks.DeletionMark
	|	order by Tasks.Start
	|	) as Tasks
	|union all
	|select top 1
	|	case when Tasks.Task.DeletionMark then 3 else 2 end, Tasks.Task, Tasks.Status, Tasks.Task.Status, Tasks.Progress, Tasks.Task.Progress
	|from InformationRegister.Tasks as Tasks
	|where Tasks.Source = &Source
	|and Tasks.User = &Performer
	|and ( Tasks.Task.DeletionMark or not Tasks.Completed )
	|order by Action
	|";
	SubordinatedTask = not BusinessProcess.IsEmpty () and Creator <> Performer;
	if ( SubordinatedTask ) then
		s = s + "
		|;
		|// #CreatorTasks
		|select 1 as Action, Tasks.Task as Task, Tasks.Status as Status, null as FinalStatus, Tasks.Progress as Progress, 0 as FinalProgress
		|from (
		|	select top 1 Tasks.Ref as Task, Tasks.Status as Status, Tasks.Progress as Progress
		|	from Task.UserTask as Tasks
		|	where Tasks.Source = &Source
		|	and Tasks.Creator = &Creator
		|	and not Tasks.Executed
		|	and not Tasks.DeletionMark
		|	order by Tasks.Start
		|	) as Tasks
		|union all
		|select top 1
		|	case when Tasks.Task.DeletionMark then 3 else 2 end, Tasks.Task, Tasks.Status, Tasks.Task.Status, Tasks.Progress, Tasks.Task.Progress
		|from InformationRegister.Tasks as Tasks
		|where Tasks.Source = &Source
		|and Tasks.User = &Creator
		|and ( Tasks.Task.DeletionMark or not Tasks.Completed )
		|order by Action
		|";
	endif;
	q = new Query ( s );
	q.SetParameter ( "Source", Source );
	q.SetParameter ( "Performer", Performer );
	q.SetParameter ( "Creator", Creator );
	return SQL.Exec ( q );
	
EndFunction

Procedure saveTask ( Table, User, Observation )
	
	operation = Table.Count ();
	startOrComplete = 1;
	update = 2;
	if ( operation = startOrComplete ) then
		enrollTask ( Table [ 0 ], User, Observation );
	elsif ( operation = update ) then
		next = Table [ 0 ];
		last = Table [ 1 ];
		if ( next.Task <> last.Task
			or next.Status <> last.Status
			or next.Progress <> last.Progress ) then
			enrollTask ( next, User, Observation );
		endif;
	endif;
	
EndProcedure

Procedure enrollTask ( Row, User, Observation )
	
	SetPrivilegedMode ( true );
	deleteTask = 3;
	completeTask = 2;
	r = InformationRegisters.Tasks.CreateRecordManager ();
	r.Source = Source;
	r.User = User;
	if ( Row.Action = deleteTask ) then
		r.Delete ();
	else
		r.Task = Row.Task;
		if ( Row.Action = completeTask ) then
			r.Status = Row.FinalStatus;
			r.Progress = Row.FinalProgress;
			r.Completed = true;
		else
			r.Status = Row.Status;
			r.Progress = Row.Progress;
		endif;
		r.Observation = Observation;
		r.Write ();
	endif;
	SetPrivilegedMode ( false );
	
EndProcedure

Function remindMe ()
	
	remind = Reminder <> Enums.Reminder.None;
	if ( IsNew ) then
		return remind;
	else
		return remind and not Executed and Start > ToLocalTime ( CurrentUniversalDate (), DF.Pick ( Performer, "TimeZone" ) );
	endif;
	
EndFunction

Procedure OnExecute ( Cancel )
	
	autocomplete ();
	
EndProcedure

Procedure autocomplete ()
	
	if ( BusinessProcess.IsEmpty () ) then
		return;
	endif;
	SetPrivilegedMode ( true );
	list = findUncompleted ();
	for each reference in list do
		obj = reference.GetObject ();
		obj.Executed = true;
		obj.Autocompleted = true;
		obj.Action = Action;
		obj.Write ();
	enddo;
	
EndProcedure

Function findUncompleted ()
	
	s = "
	|select Tasks.Ref as Ref
	|from Task.UserTask as Tasks
	|where not Tasks.DeletionMark
	|and not Tasks.Executed
	|and not Tasks.Mandatory
	|and Tasks.BusinessProcess = &BP
	|and Tasks.RoutePoint = &Point
	|and Tasks.Ref <> &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "BP", BusinessProcess );
	q.SetParameter ( "Point", RoutePoint );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction

Procedure OnCopy ( CopiedObject )
	
	adjustCopy ();
	
EndProcedure

Procedure adjustCopy ()
	
	BusinessProcess = undefined;
	RoutePoint = undefined;
	Point = undefined;
	Action = undefined;
	Autocompleted = false;
	Completed = undefined;
	Loop = undefined;
	Mandatory = false;
	Stage = undefined;
	Executed = false;
	ThisObject.Progress = 0;
	
EndProcedure

#endif