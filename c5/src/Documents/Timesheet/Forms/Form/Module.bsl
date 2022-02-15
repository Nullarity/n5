&AtClient
var PreviousDateStart;
&AtServer
var CurrentUserHasTasks;
&AtServer
var SavedTasks;
&AtServer
var SavedMemos;
&AtServer
var SavedApprovalSequences;
&AtServer
var DayColumn;
&AtServer
var MinutesColumn;
&AtServer
var TimeEntryColumn;
&AtServer
var TimeTable;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setCanEdit ();
	arrangeColumns ();
	setStatusAndTasks ();
	setMemos ();
	setApprovalSequence ();
	setRowsFilter ();
	setReadOnlyStatus ();
	setDefaultButton ();
	setDocumentSupportsApprovalProcess ();
	calcTotals ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure setCanEdit ()
	
	CanEdit = AccessRight ( "Edit", Metadata.Documents.Timesheet );
	
EndProcedure 

&AtServer
Procedure arrangeColumns ()
	
	if ( Object.DateStart = Date ( 1, 1, 1 ) ) then
		return;
	endif; 
	daysOff = getDaysOff ();
	day = Object.DateStart;
	dayCounter = 1;
	columnPerfix = Object.TableName + "Day";
	fullMonth = ( Object.TableName = "Other" or Object.TableName = "Month" );
	while ( day <= Object.DateEnd ) do
		column = Items [ columnPerfix + dayCounter ];
		column.Title = getDayTitle ( day );
		if ( fullMonth ) then
			column.Visible = true;
		endif; 
		setColumnAppearance ( column, day, daysOff );
		day = day + 86400;
		dayCounter = dayCounter + 1;
	enddo; 
	if ( fullMonth ) then
		while ( dayCounter <= 31 ) do
			column = Items [ columnPerfix + dayCounter ];
			column.Visible = false;
			dayCounter = dayCounter + 1;
		enddo; 
	endif;
	
EndProcedure 

&AtServer
Function getDaysOff ()
	
	s = "
	|select Schedules.Day as Day
	|from InformationRegister.Schedules as Schedules
	|where Schedules.Minutes = 0
	|and Schedules.Schedule = &Schedule
	|and Schedules.Day between &DateStart and &DateEnd
	|";
	q = new Query ( s );
	q.SetParameter ( "Schedule", Object.Schedule );
	q.SetParameter ( "DateStart", Object.DateStart );
	q.SetParameter ( "DateEnd", Object.DateEnd );
	yearDateStart = Year ( Object.DateStart );
	yearDateEnd = Year ( Object.DateEnd );
	years = new Array ();
	years.Add ( yearDateStart );
	if ( yearDateStart <> yearDateEnd ) then
		years.Add ( yearDateEnd );
	endif; 
	q.SetParameter ( "Years", years );
	return q.Execute ().Unload ().UnloadColumn ( "Day" );
	
EndFunction 

&AtServer
Function getDayTitle ( Day )
	
	return Format ( Day, "DF='dd ddd'" ); 
	
EndFunction 

&AtServer
Procedure setColumnAppearance ( Column, Day, DaysOff )
	
	if ( DaysOff.Find ( Day ) = undefined ) then
		backColor = new Color ();
	else
		backColor = StyleColors.ToolTipBackColor;
	endif; 
	Column.TitleBackColor = backColor;
	Column.BackColor = backColor;
	Column.FooterBackColor = backColor;
	
EndProcedure

&AtServer
Procedure setStatusAndTasks ()
	
	Status = getStatus ();
	if ( approvalStatus ( ThisObject ) ) then
		setTasks ();
	else
		resetRoutePoint ();
		resetCurrentUserHasTasks ();
	endif; 
	
EndProcedure 

&AtServer
Function getStatus ()
	
	currentStatus = InformationRegisters.TimesheetStatuses.Get ( new Structure ( "Timesheet", Object.Ref ) ).Status;
	if ( currentStatus.IsEmpty () ) then
		return Enums.TimesheetStatuses.None;
	else
		return currentStatus;
	endif; 
	
EndFunction

&AtClientAtServerNoContext
Function approvalStatus ( Form )
	
	return Form.Status = PredefinedValue ( "Enum.TimesheetStatuses.Approval" );
	
EndFunction 

&AtServer
Procedure setTasks ()
	
	table = getTasks ();
	setRoutePoint ( table );
	setCurrentUserHasTasks ( table );
	applyTaskToTime ( table );
	
EndProcedure 

&AtServer
Function getTasks ()
	
	s = "
	|select Tasks.Ref as Task, Tasks.BusinessProcess as BP,
	|	case when Tasks.RoutePoint = value ( BusinessProcess.TimesheetApproval.RoutePoint.Approval ) then ""Approval""
	|		when Tasks.RoutePoint = value ( BusinessProcess.TimesheetApproval.RoutePoint.Rework ) then ""Rework""
	|	end as RoutePoint
	|from Task.Task.TasksByExecutive ( ,
	|	not Executed
	|	and BusinessProcess refs BusinessProcess.TimesheetApproval
	|	and cast ( BusinessProcess as BusinessProcess.TimesheetApproval ).Timesheet = &Timesheet ) as Tasks
	|";
	q = new Query ( s );
	q.SetParameter ( "Timesheet", Object.Ref );
	return q.Execute ().Unload ();
	
EndFunction

&AtServer
Procedure setRoutePoint ( Tasks )
	
	if ( Tasks.Find ( "Approval", "RoutePoint" ) <> undefined ) then
		RoutePoint = "Approval";
	elsif ( Tasks.Find ( "Rework", "RoutePoint" ) <> undefined ) then
		RoutePoint = "Rework";
	else
		RoutePoint = "";
	endif; 
	
EndProcedure 

&AtServer
Procedure setCurrentUserHasTasks ( Tasks )
	
	CurrentUserHasTasks = Tasks.Count () > 0;
	
EndProcedure 

&AtServer
Procedure applyTaskToTime ( Tasks )
	
	searchStruct = new Structure ( "RoutePoint, BP", RoutePoint );
	table = getTable ( Object );
	for each row in table do
		searchStruct.BP = row.TimesheetApproval;
		foundRows = Tasks.FindRows ( searchStruct );
		if ( foundRows.Count () = 0 ) then
			row.Task = undefined;
		else
			row.Task = foundRows [ 0 ].Task;
		endif; 
	enddo; 
	
EndProcedure 

&AtClientAtServerNoContext
Function getTable ( Object )
	
	return Object [ Object.TableName ];
	
EndFunction 

&AtServer
Procedure resetRoutePoint ()
	
	RoutePoint = "";
	
EndProcedure 

&AtServer
Procedure resetCurrentUserHasTasks ()
	
	CurrentUserHasTasks = false;
	
EndProcedure 

&AtServer
Procedure setReadOnlyStatus ()
	
	ReadOnlyStatus = not CanEdit
	or ( Status = Enums.TimesheetStatuses.Finished )
	or ( approvalStatus ( ThisObject ) and not CurrentUserHasTasks );
	
EndProcedure 

&AtServer
Procedure setDefaultButton ()
	
	if ( Status = Enums.TimesheetStatuses.Approval ) then
		if ( RoutePoint = "Approval" ) then
			Items.FormApplyResolutions.DefaultButton = true;
		elsif ( RoutePoint = "Rework" ) then
			Items.FormSendForApprovalAgain.DefaultButton = true;
		endif; 
	elsif ( Status = Enums.TimesheetStatuses.None ) then
		Items.FormSendForApproval.DefaultButton = true;
	endif; 
	
EndProcedure 

&AtServer
Procedure setMemos ()
	
	if ( Status = Enums.TimesheetStatuses.None ) then
		return;
	endif; 
	table = getTable ( Object );
	memosTable = getMemosTable ();
	searchStruct = new Structure ( "TimesheetApproval" );
	for each memosRow in memosTable do
		searchStruct.TimesheetApproval = memosRow.TimesheetApproval;
		foundRows = table.FindRows ( searchStruct );
		for each row in foundRows do
			row.Memo = memosRow.Memo;
		enddo; 
	enddo; 
	
EndProcedure 

&AtServer
Function getMemosTable ()
	
	s = "
	|select allowed max ( TimesheetResolutions.Date ) as Date, TimesheetResolutions.TimesheetApproval as TimesheetApproval
	|into LastMemos
	|from InformationRegister.TimesheetResolutions as TimesheetResolutions
	|where TimesheetResolutions.TimesheetApproval in ( select distinct TimesheetApproval from Document.Timesheet." + Object.TableName + " where Ref = &Ref )
	|group by TimesheetResolutions.TimesheetApproval
	|;
	|select allowed Time.TimesheetApproval as TimesheetApproval, TimesheetResolutions.User.Description + "": "" + TimesheetResolutions.Memo as Memo
	|from Document.Timesheet." + Object.TableName + " as Time
	|	join InformationRegister.TimesheetResolutions as TimesheetResolutions
	|	on Time.TimesheetApproval = TimesheetResolutions.TimesheetApproval
	|	join LastMemos as LastMemos
	|	on LastMemos.TimesheetApproval = TimesheetResolutions.TimesheetApproval
	|	and LastMemos.Date = TimesheetResolutions.Date
	|where Time.Ref = &Ref
	|and TimesheetResolutions.Memo <> """"
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure setApprovalSequence ()
	
	if ( Status = Enums.TimesheetStatuses.None ) then
		return;
	endif; 
	table = getTable ( Object );
	Documents.Timesheet.FillApprovalSequence ( Object.Ref, table );
	
EndProcedure 

&AtServer
Procedure setRowsFilter ()
	
	projects = getAllowedProjects ();
	table = getTable ( Object );
	filterByTasks = CurrentUserHasTasks and approvalStatus ( ThisObject );
	for each row in table do
		if ( projects [ row.Project ] = undefined ) then
			row.Allowed = false;
		elsif ( filterByTasks ) then
			row.Allowed = not row.Task.IsEmpty ();
		else
			row.Allowed = true;
		endif; 
	enddo; 
	getFormTable ( ThisObject ).RowFilter = new FixedStructure ( "Allowed", true );
	
EndProcedure 

&AtServer
Function getAllowedProjects ()
	
	s = "
	|select allowed Projects.Ref as Project
	|from Catalog.Projects as Projects
	|where Projects.Ref in ( &Projects )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Projects", Object [ Object.TableName ].Unload ( , "Project" ).UnloadColumn ( "Project" ) );
	table = q.Execute ().Unload ();
	projects = new Map ();
	for each row in table do
		projects [ row.Project ] = true;
	enddo; 
	return projects;
	
EndFunction

&AtClientAtServerNoContext
Function getFormTable ( Form )
	
	return Form.Items [ Form.Object.TableName ];
	
EndFunction 

&AtServer
Procedure setDocumentSupportsApprovalProcess ()
	
	DocumentSupportsApprovalProcess = true;
	if ( Status = Enums.TimesheetStatuses.Finished ) then
		table = getTable ( Object );
		emptyResolution = Enums.Resolutions.EmptyRef ();
		for each row in table do
			if ( row.Resolution <> emptyResolution ) then
				return;
			endif; 
		enddo; 
		DocumentSupportsApprovalProcess = false;
	endif; 

EndProcedure 

&AtClientAtServerNoContext
Procedure calcTotals ( Form )
	
	object = Form.Object;
	if ( object.Employee.IsEmpty () ) then
		return;
	endif; 
	table = getTable ( object );
	allowedOnly = new Structure ( "Allowed", true );
	for i = 1 to object.TimesheetDays do
		totalByColumn = TimesheetForm.TotalByColumn ( table.FindRows ( allowedOnly ), "Minutes" + i );
		Form [ "TotalDay" + i ] = Conversion.MinutesToDuration ( totalByColumn );
	enddo; 
	total = TimesheetForm.GetTotal ( table.FindRows ( allowedOnly ) );
	Form.TotalTotal = Conversion.MinutesToDuration ( total );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		if ( isCopy () ) then
			Cancel = true;
			return;
		endif; 
		setCanEdit ();
		TimesheetForm.SetCreator ( ThisObject );
		setSchedule ();
		extractFields ();
		setPeriod ();
		adjustDays ();
		arrangeColumns ();
		loadEntries ();
		calcTotals ( ThisObject );
		setStatusByDefault ();
		resetRoutePoint ();
		setDefaultButton ();
	endif; 
	setTimeWasModified ( ThisObject, false );
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|DateStart lock Object.TimesheetPeriod <> Enum.TimesheetPeriods.Other;
	|Employee lock ( ReadOnlyStatus or filled ( Object.Ref ) );
	|OneWeekPage show
	|( Object.TimesheetPeriod = Enum.TimesheetPeriods.Week
	|	or ( empty ( Object.Ref ) and empty ( Object.TimesheetPeriod ) ) );
	|OtherPage show Object.TimesheetPeriod = Enum.TimesheetPeriods.Other;
	|MonthPage show Object.TimesheetPeriod = Enum.TimesheetPeriods.Month;
	|TwoWeeksPage show Object.TimesheetPeriod = Enum.TimesheetPeriods.TwoWeeks;
	|OneWeek enable
	|filled ( Object.Employee )
	|and filled ( Object.DateStart )
	|and filled ( Object.DateEnd )
	|and Object.TimesheetPeriod = Enum.TimesheetPeriods.Week;
	|TwoWeeks enable
	|filled ( Object.Employee )
	|and filled ( Object.DateStart )
	|and filled ( Object.DateEnd )
	|and Object.TimesheetPeriod = Enum.TimesheetPeriods.TwoWeeks;
	|Month enable
	|filled ( Object.Employee )
	|and filled ( Object.DateStart )
	|and filled ( Object.DateEnd )
	|and Object.TimesheetPeriod = Enum.TimesheetPeriods.Month;
	|Other enable
	|filled ( Object.Employee )
	|and filled ( Object.DateStart )
	|and filled ( Object.DateEnd )
	|and Object.TimesheetPeriod = Enum.TimesheetPeriods.Other;
	|OneWeekApprovalSequence TwoWeeksApprovalSequence MonthApprovalSequence OtherApprovalSequence show Status <> Enum.TimesheetStatuses.None and DocumentSupportsApprovalProcess;
	|FormSendForApproval OneWeekAdd OneWeekCopy OneWeekDelete OneWeekChange TwoWeeksAdd MonthAdd OtherAdd TwoWeeksCopy MonthCopy OtherCopy TwoWeeksDelete MonthDelete OtherDelete TwoWeeksChange MonthChange OtherChange show CanEdit and Status = Enum.TimesheetStatuses.None;
	|FormApplyResolutions FormApproveTimesheet show
	|CanEdit
	|and Status = Enum.TimesheetStatuses.Approval
	|and RoutePoint = BusinessProcess.TimesheetApproval.RoutePoint.Approval;
	|FormSendForApprovalAgain show
	|CanEdit
	|and Status = Enum.TimesheetStatuses.Approval
	|and RoutePoint = BusinessProcess.TimesheetApproval.RoutePoint.Rework;
	|FormWrite show ReadOnlyStatus <> true;
	|OneWeek TwoWeeks Month Other Memo lock ReadOnlyStatus;
	|Date lock ( ReadOnlyStatus or Status <> Enum.TimesheetStatuses.None );
	|OneWeekResolution TwoWeeksResolution MonthResolution OtherResolution lock RoutePoint <> BusinessProcess.TimesheetApproval.RoutePoint.Approval;
	|OneWeekResolution TwoWeeksResolution MonthResolution OtherResolution show Status <> Enum.TimesheetStatuses.None and DocumentSupportsApprovalProcess;
	|OneWeekMemo TwoWeeksMemo MonthMemo OtherMemo show Status <> Enum.TimesheetStatuses.None and DocumentSupportsApprovalProcess
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Function isCopy ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		Output.CannotCopyTimesheet ();
		return true;
	endif; 
	return false;
	
EndFunction 

&AtServer
Procedure setSchedule ()
	
	SetPrivilegedMode ( true );
	date = ? ( Object.DateEnd = Date ( 1, 1, 1 ), undefined, Object.DateEnd );
	schedule = InformationRegisters.Personnel.GetLast ( date, new Structure ( "Employee", Object.Employee ) ).Schedule;
	Object.Schedule = ? ( schedule.IsEmpty (), Application.Schedule (), schedule );

EndProcedure 

&AtServer
Procedure extractFields ()
	
	if ( Object.Schedule.IsEmpty () ) then
		return;
	endif; 
	s = "
	|select Schedules.TimesheetPeriod as TimesheetPeriod,
	|	case when Schedules.WeekStart = value ( Enum.Week.Monday ) then 1
	|		when Schedules.WeekStart = value ( Enum.Week.Tuesday ) then 2
	|		when Schedules.WeekStart = value ( Enum.Week.Wednesday ) then 3
	|		when Schedules.WeekStart = value ( Enum.Week.Thursday ) then 4
	|		when Schedules.WeekStart = value ( Enum.Week.Friday ) then 5
	|		when Schedules.WeekStart = value ( Enum.Week.Saturday ) then 6
	|		else 7
	|	end as WeekStart,
	|	case when Schedules.TimesheetPeriod = value ( Enum.TimesheetPeriods.Week ) then ""OneWeek""
	|		when Schedules.TimesheetPeriod = value ( Enum.TimesheetPeriods.TwoWeeks ) then ""TwoWeeks""
	|		when Schedules.TimesheetPeriod = value ( Enum.TimesheetPeriods.Month ) then ""Month""
	|		when Schedules.TimesheetPeriod = value ( Enum.TimesheetPeriods.Other ) then ""Other""
	|	end as TableName,
	|	case when Schedules.TimesheetPeriod = value ( Enum.TimesheetPeriods.Week ) then 7
	|		when Schedules.TimesheetPeriod = value ( Enum.TimesheetPeriods.TwoWeeks ) then 14
	|		when Schedules.TimesheetPeriod = value ( Enum.TimesheetPeriods.Month ) then 0
	|		when Schedules.TimesheetPeriod = value ( Enum.TimesheetPeriods.Other ) then Schedules.TimesheetDays
	|	end as TimesheetDays
	|from Catalog.Schedules as Schedules
	|where Schedules.Ref = &Schedule
	|";
	q = new Query ( s );
	q.SetParameter ( "Schedule", Object.Schedule );
	data = q.Execute ().Unload () [ 0 ];
	FillPropertyValues ( Object, data );
	
EndProcedure 

&AtServer
Procedure setPeriod ()
	
	if ( Object.Schedule.IsEmpty () ) then
		return;
	endif; 
	Object.DateStart = getDateStart ();
	Object.DateEnd = getDateEnd ();
	
EndProcedure 

&AtServer
Function getDateStart ()
	
	nextDateStart = getNextDateStart ();
	if ( nextDateStart = undefined ) then
		currendDate = CurrentDate ();
		if ( Object.TableName = "Month" ) then
			nextDateStart = BegOfMonth ( currendDate );
		else
			currentDay = WeekDay ( currendDate );
			nextDateStart = currendDate + ( Object.WeekStart - currentDay ) * 86400;
		endif; 
	endif; 
	return nextDateStart;
	
EndFunction 

&AtServer
Function getNextDateStart ()
	
	s = "
	|select allowed top 1 dateadd ( Timesheet.DateEnd, day, 1 ) as DateStart
	|from Document.Timesheet as Timesheet
	|where Timesheet.Employee = &Employee
	|and not Timesheet.DeletionMark
	|order by Timesheet.DateEnd desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Employee", Object.Employee );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].DateStart );
	
EndFunction 

&AtServer
Function getDateEnd ()
	
	if ( Object.TableName = "Month" ) then
		return BegOfDay ( EndOfMonth ( Object.DateStart ) );
	elsif ( Object.TableName = "Other" ) then
		return Object.DateStart + 86400 * ( Object.TimesheetDays - 1 );
	elsif ( Object.TableName = "TwoWeeks" ) then
		return Object.DateStart + 86400 * 13;
	elsif ( Object.TableName = "OneWeek" ) then
		return Object.DateStart + 86400 * 6;
	endif; 
	
EndFunction 

&AtServer
Procedure adjustDays ()
	
	if ( Object.TableName = "Month" ) then
		Object.TimesheetDays = Day ( Object.DateEnd );
	endif; 
	
EndProcedure 

&AtServer
Procedure loadEntries ()
	
	if ( Object.Employee.IsEmpty () ) then
		return;
	endif; 
	table = getEntries ();
	updateTime ( table );

EndProcedure 

&AtServer
Function getEntries ()
	
	s = "
	|select Entries.Ref as Ref, Entries.Customer as Customer, Entries.Project,
	|	1 + datediff ( &DateStart, Entries.Date, day ) as Day,
	|	sum ( case when Time.TimeType = value ( Enum.Time.Billable ) then Time.Minutes else 0 end ) as Billable,
	|	sum ( case when Time.TimeType = value ( Enum.Time.NonBillable ) then Time.Minutes else 0 end ) as NonBillable,
	|	sum ( case when Time.TimeType = value ( Enum.Time.Vacation ) then Time.Minutes else 0 end ) as Vacation,
	|	sum ( case when Time.TimeType = value ( Enum.Time.ExtendedVacation ) then Time.Minutes else 0 end ) as ExtendedVacation,
	|	sum ( case when Time.TimeType = value ( Enum.Time.Sickness ) then Time.Minutes else 0 end ) as Sickness,
	|	sum ( case when Time.TimeType = value ( Enum.Time.Holiday ) then Time.Minutes else 0 end ) as Holiday,
	|	sum ( case when Time.TimeType = value ( Enum.Time.Banked ) then Time.Minutes else 0 end ) as Banked,
	|	sum ( case when Time.TimeType = value ( Enum.Time.BankedUse ) then Time.Minutes else 0 end ) as BankedUse,
	|	sum ( case when Time.TimeType = value ( Enum.Time.Overtime ) then Time.Minutes else 0 end ) as Overtime,
	|	sum ( case when Time.TimeType = value ( Enum.Time.DayOff ) then Time.Minutes else 0 end ) as DayOff,
	|	sum ( case when Time.TimeType = value ( Enum.Time.Evening ) then Time.Minutes else 0 end ) as Evening,
	|	sum ( case when Time.TimeType = value ( Enum.Time.Night ) then Time.Minutes else 0 end ) as Night
	|from Document.TimeEntry as Entries
	|	//
	|	// Tasks
	|	//
	|	join Document.TimeEntry.Tasks as Time
	|	on Time.Ref = Entries.Ref
	|where Entries.Date between &DateStart and &DateEnd
	|and Entries.Employee = &Employee
	|and not Entries.DeletionMark
	|group by Entries.Ref, Entries.Customer, Entries.Project, 1 + datediff ( &DateStart, Entries.Date, day )
	|order by Entries.Customer, Entries.Project
	|";
	q = new Query ( s );
	q.SetParameter ( "DateStart", Object.DateStart );
	q.SetParameter ( "DateEnd", EndOfDay ( Object.DateEnd ) );
	q.SetParameter ( "Employee", Object.Employee );
	SetPrivilegedMode ( true );
	table = q.Execute ().Unload ();
	SetPrivilegedMode ( false );
	return table;
	
EndFunction

&AtServer
Procedure updateTime ( Table )
	
	p = new Structure ( "Customer, Project, Day, Minutes, TimeType" );
	for each row in Table do
		FillPropertyValues ( p, row );
		for i = 1 to 12 do
			if ( i = 1 ) then
				p.TimeType = Enums.Time.Billable;
				p.Minutes = row.Billable;
			elsif ( i = 2 ) then
				p.TimeType = Enums.Time.NonBillable;
				p.Minutes = row.NonBillable;
			elsif ( i = 3 ) then
				p.TimeType = Enums.Time.Holiday;
				p.Minutes = row.Holiday;
			elsif ( i = 4 ) then
				p.TimeType = Enums.Time.Vacation;
				p.Minutes = row.Vacation;
			elsif ( i = 5 ) then
				p.TimeType = Enums.Time.ExtendedVacation;
				p.Minutes = row.ExtendedVacation;
			elsif ( i = 6 ) then
				p.TimeType = Enums.Time.Sickness;
				p.Minutes = row.Sickness;
			elsif ( i = 7 ) then
				p.TimeType = Enums.Time.Banked;
				p.Minutes = row.Banked;
			elsif ( i = 8 ) then
				p.TimeType = Enums.Time.BankedUse;
				p.Minutes = row.BankedUse;
			elsif ( i = 9 ) then
				p.TimeType = Enums.Time.Overtime;
				p.Minutes = row.Overtime;
			elsif ( i = 10 ) then
				p.TimeType = Enums.Time.Evening;
				p.Minutes = row.Evening;
			elsif ( i = 11 ) then
				p.TimeType = Enums.Time.Night;
				p.Minutes = row.Night;
			elsif ( i = 12 ) then
				p.TimeType = Enums.Time.DayOff;
				p.Minutes = row.DayOff;
			endif; 
			timesheetRow = getTimesheetRow ( ThisObject, p );
			if ( timesheetRow <> undefined ) then
				fillTimesheetRow ( p, timesheetRow, row.Ref );
			endif; 
		enddo; 
	enddo;
	calcTotal ( ThisObject );
	
EndProcedure 

&AtClientAtServerNoContext
Function getTimesheetRow ( Form, Params )
	
	object = Form.Object;
	searchStruct = new Structure ( "Project, TimeType", Params.Project, Params.TimeType );
	table = getTable ( object );
	foundRows = table.FindRows ( searchStruct );
	billableTimeType = PredefinedValue ( "Enum.Time.Billable" );
	nonBillableTimeType = PredefinedValue ( "Enum.Time.NonBillable" );
	if ( foundRows.Count () = 0 ) then
		if ( Params.Minutes = 0 ) then
			return undefined;
		endif; 
		searchStruct.TimeType = ? ( Params.TimeType = nonBillableTimeType, BillableTimeType, nonBillableTimeType );
		foundRows = table.FindRows ( searchStruct );
		if ( foundRows.Count () = 0 ) then
			timesheetRow = table.Add ();
		else
			foundIndex = table.IndexOf ( foundRows [ 0 ] );
			lastIndex = table.Count () - 1;
			if ( searchStruct.TimeType = billableTimeType ) then
				if ( foundIndex = lastIndex ) then
					timesheetRow = table.Add ();
				else
					timesheetRow = table.Insert ( foundIndex + 1 );
				endif; 
			else
				timesheetRow = table.Insert ( foundIndex );
			endif; 
		endif; 
		FillPropertyValues ( timesheetRow, Params );
		timesheetRow.Allowed = true;
		timesheetRow.ExistTimeEntries = true;
	else
		timesheetRow = foundRows [ 0 ];
	endif; 
	return timesheetRow;
	
EndFunction 

&AtServer
Procedure fillTimesheetRow ( Params, TimesheetRow, TimeEntry )
	
	TimesheetRow [ "Minutes" + Params.Day ] = Params.Minutes;
	TimesheetRow [ "Day" + Params.Day ] = Conversion.MinutesToDuration ( Params.Minutes );
	TimesheetRow [ "TimeEntry" + Params.Day ] = TimeEntry;
	calcTotalByRow ( ThisObject, TimesheetRow );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcTotalByRow ( Form, Row )
	
	object = Form.Object;
	total = 0;
	totalByTimesheet = 0;
	for i = 1 to object.TimesheetDays do
		minutes = Row [ "Minutes" + i ];
		total = total + minutes;
		if ( Row [ "TimeEntry" + i ].IsEmpty () ) then
			totalByTimesheet = totalByTimesheet + minutes;
		endif; 
	enddo; 
	Row.Total = Conversion.MinutesToDuration ( total );
	Row.TotalByTimesheet = Conversion.MinutesToDuration ( totalByTimesheet );
	Row.TotalMinutes = total;
	Row.TotalMinutesByTimesheet = totalByTimesheet;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcTotal ( Form )
	
	object = Form.Object;
	table = getTable ( object );
	minutes = TimesheetForm.GetTotal ( table );
	object.Minutes = minutes;
	object.Duration = Conversion.MinutesToDuration ( minutes );
	
EndProcedure 

&AtServer
Procedure setStatusByDefault ()
	
	Status = Enums.TimesheetStatuses.None;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setTimeWasModified ( Form, Flag )
	
	Form.TimeWasModified = Flag;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	loadTableToClient ();
	
EndProcedure

&AtClient
Procedure loadTableToClient ()
	
	if ( Object.TableName = "" ) then
		return;
	endif; 
	count = Object [ Object.TableName ].Count ();
	i = 0;
	while ( i < count ) do
		// Enforce system to download all records
		//@skip-warning
		row = Object [ Object.TableName ].Get ( i );
		i = i + 1;
	enddo; 
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not checkResolutions ( WriteParameters ) ) then
		Cancel = true;
		return;
	endif; 
	setDocumentDate ( CurrentObject );
	removeEmptyRows ( CurrentObject );
	if ( existsDoubleRow ( CurrentObject ) ) then
		Cancel = true;
		return;
	endif; 
	writeTotals ( CurrentObject );
	saveTasks ();
	saveApprovalDynamicColumns ();
	setProperties ( CurrentObject, WriteParameters );

EndProcedure

&AtServer
Function checkResolutions ( WriteParameters )
	
	if ( not isCommand ( "ApplyResolutions", WriteParameters ) ) then
		return true;
	endif;
	error = false;
	msg = new Structure ( "Field", Output.Resolution () );
	table = getTable ( Object );
	for each row in table do
		if ( row.Allowed and row.Resolution.IsEmpty () ) then
			Output.FieldIsEmpty ( msg, Output.Row ( Object.TableName, row.LineNumber, "Resolution" ) );
			error = true;
		endif; 
	enddo; 
	return not error;
	
EndFunction

&AtClientAtServerNoContext
Function isCommand ( CommandName, WriteParameters )
	
	return WriteParameters.Property ( "Command" ) and WriteParameters.Command = CommandName;
	
EndFunction 

&AtServer
Procedure setDocumentDate ( CurrentObject )
	
	CurrentObject.Date = CurrentObject.DateEnd;
	
EndProcedure 

&AtServer
Procedure removeEmptyRows ( CurrentObject )
	
	approvalsToRemove = new Map ();
	currentObjectTable = getTable ( CurrentObject );
	table = getTable ( Object );
	index = currentObjectTable.Count ();
	while ( index > 0 ) do
		index = index - 1;
		row = currentObjectTable [ index ];
		if ( isEmpty ( row ) ) then
			if ( approvalStatus ( ThisObject ) ) then
				ApprovalsToRemove [ row.TimesheetApproval ] = true;
			endif; 
			currentObjectTable.Delete ( index );
			table.Delete ( index );
		endif; 
	enddo; 
	calcTotal ( ThisObject );
	if ( approvalsToRemove.Count () > 0 ) then
		removeUnusedApprovals ( CurrentObject, approvalsToRemove );
	endif; 
	
EndProcedure 

&AtServer
Function isEmpty ( Row )
	
	if ( row.Total <> 0 ) then
		return false;
	endif; 
	for i = 1 to Object.TimesheetDays do
		if ( Row [ "Minutes" + i ] <> 0 ) then
			return false;
		endif; 
	enddo; 
	return true;

EndFunction 

&AtServer
Procedure removeUnusedApprovals ( CurrentObject, ApprovalsToRemove )
	
	approvals = getRemovingApprovals ( CurrentObject, ApprovalsToRemove );
	removeApprovalsAndTasks ( approvals );
	
EndProcedure 

&AtServer
Function getRemovingApprovals ( CurrentObject, ApprovalsToRemove )
	
	table = getTable ( CurrentObject );
	approvalsArray = new Array ();
	for each item in ApprovalsToRemove do
		foundRow = table.Find ( item.Key, "TimesheetApproval" );
		if ( foundRow = undefined ) then
			approvalsArray.Add ( item.Key );
		endif; 
	enddo; 
	return approvalsArray;
	
EndFunction 

&AtServer
Procedure removeApprovalsAndTasks ( Approvals )
	
	SetPrivilegedMode ( true );
	table = getApprovalsTasks ( Approvals );
	for each row in table do
		obj = row.Task.GetObject ();
		obj.Delete ();
	enddo; 
	for each process in Approvals do
		obj = process.GetObject ();
		obj.Delete ();
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Function getApprovalsTasks ( Approvals )
	
	s = "
	|select Tasks.Ref as Task
	|from Task.Task as Tasks
	|where Tasks.BusinessProcess in ( &Approvals )
	|";
	q = new Query ( s );
	q.SetParameter ( "Approvals", Approvals );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Function existsDoubleRow ( CurrentObject )
	
	doubles = Collections.GetDoubles ( getTable ( CurrentObject ), "TimeType, Customer, Project" );
	error = false;
	if ( doubles.Count () > 0 ) then
		error = true;
		for each row in doubles do
			rowPath = Output.Row ( CurrentObject.TableName, row.LineNumber, "Customer" );
			Output.DoubleTimesheetRow ( , rowPath );
		enddo; 
	endif; 
	return error;
	
EndFunction 

&AtServer
Procedure writeTotals ( CurrentObject )
	
	table = prepareTotals ( CurrentObject );
	totals = CurrentObject.Totals;
	totals.Clear ();
	for each row in table do
		totalRow = totals.Add ();
		totalRow.Customer = row.Customer;
		totalRow.Project = row.Project;
		totalRow.Total = row.TotalMinutes;
		totalRow.Banked = row.BankedPlus - row.BankedMinus;
	enddo; 
	
EndProcedure 

&AtServer
Function prepareTotals ( CurrentObject )
	
	table = getTable ( CurrentObject ).Unload ( , "Customer, Project, TimeType, TotalMinutes" );
	numberType = Metadata.Documents.Timesheet.TabularSections.OneWeek.Attributes.TotalMinutes.Type;
	table.Columns.Add ( "BankedPlus", numberType );
	table.Columns.Add ( "BankedMinus", numberType );
	for each row in table do
		type = row.TimeType;
		if ( type = Enums.Time.Evening
			or type = Enums.Time.Night ) then
			row.TotalMinutes = 0;
			continue;
		endif;
		time = row.TotalMinutes;
		if ( type = Enums.Time.Banked ) then
			row.TotalMinutes = 0;
			row.BankedPlus = time;
		elsif ( type = Enums.Time.BankedUse ) then
			row.BankedMinus = time;
		endif; 
	enddo; 
	table.GroupBy ( "Customer, Project", "TotalMinutes, BankedPlus, BankedMinus" );
	return table;
	
EndFunction 

&AtServer
Procedure saveTasks ()
	
	SavedTasks = new Map ();
	table = getTable ( Object );
	for each row in table do
		SavedTasks [ row.LineNumber ] = new Structure ( "Task, Allowed", row.Task, row.Allowed );
	enddo; 
	
EndProcedure 

&AtServer
Procedure saveApprovalDynamicColumns ()
	
	if ( Status = Enums.TimesheetStatuses.None ) then
		SavedMemos = undefined;
		SavedApprovalSequences = undefined;
	else
		SavedMemos = new Map ();
		SavedApprovalSequences = new Map ();
		table = getTable ( Object );
		for each row in table do
			SavedMemos [ row.TimesheetApproval ] = row.Memo;
			SavedApprovalSequences [ row.TimesheetApproval ] = row.ApprovalSequence;
		enddo; 
	endif; 
	
EndProcedure 

&AtServer
Procedure setProperties ( CurrentObject, WriteParameters )
	
	if ( WriteParameters.Property ( "Command" ) ) then
		CurrentObject.AdditionalProperties.Insert ( "Command", WriteParameters.Command );
	endif; 
	CurrentObject.AdditionalProperties.Insert ( "TimeWasModified", TimeWasModified );
	if ( isCommand ( "ApplyResolutions", WriteParameters )
		or isCommand ( "SendForApprovalAgain", WriteParameters )
		or isCommand ( "ApproveTimesheet", WriteParameters ) ) then
		CurrentObject.AdditionalProperties.Insert ( "Tasks", getAllowedTasks () );
	endif; 
	if ( isCommand ( "ApplyResolutions", WriteParameters )
		or isCommand ( "ApproveTimesheet", WriteParameters ) ) then
		CurrentObject.AdditionalProperties.Insert ( "Resolutions", getAllowedResolutions () );
	endif; 
	
EndProcedure 

&AtServer
Function getAllowedTasks ()

	allowedTasks = new Array ();
	storedTasks = new Map ();
	table = getTable ( Object );
	for each row in table do
		if ( not row.Allowed ) then
			continue;
		elsif ( row.Task.IsEmpty () ) then
			continue;
		elsif ( storedTasks [ row.Task ] <> undefined ) then
			continue;
		endif; 
		allowedTasks.Add ( row.Task );
		storedTasks [ row.Task ] = true;
	enddo; 
	return allowedTasks;
	
EndFunction

&AtServer
Function getAllowedResolutions ()
	
	resolutions = new Map ();
	table = getTable ( Object );
	for each row in table do
		if ( not row.Allowed ) then
			continue;
		endif;
		resolutions [ row.TimesheetApproval ] = row.Resolution;
	enddo; 
	return resolutions;
	
EndFunction 

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( isCommand ( "SendForApproval", WriteParameters )
		or isCommand ( "ApplyResolutions", WriteParameters )
		or isCommand ( "SendForApprovalAgain", WriteParameters )
		or isCommand ( "ApproveTimesheet", WriteParameters ) ) then
		Notify ( "RefreshTimesheetsApproval" );
		Close ();
	endif; 
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )

	if ( not isCommand ( "SendForApproval", WriteParameters ) ) then
		restoreTasks ();
	endif; 
	restoreApprovalDynamicColumns ();
	if ( WriteParameters.Property ( "Command" ) ) then
		sendEmails ( WriteParameters );
	endif; 
	setTimeWasModified ( ThisObject, false );
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

&AtServer
Procedure restoreTasks ()
	
	table = getTable ( Object );
	for each row in table do
		FillPropertyValues ( row, SavedTasks [ row.LineNumber ] );
	enddo; 
	
EndProcedure 

&AtServer
Procedure restoreApprovalDynamicColumns ()
	
	if ( SavedMemos = undefined ) then
		return;
	endif; 
	table = getTable ( Object );
	for each row in table do
		row.Memo = SavedMemos [ row.TimesheetApproval ];
		row.ApprovalSequence = SavedApprovalSequences [ row.TimesheetApproval ];
	enddo; 
	
EndProcedure 

&AtServer
Procedure sendEmails ( WriteParameters )
	
	SetPrivilegedMode ( true );
	data = getApprovalReceivers ( WriteParameters );
	sendApprovalOrReworkEmails ( data );
	if ( isCommand ( "ApplyResolutions", WriteParameters )
		or isCommand ( "ApproveTimesheet", WriteParameters ) ) then
		sendRejectionOrCompletionEmails ( data, WriteParameters );
	endif;
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Function getApprovalReceivers ( WriteParameters )
	
	env = new Structure ();
	SQL.Init ( env );
	sqlApprovalReceivers ( env, WriteParameters );
	env.Q.SetParameter ( "Timesheet", Object.Ref );
	env.Q.SetParameter ( "Creator", Object.Creator );
	env.Q.SetParameter ( "Approvals", getApprovals () );
	SQL.Perform ( env );
	return env;
	
EndFunction 

&AtServer
Procedure sqlApprovalReceivers ( Env, WriteParameters )
	
	s = "
	|// #ApproveOrReworkTime
	|select distinct UserSettings.Ref as UserSettings, UserSettings.Owner.Email as Email,
	|	case when Tasks.RoutePoint = value ( BusinessProcess.TimesheetApproval.RoutePoint.Approval ) then ""SendForApproval""
	|		when Tasks.RoutePoint = value ( BusinessProcess.TimesheetApproval.RoutePoint.Rework ) then ""SendToRework""
	|	end as Action
	|from Catalog.UserSettings as UserSettings
	|	//
	|	// Tasks
	|	//
	|	join Task.Task as Tasks
	|	on not Tasks.Executed
	|	and Tasks.User = UserSettings.Owner
	|	join BusinessProcess.TimesheetApproval as TimesheetApprovals
	|	on TimesheetApprovals.Ref = Tasks.BusinessProcess
	|where UserSettings.TimesheetNotifications";
	if ( isCommand ( "SendForApproval", WriteParameters ) ) then
		s = s + "
		|and TimesheetApprovals.Timesheet = &Timesheet
		|and Tasks.RoutePoint = value ( BusinessProcess.TimesheetApproval.RoutePoint.Approval )
		|";
	elsif ( isCommand ( "SendForApprovalAgain", WriteParameters ) ) then
		s = s + "
		|and TimesheetApprovals.Ref in ( &Approvals )
		|and Tasks.RoutePoint = value ( BusinessProcess.TimesheetApproval.RoutePoint.Approval )
		|";
	elsif ( isCommand ( "ApplyResolutions", WriteParameters )
		or isCommand ( "ApproveTimesheet", WriteParameters ) ) then
		s = s + "
		|and TimesheetApprovals.Ref in ( &Approvals )
		|and ( Tasks.RoutePoint = value ( BusinessProcess.TimesheetApproval.RoutePoint.Approval )
		|or Tasks.RoutePoint = value ( BusinessProcess.TimesheetApproval.RoutePoint.Rework ) )
		|;";
		if ( isCommand ( "ApplyResolutions", WriteParameters ) ) then
			s = s + "
			|// @RejectedTime
			|select top 1 UserSettings.Ref as UserSettings, UserSettings.Owner.Email as Email
			|from Catalog.UserSettings as UserSettings
			|where UserSettings.Owner = &Creator
			|and UserSettings.TimesheetNotifications
			|and 1 in ( select 1 from InformationRegister.TimeResolutions where TimesheetApproval in ( &Approvals ) and Resolution = value ( Enum.Resolutions.Reject ) )
			|;";
		endif; 
		s = s + "
		|// @CompetedTime
		|select top 1 UserSettings.Ref as UserSettings, UserSettings.Owner.Email as Email
		|from Catalog.UserSettings as UserSettings
		|where UserSettings.Owner = &Creator
		|and UserSettings.TimesheetNotifications
		|and 1 not in ( select 1
		|			from BusinessProcess.TimesheetApproval as TimesheetApproval
		|			where TimesheetApproval.Timesheet = &Timesheet
		|			and not TimesheetApproval.DeletionMark
		|			and not TimesheetApproval.Completed )
		|";
	endif; 
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Function getApprovals ()
	
	approvals = new Array ();
	table = getTable ( Object );
	for each row in table do
		if ( row.Allowed ) then
			approvals.Add ( row.TimesheetApproval );
		endif; 
	enddo; 
	return approvals;
	
EndFunction 

&AtServer
Procedure sendApprovalOrReworkEmails ( Data )
	
	p = TimesheetMailing.GetParams ();
	p.TimesheetURL = Conversion.ObjectToURL ( Object.Ref );
	p.TimesheetNumber = Object.Number;
	p.Employee = "" + Object.Employee;
	table = Data.ApproveOrReworkTime;
	for each row in table do
		p.Action = row.Action;
		p.Email = row.Email;
		p.UserSettingsURL = Conversion.ObjectToURL ( row.UserSettings );
		jobParams = new Array ();
		jobParams.Add ( p );
		Jobs.Run ( "TimesheetMailing.Send", jobParams );
	enddo; 
	
EndProcedure 

&AtServer
Procedure sendRejectionOrCompletionEmails ( Data, WriteParameters )
	
	p = TimesheetMailing.GetParams ();
	p.TimesheetURL = Conversion.ObjectToURL ( Object.Ref );
	p.TimesheetNumber = Object.Number;
	if ( isCommand ( "ApplyResolutions", WriteParameters ) ) then
		if ( Data.RejectedTime <> undefined ) then
			p.Action = "SendRejectionToCreator";
			p.Email = Data.RejectedTime.Email;
			p.UserSettingsURL = Conversion.ObjectToURL ( Data.RejectedTime.UserSettings );
			p.User = "" + SessionParameters.User;
			jobParams = new Array ();
			jobParams.Add ( p );
			Jobs.Run ( "TimesheetMailing.Send", jobParams );
		endif;
	endif; 
	if ( Data.CompetedTime <> undefined ) then
		p.Action = "SendCompletionToCreator";
		p.Email = Data.CompetedTime.Email;
		p.UserSettingsURL = Conversion.ObjectToURL ( Data.CompetedTime.UserSettings );
		jobParams = new Array ();
		jobParams.Add ( p );
		Jobs.Run ( "TimesheetMailing.Send", jobParams );
	endif;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure SendForApproval ( Command )
	
	startCommand ( "SendForApproval" );
	
EndProcedure

&AtClient
Procedure startCommand ( CommandName )
	
	if ( CommandName = "SendForApproval" ) then
		Output.SendForApprovalConfirmation ( ThisObject, CommandName, , "commandConfirmation" );
	elsif ( CommandName = "SendForApprovalAgain" ) then
		Output.SendForApprovalAgainConfirmation ( ThisObject, CommandName, , "commandConfirmation" );
	elsif ( CommandName = "ApplyResolutions" ) then
		Output.ApplyResolutionsConfirmation ( ThisObject, CommandName, , "commandConfirmation" );
	else
		writeDocument ( CommandName );
	endif; 
	
EndProcedure

&AtClient
Procedure commandConfirmation ( Answer, CommandName ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		writeDocument ( CommandName );
	endif; 

EndProcedure

&AtClient
Procedure writeDocument ( CommandName )
	
	writeParams = new Structure ();
	writeParams.Insert ( "WriteMode", DocumentWriteMode.Posting );
	writeParams.Insert ( "Command", CommandName );
	Write ( writeParams );
	
EndProcedure 

&AtClient
Procedure SendForApprovalAgain ( Command )
	
	startCommand ( "SendForApprovalAgain" );
	
EndProcedure

&AtClient
Procedure ApplyResolutions ( Command )
	
	startCommand ( "ApplyResolutions" );
	
EndProcedure

&AtClient
Procedure ApproveTimesheet ( Command )
	
	Output.ApproveTimesheetConfirmation ( ThisObject );

EndProcedure

&AtClient
Procedure ApproveTimesheetConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		setPositiveResolutions ();
		startCommand ( "ApproveTimesheet" );
	endif; 
	
EndProcedure 

&AtClient
Procedure setPositiveResolutions ()
	
	Message ( "setPositiveResolutions" );
	table = getTable ( Object );
	resolution = PredefinedValue ( "Enum.Resolutions.Approve" );
	for each row in table do
		if ( row.Allowed ) then
			row.Resolution = resolution;
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure EmployeeOnChange ( Item )
	
	fill ();
	
EndProcedure

&AtServer
Procedure fill ()
	
	clear ();
	resetPeriod ();
	TimesheetForm.SetIndividual ( Object );
	setSchedule ();
	extractFields ();
	setPeriod ();
	adjustDays ();
	arrangeColumns ();
	clear ();
	loadEntries ();
	calcTotals ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.TimesheetPeriod" );
	
EndProcedure 

&AtServer
Procedure clear ()
	
	if ( Object.TableName = "" ) then
		return;
	endif; 
	table = getTable ( Object );
	table.Clear ();
	
EndProcedure 

&AtServer
Procedure resetPeriod ()
	
	Object.Date = undefined;
	Object.DateStart = undefined;
	Object.DateEnd = undefined;
	
EndProcedure 

&AtClient
Procedure PreviousPeriod ( Command )
	
	gotoNextTimesheet ( -1 );
	
EndProcedure

&AtClient
Procedure gotoNextTimesheet ( Direction )
	
	if ( not Forms.Check ( ThisObject, "Employee, DateStart" ) ) then
		return;
	endif; 
	if ( Modified ) then
		Output.GoToNextPeriodConfirmation ( ThisObject, Direction );
	else
		loadNextPeriod ( Direction );
	endif; 
	
EndProcedure 

&AtClient
Procedure GoToNextPeriodConfirmation ( Answer, Direction ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		if ( not Write () ) then
			return;
		endif; 
	elsif ( answer = DialogReturnCode.No ) then
		Modified = false;
	elsif ( answer = DialogReturnCode.Cancel ) then
		return;
	endif; 
	loadNextPeriod ( Direction );
	
EndProcedure 

&AtServer
Procedure loadNextPeriod ( Direction )
	
	nextPeriod = getNextPeriod ( Direction );
	nextTimesheet = getNextTimesheet ( nextPeriod );
	if ( nextTimesheet = undefined ) then
		if ( not CanEdit ) then
			return;
		endif; 
		ValueToFormAttribute ( getNewTimesheet ( nextPeriod ), "Object" );
		adjustDays ();
		loadEntries ();
	else
		ValueToFormAttribute ( nextTimesheet.GetObject (), "Object" );
	endif; 
	arrangeColumns ();
	setStatusAndTasks ();
	setMemos ();
	setApprovalSequence ();
	setRowsFilter ();
	setReadOnlyStatus ();
	setDefaultButton ();
	setDocumentSupportsApprovalProcess ();
	setTimeWasModified ( ThisObject, false );
	calcTotals ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure 

&AtServer
Function getNextPeriod ( Direction )
	
	period = new Structure ( "DateStart, DateEnd", Object.DateStart, Object.DateEnd );
	if ( Object.TableName = "Month" ) then
		period.DateStart = AddMonth ( period.DateStart, Direction );
		period.DateEnd = BegOfDay ( EndOfMonth ( period.DateStart ) );
	else
		if ( Direction = 1 ) then
			period.DateStart = period.DateEnd + 86400;
			period.DateEnd = period.DateEnd + Object.TimesheetDays * 86400;
		else
			period.DateEnd = period.DateStart - 86400;
			period.DateStart = period.DateStart - Object.TimesheetDays * 86400;
		endif; 
	endif; 
	return period;
	
EndFunction

&AtServer
Function getNextTimesheet ( Period )
	
	s = "
	|select top 1 Timesheets.Ref as Ref
	|from Document.Timesheet as Timesheets
	|where Timesheets.Employee = &Employee
	|and not Timesheets.DeletionMark
	|and Timesheets.DateStart between &DateStart and &DateEnd
	|and TimesheetPeriod = &TimesheetPeriod
	|";
	q = new Query ( s );
	q.SetParameter ( "Employee", Object.Employee );
	q.SetParameter ( "DateStart", Period.DateStart );
	q.SetParameter ( "DateEnd", Period.DateEnd );
	q.SetParameter ( "TimesheetPeriod", Object.TimesheetPeriod );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

&AtServer
Function getNewTimesheet ( Period )
	
	obj = Documents.Timesheet.CreateDocument ();
	obj.Employee = Object.Employee;
	obj.Individual = Object.Individual;
	obj.Creator = Object.Creator;
	obj.DateStart = Period.DateStart;
	obj.DateEnd = Period.DateEnd;
	obj.WeekStart = Object.WeekStart;
	obj.Schedule = Object.Schedule;
	obj.TableName = Object.TableName;
	obj.TimesheetDays = Object.TimesheetDays;
	obj.TimesheetPeriod = Object.TimesheetPeriod;
	obj.Date = CurrentDate ();
	return obj;
	
EndFunction 

&AtClient
Procedure NextPeriod ( Command )
	
	gotoNextTimesheet ( 1 );
	
EndProcedure

&AtClient
Procedure DateStartClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure DateStartStartChoice ( Item, ChoiceData, StandardProcessing )
	
	savePreviousDateStart ();
	
EndProcedure

&AtClient
Procedure savePreviousDateStart ()
	
	PreviousDateStart = Object.DateStart;
	
EndProcedure 

&AtClient
Procedure DateStartOnChange ( Item )
	
	Forms.ClearTables ( Object.Other, "ClearTableConfirmation", ThisObject, , true );
	
EndProcedure

&AtClient
Procedure ClearTableConfirmation ( Result, Params ) export
	
	if ( Result ) then
		applyNewDateStart ();
	else
		setPreviousDateStart ();
	endif; 
	
EndProcedure

&AtServer
Procedure applyNewDateStart ()
	
	setDateEnd ();
	arrangeColumns ();
	loadEntries ();
	calcTotals ( ThisObject );
	
EndProcedure 

&AtServer
Procedure setDateEnd ()
	
	Object.DateEnd = Object.DateStart + Object.TimesheetDays * 86400;
	
EndProcedure 

&AtClient
Procedure setPreviousDateStart ()
	
	Object.DateStart = PreviousDateStart;
	
EndProcedure 

// *****************************************
// *********** Group OneWeek

&AtClient
Procedure OneWeekChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	StandardProcessing = false;
	if ( TypeOf ( SelectedValue ) = Type ( "Structure" ) ) then
		proceedTimeEntryCommand ( Item, SelectedValue );
	endif; 
	
EndProcedure

&AtClient
Procedure proceedTimeEntryCommand ( Item, Params )
	
	#if ( WebClient ) then
		// Bug workaround for 8.3.13.1513: In edit mode, webclient shows hours in a wrong cell 
		Item.EndEditRow ( false );
	#endif
	if ( Params.Command = "Update" ) then
		day = getDayNumberByCell ( Item.CurrentItem );
		applyTimeEntry ( Params, day, Item.CurrentData.LineNumber - 1 );
	elsif ( Params.Command = "Delete" ) then
		clearMinutesAndTimeEntry ( Item, Params );
	endif; 
	setCellTextEdit ( Item );
	Modified = true;
	
EndProcedure 

&AtServer
Procedure applyTimeEntry ( val Params, val Day, val RowIndex )
	
	defineColumns ( Day );
	detachTimeEntry ( Params );
	attachTimeEntry ( Params, RowIndex);
	calcTotal ( ThisObject );
	calcTotals ( ThisObject );
	Write ();
	
EndProcedure 

&AtServer
Procedure defineColumns ( Day )
	
	DayColumn = "Day" + Day;
	MinutesColumn = "Minutes" + Day;
	TimeEntryColumn = "TimeEntry" + Day;
	TimeTable = getTable ( Object );
	
EndProcedure 

&AtServer
Procedure detachTimeEntry ( Params )
	
	rows = TimeTable.FindRows ( new Structure ( TimeEntryColumn, Params.TimeEntry ) );
	for each row in rows do
		row [ MinutesColumn ] = 0;
		row [ DayColumn ] = 0;
		row [ TimeEntryColumn ] = undefined;
		resetExistTimeEntries ( Object, row );
		calcTotalByRow ( ThisObject, row );
	enddo; 
	
EndProcedure 

&AtServer
Procedure attachTimeEntry ( Params, RowIndex )
	
	timeList = Params.Time;
	project = Params.Project;
	customer = Params.Customer;
	entry = Params.TimeEntry;
	i = timeList.UBound ();
	while ( i >= 0 ) do
		time = timeList [ i ];
		type = time.Time;
		rows = TimeTable.FindRows ( new Structure ( "Project, TimeType", project, type ) );
		for each row in rows do
			minutes = time.Minutes;
			row [ TimeEntryColumn ] = entry;
			row [ minutesColumn ] = minutes;
			row [ dayColumn ] = Conversion.MinutesToDuration ( minutes );
			calcTotalByRow ( ThisObject, row );
			timeList.Delete ( i );
			break;
		enddo; 
		i = i - 1;
	enddo; 
	if ( timeList.Count () > 0 ) then
		i = RowIndex;
		for each time in timeList do
			type = time.Time;
			minutes = time.Minutes;
			i = i + 1;
			row = TimeTable.Insert ( i );
			row.Allowed = true;
			row.Project = project;
			row.Customer = customer;
			row.TimeType = type;
			row.ExistTimeEntries = true;
			row [ timeEntryColumn ] = entry;
			row [ minutesColumn ] = minutes;
			row [ dayColumn ] = Conversion.MinutesToDuration ( minutes );
			calcTotalByRow ( ThisObject, row );
		enddo; 
	endif; 
	
EndProcedure 

&AtClient
Procedure clearMinutesAndTimeEntry ( Item, Params )
	
	dayNumber = getDayNumberByCell ( Item.CurrentItem );
	dayColumn = "Day" + dayNumber;
	minutesColumn = "Minutes" + dayNumber;
	timeEntryColumn = "TimeEntry" + dayNumber;
	table = getTable ( Object );
	foundRows = table.FindRows ( new Structure ( "Project", Params.Project ) );
	for each row in foundRows do
		row [ dayColumn ] = 0;
		row [ minutesColumn ] = 0;
		row [ timeEntryColumn ] = undefined;
		resetExistTimeEntries ( Object, row );
		calcTotalByRow ( ThisObject, row );
	enddo;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure resetExistTimeEntries ( Object, Row )
	
	for i = 1 to Object.TimesheetDays do
		timeEntry = Row [ "TimeEntry" + i ];
		if ( not timeEntry.IsEmpty () ) then
			return;
		endif; 
	enddo; 
	Row.ExistTimeEntries = false;
	
EndProcedure 

&AtClient
Procedure setCellTextEdit ( Item )
	
	data = getTimeEntryAndDate ( Item );
	if ( data <> undefined ) then
		Item.CurrentItem.TextEdit = data.TimeEntry.IsEmpty ();
	endif; 
	
EndProcedure 

&AtClient
Function getTimeEntryAndDate ( Item )
	
	if ( Item.CurrentData = undefined or Item.CurrentItem = undefined ) then
		return undefined;
	endif; 
	dayColumn = Object.TableName + "Day";
	if ( Find ( Item.CurrentItem.Name, dayColumn ) = 0 ) then
		return undefined;
	endif;
	dayNumber = getDayNumberByCell ( Item.CurrentItem );
	timeEntry = Item.CurrentData [ "TimeEntry" + dayNumber ];
	day = Object.DateStart + 86400 * ( Number ( dayNumber ) - 1 );
	return new Structure ( "TimeEntry, Day", timeEntry, day );
	
EndFunction 

&AtClient
Procedure OneWeekBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = approvalStatus ( ThisObject );
	
EndProcedure

&AtClient
Procedure OneWeekOnStartEdit ( Item, NewRow, Clone )
	
	if ( Clone ) then
		resetTimeEntries ( Item );
		setOrganizationReadonlyFlag ( Item );
	else
		if ( NewRow ) then
			setWeekFieldsByDefault ( Item.CurrentData );
		else
			setTimeTypeAndProjectReadonlyFlag ( Item );
			setOrganizationReadonlyFlag ( Item );
		endif; 
	endif; 

EndProcedure

&AtClient
Procedure resetTimeEntries ( Item )
	
	currentData = Item.CurrentData;
	for i = 1 to Object.TimesheetDays do
		currentData [ "TimeEntry" + i ] = undefined;
	enddo; 
	currentData.ExistTimeEntries = false;
	
EndProcedure 

&AtClient
Procedure setOrganizationReadonlyFlag ( Table )
	
	currentData = Table.CurrentData;
	Items [ Table.Name + "Customer" ].Readonly = currentData.ExistTimeEntries;
	
EndProcedure 

&AtClient
Procedure setWeekFieldsByDefault ( Row )
	
	Row.Allowed = true;
	
EndProcedure 

&AtClient
Procedure setTimeTypeAndProjectReadonlyFlag ( Table )
	
	disable = Table.CurrentData.ExistTimeEntries;
	tableName = Table.Name;
	Items [ tableName + "TimeType" ].Readonly = disable;
	Items [ tableName + "Project" ].Readonly = disable;
	
EndProcedure 

&AtClient
Procedure OneWeekSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	openReadonlyField ( Item, Field, StandardProcessing );
	
EndProcedure

&AtClient
Procedure openReadonlyField ( Item, Field, StandardProcessing )
	
	if ( not Item.ReadOnly and not Field.ReadOnly ) then
		return;
	endif; 
	if ( columnIs ( Field, "Memo" ) ) then
		StandardProcessing = false;
		openMemo ( Item, Field );
	elsif ( columnIs ( Field, "Project" ) ) then
		StandardProcessing = false;
		ShowValue ( , Item.CurrentData.Project );
	elsif ( columnIs ( Field, "Customer" ) ) then
		StandardProcessing = false;
		ShowValue ( , Item.CurrentData.Customer );
	endif; 
	
EndProcedure 

&AtClient
Function columnIs ( Field, ColumnName )
	
	return Find ( Field.Name, ColumnName ) <> 0;
	
EndFunction 

&AtClient
Procedure openMemo ( Item, Field )
	
	currentData = Item.CurrentData;
	if ( RoutePoint = "Rework"
		or RoutePoint = "Approval" ) then
		p = new Structure ( "FillingValues", new Structure () );
		p.FillingValues.Insert ( "TimesheetApproval", currentData.TimesheetApproval );
		OpenForm ( "InformationRegister.TimesheetResolutions.Form.NewMemo", p, ThisObject, , , , new NotifyDescription ( "TimesheetsResolutionsNewMemo", ThisObject, currentData ), FormWindowOpeningMode.LockWholeInterface );
	else
		p = new Structure ( "Filter", new Structure () );
		p.Filter.Insert ( "TimesheetApproval", currentData.TimesheetApproval );
		OpenForm ( "InformationRegister.TimesheetResolutions.Form.List", p );
	endif; 
	
EndProcedure 

&AtClient
Procedure TimesheetsResolutionsNewMemo ( Result, Row ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	Row.Memo = Result;
	
EndProcedure 

&AtClient
Procedure OneWeekBeforeRowChange ( Item, Cancel )
	
	if ( openInsteadEdit ( Item ) ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtClient
Function openInsteadEdit ( Item )

	currentData = Item.CurrentData;
	if ( columnIs ( Item.CurrentItem, "TimeType" )
		and currentData.ExistTimeEntries ) then
		return true;
	endif;
	if ( columnIs ( Item.CurrentItem, "Project" )
		and currentData.ExistTimeEntries ) then
		ShowValue ( , currentData.Project );
		return true;
	endif;
	timeType = currentData.TimeType;
	if ( columnIs ( Item.CurrentItem, "Customer" )
		and ( currentData.ExistTimeEntries
		or timeType = PredefinedValue ( "Enum.Time.Holiday" )
		or timeType = PredefinedValue ( "Enum.Time.Sickness" )
		or timeType = PredefinedValue ( "Enum.Time.Vacation" )
		or timeType = PredefinedValue ( "Enum.Time.ExtendedVacation" ) ) ) then
		ShowValue ( , currentData.Customer );
		return true;
	endif; 
	return false;

EndFunction 

&AtClient
Procedure OneWeekBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	if ( approvalStatus ( ThisObject )
		or rowContainsTimeEntries ( Item ) ) then
		return;
	else
		Output.RecordRemovingConfirmation ( ThisObject, Item );
	endif; 
	
EndProcedure

&AtClient
Function rowContainsTimeEntries ( Item )
	
	currentData = Item.CurrentData;
	if ( currentData.ExistTimeEntries ) then
		Output.RowContainsTimeEntries ();
		return true;
	endif; 
	return false;
	
EndFunction 

&AtClient
Procedure RecordRemovingConfirmation ( Answer, Item ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		Modified = true;
		Forms.DeleteSelectedRows ( getTable ( Object ), Item );
		calcTotal ( ThisObject );
		calcTotals ( ThisObject );
	endif; 
	
EndProcedure 

&AtClient
Procedure OneWeekOnEditEnd ( Item, NewRow, CancelEdit )
	
	enableKeyColumns ( Item );
	calcTotal ( ThisObject );
	calcTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure enableKeyColumns ( Item )
	
	tableName = Item.Name;
	Items [ tableName + "TimeType" ].Readonly = false;
	Items [ tableName + "Customer" ].Readonly = false;
	Items [ tableName + "Project" ].Readonly = false;
	
EndProcedure 

&AtClient
Procedure OneWeekOnActivateCell ( Item )
	
	setCellTextEdit ( Item );
	
EndProcedure

&AtClient
Procedure OneWeekResolutionOnChange ( Item )
	
	changeResolution ( Item );
	
EndProcedure

&AtClient
Procedure changeResolution ( Item )
	
	currentData = getParent ( Item ).CurrentData;
	approvalProcess = currentData.TimesheetApproval;
	table = getTable ( Object );
	foundRows = table.FindRows ( new Structure ( "TimesheetApproval", approvalProcess ) );
	for each row in foundRows do
		row.Resolution = currentData.Resolution;
	enddo; 
	
EndProcedure 

&AtClient
Function getParent ( Item )
	
	element = Item;
	typeTable = Type ( "FormTable" );
	while ( true ) do
		if ( TypeOf ( element.Parent ) = typeTable ) then
			return element.Parent;
		endif;
		element = element.Parent;
	enddo; 
	
EndFunction 

&AtClient
Procedure OneWeekProjectOnChange ( Item )
	
	setTimeType ( Item );
	
EndProcedure

&AtClient
Procedure setTimeType ( Item )
	
	currentData = Item.Parent.CurrentData;
	timeType = getTimeType ( currentData.Project, Object.Employee );
	currentData.TimeType = timeType;
	
EndProcedure 

&AtServerNoContext
Function getTimeType ( val Project, val Employee )
	
	s = "
	|select top 1 Tasks.TimeType as TimeType
	|from Catalog.Projects.Tasks as Tasks
	|where Tasks.Ref = &Project
	|and Tasks.Employee = &Employee
	|";
	q = new Query ( s );
	q.SetParameter ( "Project", Project );
	q.SetParameter ( "Employee", Employee );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		type = DF.Pick ( Project, "ProjectType" );
		if ( type = Enums.ProjectTypes.Holidays ) then
			return Enums.Time.Holiday;
		elsif ( type = Enums.ProjectTypes.SickDays ) then
			return Enums.Time.Sickness;
		elsif ( type = Enums.ProjectTypes.Vacations ) then
			return Enums.Time.Vacation;
		else
			return Enums.Time.Billable;
		endif; 
	else
		return table [ 0 ].TimeType;
	endif; 
	
EndFunction

&AtClient
Procedure OneWeekTimeTypeOnChange ( Item )
	
	applyTimeType ( Item );
	
EndProcedure

&AtClient
Procedure applyTimeType ( Item )
	
	data = Item.Parent.CurrentData;
	fields = adjustProject ( data.Customer, data.Project, data.TimeType );
	data.Customer = fields.Customer;
	data.Project = fields.Project;
	
EndProcedure 

&AtServerNoContext
Function adjustProject ( val Customer, val Project, val TimeType )
	
	result = new Structure ( "Customer, Project", Customer, Project );
	fields = DF.Values ( Project, "Owner, ProjectType, Company.Organization as Organization" );
	if ( TimeType = Enums.Time.Sickness
		or TimeType = Enums.Time.Vacation
		or TimeType = Enums.Time.ExtendedVacation
		or TimeType = Enums.Time.Holiday ) then
		result.Customer = fields.Organization;
	endif; 
	projectType = fields.ProjectType;
	if ( fields.Owner <> result.Customer
		or ( TimeType = Enums.Time.Holiday
			and projectType <> Enums.ProjectTypes.Holidays )
		or ( TimeType = Enums.Time.Sickness
			and projectType <> Enums.ProjectTypes.SickDays )
		or ( TimeType = Enums.Time.Vacation
			and projectType <> Enums.ProjectTypes.Vacations )
		or ( TimeType = Enums.Time.ExtendedVacation
			and projectType <> Enums.ProjectTypes.Vacations )
		or ( ( TimeType = Enums.Time.Banked
				or TimeType = Enums.Time.BankedUse
				or TimeType = Enums.Time.Overtime
				or TimeType = Enums.Time.DayOff
				or TimeType = Enums.Time.Evening
				or TimeType = Enums.Time.Night
				or TimeType = Enums.Time.Billable
				or TimeType = Enums.Time.NonBillable )
			and projectType <> Enums.ProjectTypes.Regular ) )
	then
		result.Project = undefined;
	endif; 
	return result;
	
EndFunction

&AtClient
Procedure OneWeekDay1Clearing ( Item, StandardProcessing )
	
	StandardProcessing = Item.TextEdit;
	if ( Item.TextEdit ) then
		setTimeWasModified ( ThisObject, true );
	endif; 
	
EndProcedure

&AtClient
Procedure OneWeekDay1OnChange ( Item )
	
	currentData = Item.Parent.CurrentData;
	dayNumber = getDayNumberByCell ( Item );
	adjustTime ( dayNumber, currentData );
	calcMinutes ( dayNumber, currentData );
	calcTotalByRow ( ThisObject, currentData );
	setTimeWasModified ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure adjustTime ( DayNumber, Row )
	
	dayColumn = "Day" + dayNumber;
	Conversion.AdjustTime ( Row [ dayColumn ] );
	
EndProcedure 

&AtClient
Procedure calcMinutes ( DayNumber, Row )
	
	dayColumn = "Day" + dayNumber;
	minutesColumn = "Minutes" + dayNumber;
	Row [ minutesColumn ] = Conversion.DurationToMinutes ( Row [ dayColumn ] );
	
EndProcedure 

&AtClient
Function getDayNumberByCell ( Item )
	
	return StrReplace ( Item.Name, Item.Parent.Name + "Day", "" );
	
EndFunction 

&AtClient
Procedure OneWeekDay1Opening ( Item, StandardProcessing )
	
	StandardProcessing = false;
	if ( not rowFillChecking ( Item ) ) then
		return;
	endif; 
	openTimeEntry ();
	
EndProcedure

&AtClient
Function rowFillChecking ( Item )
	
	error = false;
	table = Item.Parent;
	currentData = table.CurrentData;
	rowPath = Output.Row ( table.Name, currentData.LineNumber, "" );
	fields = new Array ();
	fields.Add ( "TimeType" );
	fields.Add ( "Customer" );
	fields.Add ( "Project" );
	for each field in fields do
		if ( currentData [ field ].IsEmpty () ) then
			Output.FieldIsEmpty ( , rowPath + field  );
			error = true;
		endif; 
	enddo; 
	return not error;
	
EndFunction 

&AtClient
Procedure openTimeEntry ()
	
	table = getFormTable ( ThisObject );
	currentData = table.CurrentData;
	data = getTimeEntryAndDate ( table );
	p = new Structure ();
	p.Insert ( "TimesheetBase", true );
	p.Insert ( "TimesheetTime", currentData.TimeType );
	if ( data.TimeEntry.IsEmpty () ) then
		p.Insert ( "FillingValues", new Structure () );
		fillingValues = p.FillingValues;
		fillingValues.Insert ( "Customer", currentData.Customer );
		fillingValues.Insert ( "Project", currentData.Project );
		fillingValues.Insert ( "Date", data.Day );
		employee = Object.Employee;
		fillingValues.Insert ( "Employee", employee );
		fillingValues.Insert ( "Performer", findPerformer ( employee ) );
	else
		p.Insert ( "Key", data.TimeEntry );
	endif; 
	OpenForm ( "Document.TimeEntry.ObjectForm", p, table );
	
EndProcedure

&AtServerNoContext
Function findPerformer ( val Employee ) export
	
	return TimesheetForm.FindPerformer ( Employee );

EndFunction
