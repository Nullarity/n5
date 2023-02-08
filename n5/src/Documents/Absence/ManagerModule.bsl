#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Absence.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	if ( not checkCollisions ( Env )
		or not checkHours ( Env ) ) then
		return false;
	endif;
	makeHours ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	getFields ( Env );
	sqlCollisions ( Env );
	sqlCalendar ( Env );
	sqlPersonnel ( Env );
	sqlLocation ( Env );
	sqlHours ( Env );
	getTables ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// Absence
	|select distinct Employees.Employee as Employee, Employees.DateStart as DateStart, Employees.DateEnd as DateEnd
	|into Absence
	|from Document.Absence.Employees as Employees
	|where Employees.Ref = &Ref
	|index by Employee
	|;
	|// @Fields
	|select min ( Employees.DateStart ) as DateStart, max ( endofperiod ( Employees.DateEnd, day ) ) as DateEnd
	|from Absence as Employees
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )

	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );

EndProcedure

Procedure sqlCollisions ( Env ) 

	s = "
	|// Employees
	|select Employees.Employee as Employee, Employees.DateStart as DateStart, Employees.DateEnd as DateEnd, Employees.LineNumber as Line
	|into EmployeesDocument
	|from Document.Absence.Employees as Employees
	|where Employees.Ref = &Ref
	|index by Employees.Employee, Employees.DateStart, Employees.DateEnd
	|;
	|// #CollisionsRows
	|select Employees.Employee.Description as Employee, min ( Employees.Line ) as Line
	|from EmployeesDocument as Employees
	|	//
	|	// OtherRows
	|	//
	|	join ( select Employees.Employee as Employee, Employees.DateStart as DateStart, Employees.DateEnd as DateEnd, Employees.Line as Line
	|			from EmployeesDocument as Employees	) as OtherRows
	|	on OtherRows.Employee = Employees.Employee
	|	and OtherRows.Line <> Employees.Line
	|	and ( Employees.DateStart between OtherRows.DateStart and OtherRows.DateEnd
	|		or Employees.DateEnd between OtherRows.DateStart and OtherRows.DateEnd )
	|group by Employees.Employee
	|;
	|// #CollisionsHours
	|select Employees.Employee.Description as Employee, Employees.Line as Line, Hours.Day as Day
	|from EmployeesDocument as Employees
	|	//
	|	// Hours
	|	//
	|	join InformationRegister.Hours as Hours
	|	on Hours.Day between Employees.DateStart and Employees.DateEnd
	|	and Hours.Employee = Employees.Employee
	|	and Hours.Recorder <> &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure

Procedure sqlCalendar ( Env )
	
	s = "
	|// Timeline for next 3 years
	|select dateadd ( &DateStart, day, 11 * 11 * ( Rate1.Factor - 1 ) + 11 * ( Rate2.Factor - 1 ) + ( Rate3.Factor - 1 ) ) as Day
	|into Time
	|from (
	|	select 1 as Factor union all select 2 union all select 3 union all select 4 union all select 5 union all select 6
	|	union all select 7 union all select 8 union all select 9 union all select 10 union all select 11
	|	) as Rate1,
	|	(
	|	select 1 as Factor union all select 2 union all select 3 union all select 4 union all select 5 union all select 6
	|	union all select 7 union all select 8 union all select 9 union all select 10 union all select 11
	|	) as Rate2,
	|	(
	|	select 1 as Factor union all select 2 union all select 3 union all select 4 union all select 5 union all select 6
	|	union all select 7 union all select 8 union all select 9 union all select 10 union all select 11
	|	) as Rate3
	|where 11 * 11 * ( Rate1.Factor - 1 ) + 11 * ( Rate2.Factor - 1 ) + ( Rate3.Factor - 1 ) < 366 * 3
	|index by Day
	|;
	|// Periods for next 3 years
	|select dateadd ( &DateStart, month, 4 * 4 * ( Rate1.Factor - 1 ) + 4 * ( Rate2.Factor - 1 ) + ( Rate3.Factor - 1 ) ) as DateStart,
	|	endofperiod ( dateadd ( &DateStart, month, 4 * 4 * ( Rate1.Factor - 1 ) + 4 * ( Rate2.Factor - 1 ) + ( Rate3.Factor - 1 ) ), month ) as DateEnd
	|into Spans
	|from (
	|	select 1 as Factor union all select 2 union all select 3 union all select 4
	|	) as Rate1,
	|	(
	|	select 1 as Factor union all select 2 union all select 3 union all select 4
	|	) as Rate2,
	|	(
	|	select 1 as Factor union all select 2 union all select 3 union all select 4
	|	) as Rate3
	|where 4 * 4 * ( Rate1.Factor - 1 ) + 4 * ( Rate2.Factor - 1 ) + ( Rate3.Factor - 1 ) < 12 * 3
	|;
	|// Calendar
	|select Time.Day as Day
	|into Calendar
	|from Time as Time
	|where Time.Day between &DateStart and dateadd ( &DateEnd, day, -1 )
	|union all
	|select beginofperiod ( &DateEnd, day )
	|index by Day
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlPersonnel ( Env )
	
	s = "
	|// Employees
	|select Employees.Employee as Employee, &DateStart as Period, Employees.Hired as Hired
	|into Employees
	|from InformationRegister.Employees.SliceLast ( &DateStart,
	|	Employee in ( select Employee from Absence )
	|	 ) as Employees
	|where Employees.Hired
	|union
	|select Employees.Employee, Employees.Period, Employees.Hired
	|from InformationRegister.Employees as Employees
	|where Employees.Period > &DateStart and Employees.Period <= &DateEnd
	|and Employees.Employee in ( select Employee from Absence )
	|index by Employee
	|;
	|// Employment
	|select Employees.Employee as Employee, Employees.Period as DateStart,
	|	isnull ( Terminated.Period, &DateEnd ) as DateEnd
	|into Employment
	|from Employees as Employees
	|	//
	|	// Terminated
	|	//
	|	left join Employees as Terminated
	|	on Terminated.Employee = Employees.Employee
	|	and Terminated.Period > Employees.Period
	|	and not Terminated.Hired
	|where Employees.Hired
	|;
	|// Personnel
	|select &DateStart as Period, Personnel.Employee as Employee, Personnel.Department as Department,
	|	Personnel.Position as Position, Personnel.Schedule as Schedule, Personnel.Expenses as Expenses
	|into Personnel
	|from InformationRegister.Personnel.SliceLast ( &DateStart, Employee in ( select distinct Employee from Employees ) ) as Personnel
	|union
	|select Personnel.Period, Personnel.Employee, Personnel.Department, Personnel.Position, Personnel.Schedule, Personnel.Expenses
	|from InformationRegister.Personnel as Personnel
	|where Personnel.Period > &DateStart and Personnel.Period <= &DateEnd
	|and Personnel.Employee in ( select distinct Employee from Employees )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlLocation ( Env )
	
	s = "
	|// Changes
	|select Personnel.Employee as Employee, Personnel.Period as DateStart,
	|	min ( isnull ( dateadd ( Changes.Period, second, -1 ), Employment.DateEnd ) ) as DateEnd
	|into Changes
	|from Personnel as Personnel
	|	//
	|	// Employment
	|	//
	|	join Employment as Employment
	|	on Employment.Employee = Personnel.Employee
	|	//
	|	// Changes
	|	//
	|	left join Personnel as Changes
	|	on Changes.Period > Personnel.Period
	|	and Changes.Period < Employment.DateEnd
	|	and Changes.Employee = Personnel.Employee
	|	and ( Personnel.Department <> Changes.Department
	|		or Personnel.Position <> Changes.Position
	|		or Personnel.Schedule <> Changes.Schedule
	|		or Personnel.Expenses <> Changes.Expenses )
	|group by Personnel.Employee, Personnel.Period
	|;
	|// Location
	|select Personnel.Employee as Employee, Personnel.Schedule as Schedule, Changes.DateStart as DateStart, Changes.DateEnd as DateEnd
	|into ScheduledLocation
	|from Personnel as Personnel
	|	//
	|	// Changed
	|	//
	|	join Changes as Changes
	|	on Changes.Employee = Personnel.Employee
	|	and Personnel.Period between Changes.DateStart and Changes.DateEnd
	|	//
	|	// Filter by Employment
	|	//
	|	join Employment as Employment
	|	on Employment.Employee = Changes.Employee
	|	and Changes.DateStart between Employment.DateStart and Employment.DateEnd
	|	and Changes.DateEnd between Employment.DateStart and Employment.DateEnd
	|union all
	|select Personnel.Employee, Personnel.Schedule, beginofperiod ( dateadd ( &DateEnd, day, 1 ), day ), datetime ( 3999, 12, 31 )
	|from Personnel as Personnel
	|	//
	|	// LastLocation
	|	//
	|	join (
	|		select Personnel.Employee as Employee, max ( Personnel.Period ) as Period
	|		from Personnel as Personnel
	|		group by Personnel.Employee
	|	) as LastLocation
	|	on LastLocation.Employee = Personnel.Employee
	|	and LastLocation.Period = Personnel.Period
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlHours ( Env )
	
	s = "
	|// Hours
	|select Calendar.Day as Day, Absence.Employee as Employee, Schedules.Minutes as Minutes
	|into Hours
	|from Calendar as Calendar
	|	//
	|	// Location
	|	//
	|	join ScheduledLocation as Location
	|	on Calendar.Day between Location.DateStart and Location.DateEnd
	|	//
	|	// Absence
	|	//
	|	join Absence as Absence
	|	on Calendar.Day between Absence.DateStart and Absence.DateEnd
	|	and Absence.Employee = Location.Employee
	|	//
	|	// Schedule
	|	//
	|	join InformationRegister.Schedules as Schedules
	|	on Schedules.Schedule = Location.Schedule
	|	and Schedules.Day = Calendar.Day
	|	and Schedules.Minutes > 0
	|where Absence.Employee is not null
	|index by Calendar.Day, Absence.Employee
	|;
	|// AllDays
	|select distinct Calendar.Day as Day, Absence.Employee as Employee
	|into AllDays
	|from Calendar as Calendar
	|	//
	|	// Absence
	|	//
	|	left join Absence as Absence
	|	on Calendar.Day between Absence.DateStart and Absence.DateEnd
	|where Absence.Employee is not null
	|index by Calendar.Day, Absence.Employee
	|;
	|// #MissedHours
	|select AllDays.Day as Day, AllDays.Employee as Employee
	|from AllDays as AllDays
	|where ( AllDays.Day, AllDays.Employee ) not in ( select Day, Employee from Hours )
	|;
	|// #Hours
	|select Hours.Day as Day, Hours.Employee as Employee, Hours.Minutes as Minutes, value ( Enum.Time.Absence ) as Time
	|from Hours as Hours
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )

	q = Env.Q;
	fields = Env.Fields;
	q.SetParameter ( "DateStart", fields.DateStart );
	q.SetParameter ( "DateEnd", fields.DateEnd );
	SQL.Perform ( Env );

EndProcedure

Function checkCollisions ( Env ) 

	return checkCollisionsRows ( Env ) 
	and checkCollisionsHours ( Env );

EndFunction

Function checkCollisionsRows ( Env ) 

	table = Env.CollisionsRows;
	if ( table.Count () = 0 ) then
		return true;
	endif;
	p = new Structure ( "Line, Employee" );
	for each row in table do
		FillPropertyValues ( p, row );
		Output.EmployeePeriodErrorRows ( p );
	enddo;
	return false;

EndFunction

Function checkCollisionsHours ( Env ) 

	hours = Env.CollisionsHours;
	if ( hours.Count () = 0 ) then
		return true;
	endif;
	employees = hours.Copy ( , "Employee, Line" );
	employees.GroupBy ( "Employee, Line" );
	filter = new Structure ( "Employee, Line" );
	p = new Structure ( "Employee, Line, Days" );
	for each row in employees do
		FillPropertyValues ( p, row );
		FillPropertyValues ( filter, row );
		p.Days = getDays ( hours.FindRows ( filter ) );
		Output.EmployeePeriodErrorHours ( p );
	enddo;
	return false;

EndFunction

Function getDays ( HoursRows )

	days = new Array ();
	for each row in HoursRows do
		days.Add ( Format ( row.Day, "DLF=D" ) );
	enddo;
	return StrConcat ( days, ", " );

EndFunction

Function checkHours ( Env ) 

	hours = Env.MissedHours;
	if ( hours.Count () = 0 ) then
		return true;
	endif;
	employees = hours.UnloadColumn ( "Employee" );
	Collections.Group ( employees );
	filter = new Structure ( "Employee" );
	p = new Structure ( "Employee, Days" );
	for each employee in employees do
		p.Employee = employee;
		filter.Employee = employee;
		p.Days = getDays ( hours.FindRows ( filter ) );
		Output.MissedHours ( p );
	enddo;
	return false;

EndFunction

Procedure makeHours ( Env )

	recordset = Env.Registers.Hours;
	for each row in Env.Hours do
		movement = recordset.Add ();
		movement.Employee = row.Employee;
		movement.Day = row.Day;
		movement.Time = row.Time;
		movement.Minutes = row.Minutes;
	enddo;
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Hours.Write = true;
	
EndProcedure

#endregion

#endif