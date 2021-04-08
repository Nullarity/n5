#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Command;

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		if ( undoAllowed () ) then
			removeReferences ();
		else
			Cancel = true;
		endif; 
	else
		if ( WriteMode = DocumentWriteMode.Posting ) then
			defineCommand ( WriteMode );
			if ( not performCommand () ) then
				Cancel = true;
				return;
			endif; 
		endif; 
	endif; 
	
EndProcedure

Function undoAllowed ()
	
	if ( Logins.Admin () ) then
		return true;
	endif; 
	if ( approvalStarted () ) then
		Output.TimesheetCannotBeChanged ();
		return false;
	endif; 
	return true;
	
EndFunction 

Function approvalStarted ()
	
	s = "
	|select top 1 1
	|from BusinessProcess.TimesheetApproval as TimesheetApproval
	|where TimesheetApproval.Timesheet = &Timesheet
	|and TimesheetApproval.Started
	|and not TimesheetApproval.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Timesheet", Ref );
	return q.Execute ().Select ().Next ();
	
EndFunction 

Procedure removeReferences ()
	
	relatedTasks = getTasks ();
	removeTasks ( relatedTasks );
	removed = new Map ();
	table = ThisObject [ TableName ];
	for each row in table do
		approval = row.TimesheetApproval;
		if ( removed [ approval ] = undefined ) then
			removeApproval ( approval );
			removed [ approval ] = true;
		endif; 
		row.TimesheetApproval = undefined;
		row.Resolution = undefined;
	enddo; 
	
EndProcedure 

Function getTasks ()
	
	s = "
	|select Task.Ref as Ref
	|from Task.Task as Task
	|	join BusinessProcess.TimesheetApproval as TimesheetApproval
	|	on TimesheetApproval.Ref = Task.BusinessProcess
	|	and TimesheetApproval.Timesheet = &Timesheet
	|where not Task.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Timesheet", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 

Procedure removeTasks ( Tasks )
	
	for each task in Tasks do
		obj = task.GetObject ();
		obj.Delete ();
	enddo; 
	
EndProcedure 

Procedure removeApproval ( Process )
	
	if ( Process.IsEmpty () ) then
		return;
	endif; 
	obj = Process.GetObject ();
	obj.Delete ();
	
EndProcedure 

Procedure defineCommand ( WriteMode )
	
	AdditionalProperties.Property ( "Command", Command );
	if ( WriteMode <> DocumentWriteMode.Posting ) then
		return;
	endif; 
	if ( Command = undefined and not Posted ) then
		Command = "SendForApproval";
	endif; 
	AdditionalProperties.Insert ( "Command", Command );
	
EndProcedure 

Function performCommand ()
	
	SetPrivilegedMode ( true );
	if ( Command = undefined ) then
		return true;
	elsif ( Command = "SendForApproval" ) then
		startTimesheetApprovals ();
	elsif ( Command = "ApplyResolutions"
		or Command = "ApproveTimesheet" ) then
		writeResolutions ();
		executeTasks ();
	elsif ( Command = "SendForApprovalAgain" ) then
		executeTasks ();
	endif; 
	SetPrivilegedMode ( false );
	return true;
	
EndFunction 

Procedure startTimesheetApprovals ()
	
	if ( IsNew () ) then
		SetNewObjectRef ( Documents.Timesheet.GetRef ( new UUID () ) );
		timesheetRef = GetNewObjectRef ();
	else
		timesheetRef = Ref;
	endif; 
	table = ThisObject [ TableName ];
	for each row in table do
		useTimesheetApproval = DF.Pick ( row.Project, "UseApprovingProcess" );
		if ( not useTimesheetApproval ) then
			continue;
		endif; 
		setAndStartTimesheetApproval ( table, row, timesheetRef );
	enddo; 
	
EndProcedure 

Procedure setAndStartTimesheetApproval ( Table, Row, Timesheet )
	
	relatedTimesheetApproval = getRelatedTimesheetApproval ( Table, Row );
	if ( relatedTimesheetApproval = undefined ) then
		obj = BusinessProcesses.TimesheetApproval.CreateBusinessProcess ();
		obj.Date = CurrentSessionDate ();
		obj.Timesheet = Timesheet;
		obj.Project = Row.Project;
		obj.Write ();
		obj.Start ();
		Row.TimesheetApproval = obj.Ref;
	else
		Row.TimesheetApproval = relatedTimesheetApproval;
	endif; 
	
EndProcedure

Function getRelatedTimesheetApproval ( Table, Row )
	
	if ( not Row.ExistTimeEntries ) then
		return undefined;
	endif;
	relatedTimesheetApproval = undefined;
	otherTimeType = ? ( Row.TimeType = Enums.Time.Billable, Enums.Time.NonBillable, Enums.Time.Billable );
	relatedRows = Table.FindRows ( new Structure ( "Project, TimeType", Row.Project, otherTimeType ) );
	for each relatedRow in relatedRows do
		if ( not relatedRow.TimesheetApproval.IsEmpty () ) then
			relatedTimesheetApproval = relatedRow.TimesheetApproval;
			break;
		endif;
	enddo; 
	return relatedTimesheetApproval;
	
EndFunction

Procedure writeResolutions ()
	
	for each item in AdditionalProperties.Resolutions do
		timeResolutions = InformationRegisters.TimeResolutions.CreateRecordManager ();
		timeResolutions.TimesheetApproval = item.Key;
		timeResolutions.User = SessionParameters.User;
		timeResolutions.Resolution = item.Value;
		timeResolutions.Write ();
	enddo; 
	
EndProcedure 

Procedure executeTasks ()
	
	for each task in AdditionalProperties.Tasks do
		taskObject = task.GetObject ();
		taskObject.ExecuteTask ();
	enddo; 
	
EndProcedure 

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords, AdditionalProperties );
	Cancel = not Documents.Timesheet.Post ( env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	if ( not DeletionMark
		and undoAllowed () ) then
		removeReferences ();
	endif; 
	
EndProcedure

#endif