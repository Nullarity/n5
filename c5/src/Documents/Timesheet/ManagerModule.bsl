#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "DateStart" );
	Fields.Add ( "DateEnd" );
	Fields.Add ( "Number" );
	Fields.Add ( "Employee" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.Timesheet.Synonym + " #" + Data.Number + ", " + Data.Employee + ", " + Conversion.DateToString ( Data.DateStart ) + " - " + Conversion.DateToString ( Data.DateEnd );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	setContext ( Env );
	if ( Env.Command = undefined
		and not Env.TimeWasModified ) then
		return true;
	endif; 
	getData ( Env );
	makeHours ( Env );
	makeProjectsCost ( Env );
	if ( Env.Fields.UseOvertime ) then
		makeOvertime ( Env );
	endif; 
	makeTimesheetsStatuses ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure setContext ( Env )
	
	Env.Insert ( "Command" );
	Env.Properties.Property ( "Command", Env.Command );
	Env.Insert ( "TimeWasModified" );
	Env.Properties.Property ( "TimeWasModified", Env.TimeWasModified );
	
EndProcedure

Procedure getData ( Env )
	
	sqlFields ( Env );
	sqlTimesheetStatus ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	Env.Q.SetParameter ( "Employee", Env.Fields.Employee );
	Env.Q.SetParameter ( "OvertimeDateStart", Env.Fields.DateStart );
	Env.Q.SetParameter ( "OvertimeBalanceDate", Env.Fields.DateEnd );
	sqlTime ( Env );
	sqlHours ( Env );
	sqlRejectedTime ( Env );
	if ( Env.Fields.UseOvertime ) then
		sqlScheduleMinutes ( Env );
		sqlOvertimeCurrentBalance ( Env );
	endif; 
	SQL.Perform ( Env );

EndProcedure 

Procedure sqlFields ( Env )
	
	s = "
	|select Documents.DateStart as DateStart, Documents.DateEnd as DateEnd, Documents.Employee as Employee, Documents.TableName as TableName,
	|	Documents.Employee.HourlyCost as EmployeeHourlyCost, Documents.Employee.Currency as EmployeeCurrency,
	|	datediff ( Documents.DateStart, Documents.DateEnd, day ) + 1 as DaysCount, Documents.Schedule as Schedule, Documents.Schedule.UseOvertime as UseOvertime,
	|	Documents.Schedule.OvertimeLimit * 60 as OvertimeLimit, year ( Documents.DateStart ) as YearDateStart,
	|	year ( Documents.DateEnd ) as YearDateEnd, Documents.Minutes as Minutes
	|into Fields
	|from Document.Timesheet as Documents
	|where Documents.Ref = &Ref
	|;
	|// @Fields
	|select * from Fields
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlTimesheetStatus ( Env )
	
	s = "
	|// @Statuses
	|select isnull ( Approvals.Started, true ) as Started, isnull ( Approvals.Completed, true ) as Completed
	|from (
	|	select sum ( case when isnull ( Approvals.Started, false ) then 1 else 0 end ) as Started,
	|		sum ( case when isnull ( Approvals.Completed, false ) then 1 else 0 end ) as Completed
	|	from BusinessProcess.TimesheetApproval as Approvals
	|	where Approvals.Timesheet = &Ref
	|) as Approvals
	|";
	Env.Selection.Add ( s );
	
EndProcedure 
 
Procedure sqlTime ( Env )
	
	minutes = "";
	dayField = "case when Time.TimeEntry%DayNumber = value ( Document.TimeEntry.EmptyRef ) then Minutes%DayNumber else 0 end";
	dayStruct = new Structure ( "DayNumber" );
	for i = 1 to Env.Fields.DaysCount do
		dayStruct.DayNumber = i;
		minutes = minutes + " + sum ( " + Output.FormatStr ( dayField, dayStruct ) + " )";
	enddo; 
	minutes = Mid ( minutes, 3 );
	s = "
	|// #Time
	|select Time.Project as Project, Time.Project.Currency as ProjectCurrency, Time.TimeType as TimeType, " + minutes + " as Minutes
	|from Document.Timesheet." + Env.Fields.TableName + " as Time
	|	join Fields as Fields
	|	on true
	|where Time.Ref = &Ref
	|and ( Time.TimeType = value ( Enum.Time.Billable )
	|	or Time.TimeType = value ( Enum.Time.NonBillable ) )
	|and Time.Project.ProjectType not in (
	|		value ( Enum.ProjectTypes.SickDays ),
	|		value ( Enum.ProjectTypes.Vacations ),
	|		value ( Enum.ProjectTypes.Holidays ) )
	|and Time.TimesheetApproval not in (
	|	select TimesheetApproval
	|	from InformationRegister.TimeResolutions
	|	where Resolution = value ( Enum.Resolutions.Reject ) )
	|group by Time.Project, Time.TimeType
	|having " + minutes + " <> 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlHours ( Env )
	
	if ( not Env.Statuses.Completed ) then
		return;
	endif; 
	parts = new Array ();
	table = "Document.Timesheet." + Env.Fields.TableName + " as Time";
	for i = 1 to Env.Fields.DaysCount do
		parts.Add ( "
		|select TimesheetApproval as TimesheetApproval, TimeType as TimeType,
		|	" + i + " as Day, Minutes" + i + " as Minutes
		|from " + table + "
		|where Time.Ref = &Ref
		|" );
	enddo;
	s = "
	|// #Hours
	|select Time.TimeType as TimeType, Time.Day as Day,
	|	sum ( Time.Minutes ) as Minutes
	|from ( " + StrConcat ( parts, " union all " ) + " ) as Time
	|	//
	|	// Resolutions
	|	//
	|	left join InformationRegister.TimeResolutions as Resolutions
	|	on Resolutions.TimesheetApproval = Time.TimesheetApproval
	|where Time.TimesheetApproval = value ( BusinessProcess.TimesheetApproval.EmptyRef )
	|or Resolutions.Resolution = value ( Enum.Resolutions.Approve )
	|group by Time.TimeType, Time.Day
	|having sum ( Time.Minutes ) <> 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlRejectedTime ( Env )
	
	timeEntryField = "";
	for i = 1 to Env.Fields.DaysCount do
		timeEntryField = timeEntryField + ", Time.TimeEntry" + i + " as _" + i;
	enddo;
	s = "
	|// #RejectedRows
	|select " + Mid ( timeEntryField, 3 ) + "
	|from Document.Timesheet." + Env.Fields.TableName + " as Time
	|	join InformationRegister.TimeResolutions as TimeResolutions
	|	on TimeResolutions.TimesheetApproval = Time.TimesheetApproval
	|	and TimeResolutions.Resolution = value ( Enum.Resolutions.Reject )
	|where Time.Ref = &Ref
	|and Time.ExistTimeEntries
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlScheduleMinutes ( Env )
	
	s = "
	|// @MinutesBySchedule
	|select sum ( Schedules.Minutes ) as Minutes
	|from InformationRegister.Schedules as Schedules
	|	join Fields as Fields
	|	on Fields.Schedule = Schedules.Schedule
	|	and ( Fields.YearDateStart = Schedules.Year
	|		or Fields.YearDateEnd = Schedules.Year )
	|	and Schedules.Day between Fields.DateStart and Fields.DateEnd
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlOvertimeCurrentBalance ( Env )
	
	s = "
	|// #OvertimeBalances
	|select Overtime.Timesheet as Timesheet, Overtime.MinutesBalance as Minutes
	|from AccumulationRegister.Overtime.Balance ( &OvertimeBalanceDate, Timesheet.Employee = &Employee ) as Overtime
	|order by Overtime.Timesheet.DateEnd
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure makeHours ( Env )

	if ( not Env.Statuses.Completed ) then
		return;
	endif; 
	registers = Env.Registers;
	hours = registers.Hours;
	bankedHours = registers.BankedHours;
	employee = Env.Fields.Employee;
	dateStart = Env.Fields.DateStart;
	for each row in Env.Hours do
		day = dateStart + 86400 * ( row.Day - 1 );;
		minutes = row.Minutes;
		time = row.TimeType;
		movement = hours.Add ();
		movement.Employee = employee;
		movement.Day = day;
		movement.Time = time;
		movement.Minutes = minutes;
		if ( time = Enums.Time.Banked ) then
			movement = bankedHours.Add ();
		elsif ( time = Enums.Time.BankedUse ) then
			movement = bankedHours.AddExpense ();
		else
			continue;
		endif; 
		movement.Employee = employee;
		movement.Period = day;
		movement.Minutes = row.Minutes;
	enddo;
	
EndProcedure

Procedure makeProjectsCost ( Env )
	
	makeProjectsCostByTimesheet ( Env );
	reverseTimeEntriesCost ( Env );
	makeRejectedTimeEntries ( Env );
	Env.Registers.ProjectsCost.Write = true;
	
EndProcedure 

Procedure makeProjectsCostByTimesheet ( Env )
	
	table = Env.Time;
	for each row in table do
		movement = Env.Registers.ProjectsCost.Add ();
		movement.Period = Env.Fields.DateEnd;
		movement.Employee = Env.Fields.Employee;
		movement.Project = row.Project;
		if ( row.TimeType = Enums.Time.Billable ) then
			minutes = row.Minutes;
			movement.BillableMinutes = minutes;
		elsif ( row.TimeType = Enums.Time.NonBillable ) then
			minutes = row.Minutes;
			movement.NonBillableMinutes = minutes;
		endif; 
		hourlyCost = Currencies.Convert ( Env.Fields.EmployeeHourlyCost, Env.Fields.EmployeeCurrency, row.ProjectCurrency, Env.Fields.DateEnd );
		movement.Cost = hourlyCost * ( minutes / 60 );
	enddo; 
	
EndProcedure 

Procedure reverseTimeEntriesCost ( Env )
	
	getTimeEntriesProjectsCost ( Env );
	table = Env.TimeEntriesProjectsCost;
	for each row in table do
		movement = Env.Registers.ProjectsCost.Add ();
		movement.Period = Env.Fields.DateEnd;
		movement.Employee = Env.Fields.Employee;
		movement.Project = row.Project;
		movement.Task = row.Task;
		movement.BillableMinutes = - row.BillableMinutes;
		movement.NonBillableMinutes = - row.NonBillableMinutes;
		movement.Cost = - row.Cost;
	enddo; 
	
EndProcedure 

Procedure getTimeEntriesProjectsCost ( Env )
	
	sqlTimeEntriesProjectsCost ( Env );
	getRejectedTimeEntries ( Env );
	Env.Q.SetParameter ( "TimeEntries", Env.RejectedTimeEntries );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure sqlTimeEntriesProjectsCost ( Env )
	
	s = "
	|// #TimeEntriesProjectsCost
	|select ProjectsCost.Project as Project, ProjectsCost.Task as Task, sum ( ProjectsCost.Cost ) as Cost,
	|	sum ( ProjectsCost.BillableMinutes ) as BillableMinutes, sum ( ProjectsCost.NonBillableMinutes ) as NonBillableMinutes
	|from AccumulationRegister.ProjectsCost as ProjectsCost
	|where ProjectsCost.Recorder in ( &TimeEntries )
	|group by ProjectsCost.Project, ProjectsCost.Task
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure getRejectedTimeEntries ( Env )
	
	timeEntries = new Array ();
	alreadyAdded = new Map ();
	reverseTimeEntries = Env.RejectedRows;
	for i = 1 to Env.Fields.DaysCount do
		column = "_" + i;
		for each row in reverseTimeEntries do
			timeEntry = row [ column ];
			if ( timeEntry.IsEmpty () ) then
				continue;
			elsif ( alreadyAdded [ timeEntry ] <> undefined ) then
				continue;
			endif; 
			alreadyAdded [ timeEntry ] = true;
			timeEntries.Add ( timeEntry );
		enddo;
	enddo; 
	Env.Insert ( "RejectedTimeEntries", timeEntries );
	
EndProcedure

Procedure makeRejectedTimeEntries ( Env )
	
	if ( Env.Command <> "ApplyResolutions" ) then
		return;
	endif; 
	for each timeEntry in Env.RejectedTimeEntries do
		movement = Env.Registers.RejectedTimeEntries.Add ();
		movement.TimeEntry = timeEntry;
	enddo; 
	Env.Registers.RejectedTimeEntries.Write = true;
	
EndProcedure 

Procedure makeTimesheetsStatuses ( Env )
	
	if ( Env.Command <> "SendForApproval"
		and Env.Command <> "ApplyResolutions"
		and Env.Command <> "ApproveTimesheet" ) then
		return;
	endif;
	recordset = Env.Registers.TimesheetStatuses;
	record = recordset.Add ();
	record.Timesheet = Env.Ref;
	if ( Env.Statuses.Started = Env.Statuses.Completed ) then
		record.Status = Enums.TimesheetStatuses.Finished;
	elsif ( Env.Statuses.Started ) then
		record.Status = Enums.TimesheetStatuses.Approval;
	else
		record.Status = Enums.TimesheetStatuses.None;
	endif; 
	Env.Registers.TimesheetStatuses.Write = true;
	
EndProcedure 

Procedure makeOvertime ( Env )
	
	overtime = Env.Fields.Minutes - Env.MinutesBySchedule.Minutes;
	if ( overtime > 0 ) then
		makeNewOvertime ( Env, overtime );
	elsif ( overtime < 0 ) then
		closePreviousOvertime ( Env, - overtime );
	endif; 

EndProcedure 

Procedure makeNewOvertime ( Env, Overtime )
	
	movement = Env.Registers.Overtime.Add ();
	movement.Period = Env.Fields.DateEnd;
	movement.Timesheet = Env.Ref;
	movement.Minutes = Min ( Overtime, Env.Fields.OvertimeLimit );
	
EndProcedure 

Procedure closePreviousOvertime ( Env, Overtime )
	
	table = Env.OvertimeBalances;
	for each row in table do
		movement = Env.Registers.Overtime.AddExpense ();
		movement.Period = Env.Fields.DateEnd;
		movement.Timesheet = row.Timesheet;
		movement.Minutes = Min ( row.Minutes, Overtime );
		Overtime = Overtime - movement.Minutes;
		if ( Overtime = 0 ) then
			break;
		endif; 
	enddo; 
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Overtime.Write = true;
	registers.Hours.Write = true;
	registers.BankedHours.Write = true;
	
EndProcedure

Procedure FillApprovalSequence ( Timesheet, Table ) export
	
	sequenceTable = getApprovalSequenceTable ( Timesheet );
	searchStruct = new Structure ( "TimesheetApproval" );
	for each sequenceRow in sequenceTable do
		searchStruct.TimesheetApproval = sequenceRow.TimesheetApproval;
		foundRows = table.FindRows ( searchStruct );
		for each row in foundRows do
			row.ApprovalSequence = sequenceRow.Sequence;
		enddo; 
	enddo; 
	
EndProcedure 

Function getApprovalSequenceTable ( Timesheet )
	
	selectionByTimesheetApproval = getSelectionByTimesheetApproval ( Timesheet );
	table = new ValueTable ();
	table.Columns.Add ( "TimesheetApproval", new TypeDescription ( "BusinessProcessRef.TimesheetApproval" ) );
	table.Columns.Add ( "Sequence", new TypeDescription ( "String" ) );
	while ( selectionByTimesheetApproval.Next () ) do
		row = table.Add ();
		row.TimesheetApproval = selectionByTimesheetApproval.TimesheetApproval;
		selection = selectionByTimesheetApproval.Select ();
		while ( selection.Next () ) do
			row.Sequence = row.Sequence + " -> " + selection.Executor;
		enddo; 
		row.Sequence = Mid ( row.Sequence, 5 );
	enddo; 
	return table;
	
EndFunction 

Function getSelectionByTimesheetApproval ( Timesheet )
	
	s = "
	|select distinct Tasks.Date as Date, Tasks.BusinessProcess as TimesheetApproval, Tasks.User.Description as Executor
	|from Task.Task as Tasks
	|	//
	|	// TimesheetApproval
	|	//
	|	join BusinessProcess.TimesheetApproval as TimesheetApproval
	|	on TimesheetApproval.Ref = Tasks.BusinessProcess
	|	and TimesheetApproval.Timesheet = &Ref
	|where not Tasks.DeletionMark
	|and Tasks.Executed
	|order by Tasks.Date
	|totals by TimesheetApproval
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Timesheet );
	SetPrivilegedMode ( true );
	selection = q.Execute ().Select ( QueryResultIteration.ByGroups );
	SetPrivilegedMode ( false );
	return selection;
	
EndFunction 

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	getPrintData ( Params, Env );
	initTotals ( Env );
	addApprovalSequence ( Params, Env );
	putHeader ( Params, Env );
	putTableHeader ( Params, Env );
	putTable ( Params, Env );
	putTimeHeader ( Params, Env );
	putTimeTable ( Params, Env );
	putFooter ( Params, Env );
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	return true;
	
EndFunction

Procedure getPrintData ( Params, Env )
	
	sqlPrintHeader ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	sqlPrintTable ( Env );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlPrintHeader ( Env )
	
	s = "
	|// @Fields
	|select allowed presentation ( Document.Ref ) as Timesheet, presentation ( Document.Employee ) as Employee,
	|	presentation ( Document.Schedule ) as Schedule, Document.TimesheetDays as TimesheetDays,
	|	Document.DateStart as DateStart, Document.DateEnd as DateEnd, Document.Memo as Memo,
	|	case when Document.TimesheetPeriod = value ( Enum.TimesheetPeriods.Week ) then ""OneWeek""
	|		when Document.TimesheetPeriod = value ( Enum.TimesheetPeriods.TwoWeeks ) then ""TwoWeeks""
	|		when Document.TimesheetPeriod = value ( Enum.TimesheetPeriods.Month ) then ""Month""
	|		when Document.TimesheetPeriod = value ( Enum.TimesheetPeriods.Other ) then ""Other""
	|	end as TableName
	|from Document.Timesheet as Document
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlPrintTable ( Env )
	
	fields = "";
	for i = 1 to Env.Fields.TimesheetDays do
		minutesField = "Minutes" + i;
		dayField = "Day" + i;
		fields = fields + ", Time." + minutesField + " as " + minutesField + ", Time." + dayField + " as " + dayField;
	enddo; 
	fields = Mid ( fields, 3 );
	s = "
	|// #Time
	|select allowed presentation ( Time.Customer ) as Customer, presentation ( Time.Project ) as Project, Time.TimeType as TimeType,
	|	Time.TimesheetApproval as TimesheetApproval, Time.TotalMinutes as TotalMinutes, " + fields + "
	|from Document.Timesheet." + Env.Fields.TableName + " as Time
	|	join Catalog.Projects as Projects
	|	on Projects.Ref = Time.Project
	|where Time.Ref = &Ref
	|order by Time.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure initTotals ( Env )
	
	Env.Insert ( "BillableMinutes", 0 );
	Env.Insert ( "OtherMinutes", 0 );
	Env.Insert ( "TotalsByTime", TimesheetForm.TotalsTable () );
	
EndProcedure 

Procedure addApprovalSequence ( Params, Env )
	
	Env.Time.Columns.Add ( "ApprovalSequence", new TypeDescription ( "String" ) );
	FillApprovalSequence ( Params.Reference, Env.Time );
	
EndProcedure 

Procedure putHeader ( Params, Env )
	
	area = Env.T.GetArea ( "Header|VerticalHeader" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putTableHeader ( Params, Env )
	
	area = Env.T.GetArea ( "TableHeader|VerticalHeader" );
	tabDoc = Params.TabDoc;
	tabDoc.Put ( area );
	area = Env.T.GetArea ( "TableHeader|Day" );
	p = area.Parameters;
	day = Env.Fields.DateStart;
	while ( day <= Env.Fields.DateEnd ) do
		p.Day = day;
		tabDoc.Join ( area );
		day = day + 86400;
	enddo; 
	area = Env.T.GetArea ( "TableHeader|TotalByDays" );
	tabDoc.Join ( area );
	
EndProcedure
 
Procedure putTable ( Params, Env )
	
	tabDoc = Params.TabDoc;
	Print.Repeat ( tabDoc );
	rowArea = Env.T.GetArea ( "Row|VerticalHeader" );
	dayArea = Env.T.GetArea ( "Row|Day" );
	totalByDaysArea = Env.T.GetArea ( "Row|TotalByDays" );
	table = Env.Time;
	totals = Env.TotalsByTime;
	lineNumber = 0;
	p = rowArea.Parameters;
	for each row in table do
		lineNumber = lineNumber + 1;
		p.Fill ( row );
		p.LineNumber = lineNumber;
		tabDoc.Put ( rowArea );
		joinDays ( Params, Env, row, dayArea, totalByDaysArea );
		totalRow = totals.Add ();
		totalRow.TotalMinutes = row.TotalMinutes;
		totalRow.TimeType = row.TimeType;
	enddo; 
	
EndProcedure

Procedure joinDays ( Params, Env, Row, DayArea, TotalByDaysArea )
	
	totalMinutes = 0;
	tabDoc = Params.TabDoc;
	p = DayArea.Parameters;
	for i = 1 to Env.Fields.TimesheetDays do
		day = row [ "Day" + i ];
		minutes = row [ "Minutes" + i ];
		p.Day = day;
		tabDoc.Join ( DayArea );
		totalMinutes = totalMinutes + minutes;
	enddo; 
	TotalByDaysArea.Parameters.Day = Conversion.MinutesToDuration ( totalMinutes );
	tabDoc.Join ( TotalByDaysArea );
	
EndProcedure 

Procedure putTimeHeader ( Params, Env )
	
	area = Env.T.GetArea ( "TimeHeader|VerticalHeader" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	tabDoc = Params.TabDoc;
	tabDoc.Put ( area );
	area = Env.T.GetArea ( "TimeHeader|Day" );
	p = area.Parameters;
	table = Env.Time;
	for i = 1 to Env.Fields.TimesheetDays do
		minutes = TimesheetForm.TotalByColumn ( table, "Minutes" + i );
		area.Parameters.Day = Conversion.MinutesToDuration ( minutes );
		tabDoc.Join ( area );
	enddo;
	area = Env.T.GetArea ( "TimeHeader|TotalByDays" );
	totals = Env.TotalsByTime;
	totals.GroupBy ( "TimeType", "TotalMinutes" );
	area.Parameters.Day = Conversion.MinutesToDuration ( TimesheetForm.GetTotal ( totals ) );
	tabDoc.Join ( area );
	
EndProcedure

Procedure putTimeTable ( Params, Env )

	area = Env.T.GetArea ( "TimeRow" );
	tabDoc = Params.TabDoc;
	p = area.Parameters;
	for each time in Env.TotalsByTime do
		minutes = time.TotalMinutes;
		if ( minutes = 0 ) then
			continue;
		endif; 
		p.TimeType = time.TimeType;
		p.Total = Conversion.MinutesToDuration ( minutes );
		tabDoc.Put ( area );
	enddo; 
	
EndProcedure

Procedure putFooter ( Params, Env )
	
	area = Env.T.GetArea ( "Footer" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure setPageSettings ( Params )
	
	Params.TabDoc.FitToPage = true;
	
EndProcedure 

#endregion

#endif