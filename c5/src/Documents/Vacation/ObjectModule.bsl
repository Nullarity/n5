#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not HiringForm.CheckDoubles ( ThisObject ) ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( alreadyOnVacation () ) then
		Cancel = true;	
	endif;	
	
EndProcedure

Function alreadyOnVacation ()
	
	q = new Query;
	q.Text = "
	|select &Ref as Ref, Employees.Employee as Employee,
	|	Employees.DateStart as DateStart, Employees.DateEnd as DateEnd
	|into Employees
	|from &Employees as Employees
	|;
	|select Vacations.Ref as Ref, Vacations.Employee as Employee	
	|from Employees as Employees
	|	//
	|	// Vacations
	|	//
	|	join Document.Vacation.Employees as Vacations
	|	on Vacations.Ref <> Employees.Ref
	|	and Vacations.Ref.Posted
	|	and Vacations.Employee = Employees.Employee
	|	and ( Vacations.DateStart between Employees.DateStart and Employees.DateEnd
	|		or Vacations.DateEnd between Employees.DateStart and Employees.DateEnd
	|		or Employees.DateStart between Vacations.DateStart and Vacations.DateEnd
	|		or Employees.DateEnd between Vacations.DateStart and Vacations.DateEnd )
	|";
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Employees", Employees );
	result = q.Execute ().Unload ();
	error = false;
	for each row in result do
		p = new Structure ( "Ref, Employee", row.Ref, row.Employee );
		Output.EmployeeAlreadyOnVacation ( p, , row.Ref );
		error = true;
	enddo;
	return error;
	
EndFunction

#endif