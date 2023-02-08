#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Realtime;
var Env;
var IsPosting;

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	setProperties ( WriteMode );
	
EndProcedure

Procedure setProperties ( WriteMode )
	
	Realtime = Forms.RealtimePosting ( ThisObject );
	IsPosting = ( WriteMode = DocumentWriteMode.Posting );
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( IsPosting
		and not checkCollisions () ) then
		Cancel = true;
	endif;
	
EndProcedure

Function checkCollisions () 

	getData ();
	return checkCollisionsRows () 
	and checkCollisionsHours ();

EndFunction

Procedure getData ()

	SQL.Init ( Env );
	sqlCollisions ();
	Env.Q.SetParameter ( "Ref", Ref );
	SQL.Perform ( Env );

EndProcedure

Procedure sqlCollisions () 

	s = "
	|// Employees
	|select Employees.Employee as Employee, Employees.LineNumber as Line, Employees.Day as Day
	|into Employees
	|from Document.Deviation.Employees as Employees
	|where Employees.Ref = &Ref
	|index by Employees.Employee, Employees.LineNumber, Employees.Day
	|;
	|// #CollisionsRows
	|select Employees.Employee as Employee, min ( Employees.Line ) as Line, Employees.Day as Day
	|from Employees as Employees
	|	//
	|	//	OtherRows
	|	//
	|	join Employees as OtherRows
	|	on OtherRows.Employee = Employees.Employee
	|   and OtherRows.Day = Employees.Day
	|	and OtherRows.Line <> Employees.Line
	|group by Employees.Employee, Employees.Day
	|;
	|// #CollisionsHours
	|select Employees.Employee as Employee, Employees.Line as Line, Employees.Day as Day
	|from Employees as Employees
	|	//
	|	// Hours
	|	//
	|	join InformationRegister.Hours as Hours
	|	on Hours.Day = Employees.Day
	|	and Hours.Employee = Employees.Employee
	|	and Hours.Recorder <> &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure

Function checkCollisionsRows () 

	table = Env.CollisionsRows;
	if ( table.Count () = 0 ) then
		return true;
	endif;
	p = new Structure ( "Employee, Line" );
	for each row in table do
		FillPropertyValues ( p, row );
		Output.EmployeePeriodErrorRows ( p );
	enddo;
	return false;

EndFunction

Function checkCollisionsHours () 

	table = Env.CollisionsHours;
	if ( table.Count () = 0 ) then
		return true;
	endif;
	filter = new Structure ( "Employee, Line" );
	p = new Structure ( "Employee, Line, Days" );
	for each row in getEmployees ( table ) do
		setParams ( p, row, getDays ( table, row, filter ) );
		Output.EmployeePeriodErrorHours ( p );
	enddo;
	return false;

EndFunction

Function getEmployees ( Table ) 

	tableEmployees = Table.Copy ( , "Employee, Line" );
	tableEmployees.GroupBy ( "Employee, Line" );
	return tableEmployees;

EndFunction

Procedure setParams ( Params, Row, Days ) 

	FillPropertyValues ( Params, Row );
	Params.Days = Days;

EndProcedure

Function getDays ( Table, Row, Filter )

	FillPropertyValues ( Filter, Row );
	days = new Array ();
	for each row in Table.FindRows ( Filter ) do
		days.Add ( Format ( row.Day, "DLF=D" ) );
	enddo;
	return StrConcat ( days, ", " );

EndFunction

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	env.Realtime = Realtime;
	Cancel = not Documents.Deviation.Post ( env );
	
EndProcedure


#endif