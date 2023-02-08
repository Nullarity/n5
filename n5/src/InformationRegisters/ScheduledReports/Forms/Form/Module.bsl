&AtServer
var IsEmpty;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	IsNew = Record.SourceRecordKey.IsEmpty ();
	setSender ();
	setTomorrow ();
	if ( directly () ) then
		Cancel = true;
		return;
	endif; 
	if ( IsNew ) then
		setDate ( ThisObject );
		setUser ();
		setReceiver ();
		setSettingsAddress ();
		loadRecord ();
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|DaysCount enable Record.Periodicity = Enum.Periodicity.OtherPeriod;
	|Monday Tuesday Wednesday Thursday Friday Saturday Sunday enable Record.Periodicity = Enum.Periodicity.EveryDay;
	|FormDeleteSchedule show not IsNew
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setSender ()
	
	Sender = Cloud.Noreply ();
	
EndProcedure 

&AtServer
Procedure setTomorrow ()
	
	Tomorrow = CurrentSessionDate () + 86400;
	
EndProcedure 

&AtServer
Function directly ()
	
	interactive = IsNew and Record.Report.IsEmpty () or not Parameters.CopyingValue.IsEmpty ();
	if ( interactive ) then
		Output.SendingReportsByScheduleAddingError ();
	endif; 
	return interactive;
	
EndFunction 

&AtClientAtServerNoContext
Procedure setDate ( Form )
	
	record = Form.Record;
	tomorrow = Form.Tomorrow;
	if ( record.Date < tomorrow ) then
		record.Date = tomorrow;
	endif; 

EndProcedure 

&AtServer
Procedure setUser ()
	
	Record.User = SessionParameters.User;
	
EndProcedure 

&AtServer
Procedure setReceiver ()
	
	Record.Receiver = DF.Pick ( Record.User, "Email" );
	
EndProcedure 

&AtServer
Procedure setSettingsAddress ()
	
	SettingsAddress = Parameters.FillingValues.SettingsAddress;

EndProcedure 

&AtServer
Procedure loadRecord ()
	
	r = InformationRegisters.ScheduledReports.CreateRecordManager ();
	r.User = Record.User;
	r.Report = Record.Report;
	r.Read ();
	if ( r.Selected () ) then
		ValueToFormAttribute ( r, "Record" );
	endif; 
	
EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not Mailboxes.CheckAddresses ( Record, "Receiver", "Record" ) ) then
		Cancel = true;
	endif; 
	if ( not Mailboxes.CheckAddresses ( Record, "Copy", "Record" ) ) then
		Cancel = true;
	endif; 
	if ( not checkDate () ) then
		Cancel = true;
	endif; 
	if ( not checkWeekDays () ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtServer
Function checkDate ()
	
	if ( Record.Date <= CurrentSessionDate () ) then
		Output.ScheduleDateError ( , "Date", , "Record" );
		return false;
	endif; 
	return true;
	
EndFunction 

&AtServer
Function checkWeekDays ()
	
	if ( Record.Periodicity = Enums.Periodicity.EveryDay ) then
		if ( not ( Record.Monday or Record.Tuesday or Record.Wednesday or Record.Thursday or Record.Friday or Record.Saturday or Record.Sunday ) ) then
			Output.WeekDaySelectionError ( , "Monday", , "Record" );
			return false;
		endif; 
	endif; 
	return true;
	
EndFunction 

// *****************************************
// *********** Group Form

&AtClient
Procedure DeleteSchedule ( Command )
	
	Output.ReportScheduleRemovingConfirmation ( ThisObject );
	
EndProcedure

&AtClient
Procedure ReportScheduleRemovingConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		clean ();
		NotifyChanged ( Parameters.Key );
		Close ();
	endif; 

EndProcedure 

&AtServer
Procedure clean ()
	
	deleteScheduledJob ();
	deleteRecord ();
	
EndProcedure 

&AtServer
Procedure deleteScheduledJob ()
	
	SetPrivilegedMode ( true );
	job = Jobs.GetScheduled ( Record.RecordKey );
	if ( job <> undefined ) then
		job.Delete ();
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Procedure deleteRecord ()
	
	r = FormAttributeToValue ( "Record" );
	r.Delete ();
	
EndProcedure 

// *****************************************
// *********** Group SendingPeridicity

&AtClient
Procedure SendingPeriodicityOnChange ( Item )
	
	resetPeriodicity ();
	setDate ( ThisObject );
	Appearance.Apply ( ThisObject, "Record.Periodicity" );
	
EndProcedure

&AtClient
Procedure resetPeriodicity ()
	
	if ( Record.Periodicity <> PredefinedValue ( "Enum.Periodicity.OtherPeriod" ) ) then
		Record.DaysCount = 15;
	endif; 
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	saveSettings ( CurrentObject );
	initJob ( CurrentObject );
	
EndProcedure

&AtServer
Procedure saveSettings ( CurrentObject )
	
	if ( CurrentObject.Selected () ) then
		return;
	endif; 
	CurrentObject.Settings = new ValueStorage ( GetFromTempStorage ( SettingsAddress ), new Deflation () );
	
EndProcedure 

&AtServer
Procedure initJob ( CurrentObject )
	
	SetPrivilegedMode ( true );
	job = undefined;
	if ( ValueIsFilled ( CurrentObject.RecordKey ) ) then
		job = Jobs.GetScheduled ( Record.RecordKey );
	else
		CurrentObject.RecordKey = new UUID ();
	endif; 
	if ( job = undefined ) then
		job = ScheduledJobs.CreateScheduledJob ( Metadata.ScheduledJobs.GeneratingReports );
		job.Use = true;
		job.UserName = UserName ();
		job.Key = CurrentObject.RecordKey;
		p = new Array ();
		p.Add ( CurrentObject.RecordKey );
		job.Parameters = p;
	endif; 
	job.Schedule = getSchedule ();
	job.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Function getSchedule ()
	
	schedule = new JobSchedule ();
	if ( TesterCache.Testing () ) then
		now = CurrentDate () + 3;
		schedule.BeginDate = now;
		schedule.BeginTime = now;
	else
		sessionDate = CurrentSessionDate ();
		timeOffset = sessionDate - CurrentDate ();
		beginDate = Record.Date - timeOffset;
		schedule.BeginDate = beginDate;
		schedule.BeginTime = beginDate;
		if ( Record.Periodicity = Enums.Periodicity.EveryMonth ) then
			schedule.DaysRepeatPeriod = 1;
			schedule.Months = getMonths ();
			schedule.DayInMonth = 1;
		elsif ( Record.Periodicity = Enums.Periodicity.EveryTwoWeeks ) then
			schedule.DaysRepeatPeriod = 1;
			schedule.WeekDays = getWeekDays ();
			schedule.WeeksPeriod = 2;
		elsif ( Record.Periodicity = Enums.Periodicity.EveryWeek ) then
			schedule.DaysRepeatPeriod = 1;
			schedule.WeekDays = getWeekDays ();
			schedule.WeeksPeriod = 1;
		elsif ( Record.Periodicity = Enums.Periodicity.OtherPeriod ) then
			schedule.DaysRepeatPeriod = Record.DaysCount;
		elsif ( Record.Periodicity = Enums.Periodicity.EveryDay ) then
			schedule.DaysRepeatPeriod = 1;
			schedule.WeekDays = getWeekDays ();
		endif; 
	endif;
	return schedule;
	
EndFunction 

&AtServer
Function getMonths ()
	
	months = new Array ();
	months.Add ( 1 );
	months.Add ( 2 );
	months.Add ( 3 );
	months.Add ( 4 );
	months.Add ( 5 );
	months.Add ( 6 );
	months.Add ( 7 );
	months.Add ( 8 );
	months.Add ( 9 );
	months.Add ( 10 );
	months.Add ( 11 );
	months.Add ( 12 );
	return months;
	
EndFunction 

&AtServer
Function getWeekDays ()
	
	weekDays = new Array ();
	if ( Record.Periodicity = Enums.Periodicity.EveryTwoWeeks
		or Record.Periodicity = Enums.Periodicity.EveryWeek ) then
		weekDays.Add ( WeekDay ( Record.Date ) );
	else
		if ( Record.Monday ) then
			weekDays.Add ( 1 );
		endif; 
		if ( Record.Tuesday ) then
			weekDays.Add ( 2 );
		endif; 
		if ( Record.Wednesday ) then
			weekDays.Add ( 3 );
		endif; 
		if ( Record.Thursday ) then
			weekDays.Add ( 4 );
		endif; 
		if ( Record.Friday ) then
			weekDays.Add ( 5 );
		endif; 
		if ( Record.Saturday ) then
			weekDays.Add ( 6 );
		endif; 
		if ( Record.Sunday ) then
			weekDays.Add ( 7 );
		endif; 
	endif; 
	return weekDays;
	
EndFunction 

&AtClient
Procedure ReceiverStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	OpenForm ( "Catalog.AddressBook.ChoiceForm", new Structure ( "MultipleSelection", true ), Item );
	
EndProcedure

&AtClient
Procedure CopyStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	OpenForm ( "Catalog.AddressBook.ChoiceForm", new Structure ( "MultipleSelection", true ), Item );
	
EndProcedure
