#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkTasks ( CheckedAttributes );
	checkWarehouse ( CheckedAttributes );
	
EndProcedure

Procedure checkTasks ( CheckedAttributes )
	
	obligatoryTasks = DF.Pick ( Project, "ObligatoryTasks" );
	if ( obligatoryTasks ) then
		CheckedAttributes.Add ( "Tasks.Task" );
	endif; 
	
EndProcedure 

Procedure checkWarehouse ( CheckedAttributes )
	
	if ( Items.Count () > 0 ) then
		CheckedAttributes.Add ( "Warehouse" );
	endif; 
	
EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( alreadyExists () ) then
		Cancel = true;
		return;
	endif; 
	if ( not checkTimesheetPeriod () ) then
		Cancel = true;
		return;
	endif; 
	removeReminder ();
	adjustTimeOfDate ();
	setReminderDate ();
	
EndProcedure

Function alreadyExists ()
	
	if ( timeEntryFound () ) then
		Output.TimeEntryAlreadyExists ( new Structure ( "Date, Customer", Format ( Date, "DLF=D" ), Customer ) );
		return true;
	endif; 
	return false;
	
EndFunction

Function timeEntryFound ()
	
	s = "
	|select top 1 1
	|from Document.TimeEntry as TimeEntries
	|where TimeEntries.Date between &DateStart and &DateEnd
	|and TimeEntries.Project = &Project
	|and TimeEntries.Employee = &Employee
	|and TimeEntries.Ref <> &CurrentTimeEntry
	|and not TimeEntries.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "DateStart", BegOfDay ( Date ) );
	q.SetParameter ( "DateEnd", EndOfDay ( Date ) );
	q.SetParameter ( "Project", Project );
	q.SetParameter ( "Employee", Employee );
	q.SetParameter ( "CurrentTimeEntry", Ref );
	return not q.Execute ().IsEmpty ();
	
EndFunction

Function checkTimesheetPeriod ()
	
	if ( Employee.IsEmpty () ) then
		return true;
	endif; 
	if ( AdditionalProperties.Property ( "ChangedFromTimesheet" ) ) then
		return true;
	endif; 
	existedTimesheet = Documents.TimeEntry.GetTimesheetByEmployee ( Date, Employee );
	if ( existedTimesheet <> undefined ) then
		Output.TimesheetComprisesTimeEntry ( new Structure ( "Employee, Timesheet", Employee, existedTimesheet ), , existedTimesheet );
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure removeReminder ()
	
	if ( IsNew () ) then
		return;
	endif; 
	Jobs.Remove ( Ref );
	
EndProcedure 

Procedure adjustTimeOfDate ()
	
	startTime = Date ( 3999, 12, 31 );
	for each row in Tasks do
		startTime = Min ( startTime, row.TimeStart );
	enddo; 
	if ( startTime <> Date ( 3999, 12, 31 ) ) then
		Date = BegOfDay ( Date ) + ( startTime - BegOfDay ( startTime ) );
	endif; 
	
EndProcedure 

Procedure setReminderDate ()
	
	if ( Reminder = Enums.Reminder.None ) then
		return;
	endif; 
	ReminderDate = Enums.Reminder.GetDate ( Date, Reminder );
	
EndProcedure 

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	if ( not Documents.TimeEntry.Post ( env ) ) then
		Cancel = true;
		return;
	endif;
	if ( Reminder <> Enums.Reminder.None
		and CurrentSessionDate () < ReminderDate ) then
		TimeReminder.Write ( ThisObject );
	endif; 
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	deleteTimeEntriesInvoicing ();
	
EndProcedure

Procedure deleteTimeEntriesInvoicing ()
	
	record = InformationRegisters.TimeEntryInvoices.CreateRecordManager ();
	record.TimeEntry = Ref;
	record.Delete ();
	
EndProcedure 

#endif