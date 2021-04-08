#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.EmployeesTransfer.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	if ( not allHired ( Env ) ) then
		return false;
	endif; 
	makePersonnel ( Env );
	if ( not makeCompensations ( Env ) ) then
		return false;
	endif; 
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlTerminated ( Env );
	sqlLocationChanges ( Env );
	sqlCompensationChanges ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlTerminated ( Env )
	
	s = "
	|select Employees.Employee as Employee, Employees.Date ForDate, max ( Statuses.Period ) as Period
	|into LastChanges
	|from (
	|	select Employees.Employee as Employee, Employees.Date as Date
	|	from Document.EmployeesTransfer.Employees as Employees
	|	where Employees.Ref = &Ref
	|	union
	|	select Additions.Employee, Additions.Date
	|	from Document.EmployeesTransfer.Additions as Additions
	|	where Additions.Ref = &Ref
	|	) as Employees
	|	//
	|	// Statuses
	|	//
	|	join InformationRegister.Employees as Statuses
	|	on Statuses.Employee = Employees.Employee
	|	and Statuses.Period <= Employees.Date
	|group by Employees.Employee, Employees.Date
	|index by Employee
	|;
	|// #Terminated
	|select distinct Employees.LN as LN, Employees.Employee as Employee
	|from (
	|	select Employees.LineNumber as LN, Employees.Date as Date, Employees.Employee as Employee
	|	from Document.EmployeesTransfer.Employees as Employees
	|	where Employees.Ref = &Ref
	|	union
	|	select distinct Employees.LineNumber, Additions.Date, Additions.Employee
	|	from Document.EmployeesTransfer.Additions as Additions
	|		//
	|		// Employees
	|		//
	|		join Document.EmployeesTransfer.Employees as Employees
	|		on Employees.Ref = Additions.Ref
	|		and Employees.Employee = Additions.Employee
	|	where Additions.Ref = &Ref
	|	) as Employees
	|	//
	|	// Statuses
	|	//
	|	left join (
	|		select Statuses.Employee as Employee, LastChanges.ForDate as ForDate
	|		from InformationRegister.Employees as Statuses
	|			//
	|			// LastChanges
	|			//
	|			join LastChanges as LastChanges
	|			on LastChanges.Employee = Statuses.Employee
	|			and LastChanges.Period = Statuses.Period
	|		where Statuses.Hired
	|	) as Statuses
	|	on Statuses.Employee = Employees.Employee
	|	and Statuses.ForDate = Employees.Date
	|where Statuses.Employee is null
	|order by LN
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlLocationChanges ( Env )
	
	s = "
	|select Employees.Action as Action, Employees.Employee as Employee, Employees.Department as Department,
	|	Employees.Position as Position, Employees.Schedule as Schedule, Employees.Expenses as Expenses,
	|	Employees.Date as Date
	|into Employees
	|from Document.EmployeesTransfer.Employees as Employees
	|where Employees.Ref = &Ref
	|and Employees.Action <> value ( Enum.Changes.Nothing )
	|;
	|// #Employees
	|select Employees.Action as Action, Employees.Date as Date, Employees.Employee as Employee,
	|	Employees.Department as Department, Employees.Position as Position, Employees.Schedule as Schedule,
	|	Employees.Expenses as Expenses
	|from Employees as Employees
	|	//
	|	// Last
	|	//
	|	left join (
	|		select Personnel.Employee as Employee, Personnel.Department as Department, Personnel.Position as Position,
	|			Personnel.Schedule as Schedule, Personnel.Expenses as Expenses
	|		from InformationRegister.Personnel as Personnel
	|			//
	|			// LastChanges
	|			//
	|			join (
	|				select Personnel.Employee as Employee, max ( Personnel.Period ) as Period
	|				from InformationRegister.Personnel as Personnel
	|					//
	|					// Employees
	|					//
	|					join Employees as Employees
	|					on Employees.Employee = Personnel.Employee
	|					and Employees.Date > Personnel.Period
	|				group by Personnel.Employee
	|			) LastChanges
	|			on LastChanges.Employee = Personnel.Employee
	|			and LastChanges.Period = Personnel.Period
	|	) as Last
	|	on Last.Employee = Employees.Employee
	|where
	|	case
	|		when Employees.Department = Last.Department
	|		and Employees.Position = Last.Position
	|		and Employees.Schedule = Last.Schedule
	|		and Employees.Expenses = Last.Expenses
	|		then false
	|		else true
	|	end
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlCompensationChanges ( Env )
	
	s = "
	|select Compensations.Action as Action, Compensations.Employee as Employee, Compensations.Compensation as Compensation,
	|	Compensations.Date as Date, Compensations.Currency as Currency, Compensations.Rate as Rate
	|into Compensations
	|from Document.EmployeesTransfer.Employees as Compensations
	|where Compensations.Ref = &Ref
	|and Compensations.Action <> value ( Enum.Changes.Nothing )
	|union all
	|select Compensations.Action, Compensations.Employee, Compensations.Compensation, Compensations.Date,
	|	Compensations.Currency, Compensations.Rate
	|from Document.EmployeesTransfer.Additions as Compensations
	|where Compensations.Ref = &Ref
	|and Compensations.Action <> value ( Enum.Changes.Nothing )
	|index by Employee
	|;
	|// #Compensations
	|select Rows.LineNumber as LN, Compensations.Action as Action, Compensations.Employee as Employee,
	|	Compensations.Compensation as Compensation, Compensations.Date as Date, Compensations.Currency as Currency,
	|	Compensations.Rate as Rate, case when Last.Employee is null then false else true end as CompensationExists,
	|	case
	|		when ( Compensations.Action = value ( Enum.Changes.Add )
	|			and not Last.Employee is null ) then 1
	|		when ( Compensations.Action = value ( Enum.Changes.Change )
	|			and Compensations.Compensation = Last.Compensation
	|			and Compensations.Currency = Last.Currency
	|			and Compensations.Rate = Last.Rate ) then 1
	|		when ( Compensations.Action in ( value ( Enum.Changes.Change ), value ( Enum.Changes.Remove ) )
	|			and Last.Employee is null ) then 2
	|		else 0
	|	end as Situation
	|from Compensations as Compensations
	|	//
	|	// Last
	|	//
	|	left join (
	|		select Rates.Employee as Employee, Rates.Compensation as Compensation,
	|			Rates.Currency as Currency, Rates.Rate as Rate
	|		from InformationRegister.EmployeeRates as Rates
	|			//
	|			// LastChanges
	|			//
	|			join (
	|				select Rates.Employee as Employee, Rates.Compensation as Compensation, max ( Rates.Period ) as Period
	|				from InformationRegister.EmployeeRates as Rates
	|					//
	|					// Employees
	|					//
	|					join Compensations as Compensations
	|					on Compensations.Employee = Rates.Employee
	|					and Compensations.Compensation = Rates.Compensation
	|					and Compensations.Date > Rates.Period
	|				group by Rates.Employee, Rates.Compensation
	|			) LastChanges
	|			on LastChanges.Employee = Rates.Employee
	|			and LastChanges.Compensation = Rates.Compensation
	|			and LastChanges.Period = Rates.Period
	|	) as Last
	|	on Last.Employee = Compensations.Employee
	|	and Last.Compensation = Compensations.Compensation
	|	//
	|	// Rows
	|	//
	|	join Document.EmployeesTransfer.Employees as Rows
	|	on Rows.Employee = Compensations.Employee
	|	and Rows.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function allHired ( Env )
	
	errors = Env.Terminated;
	if ( errors.Count () = 0 ) then
		return true;
	endif; 
	ref = Env.Ref;
	msg = new Structure ( "Employee" );
	for each row in errors do
		msg.Employee = row.Employee;
		Output.EmployeeNotHired ( msg, Output.Row ( "Employees", row.LN, "Employee" ), ref );
	enddo; 
	return false;
	
EndFunction 

Procedure makePersonnel ( Env )
	
	personnel = Env.Registers.Personnel;
	for each row in Env.Employees do
		record = personnel.Add ();
		record.Period = row.Date;
		record.Employee = row.Employee;
		record.Department = row.Department;
		record.Position = row.Position;
		record.Schedule = row.Schedule;
		record.Expenses = row.Expenses;
	enddo; 
	
EndProcedure

Function makeCompensations ( Env )
	
	error = false;
	ref = Env.Ref;
	rates = Env.Registers.EmployeeRates;
	employees = Env.Employees;
	for each row in Env.Compensations do
		employee = Row.Employee;
		compensation = Row.Compensation;
		situation = row.Situation;
		if ( situation > 0 ) then
			hrChanges = ( situation = 1 )
			and ( employees.Find ( employee, "Employee" ) <> undefined );
			if ( hrChanges ) then
				continue;
			else
				error = true;
				msg = new Structure ( "Employee, Compensation", employee, compensation );
				path = Output.Row ( "Employees", row.LN, "Employee" );
				if ( situation = 1 ) then
					Output.EmployeeTransferError1 ( msg, path, ref );
				else
					Output.EmployeeTransferError2 ( msg, path, ref );
				endif; 
			endif; 
		endif; 
		if ( error ) then
			continue;
		endif; 
		record = rates.Add ();
		record.Period = row.Date;
		record.Employee = employee;
		record.Compensation = compensation;
		record.Currency = row.Currency;
		record.Rate = row.Rate;
		record.Actual = row.Action <> Enums.Changes.Remove;
	enddo; 
	return not error;
	
EndFunction

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Personnel.Write = true;
	registers.EmployeeRates.Write = true;
	
EndProcedure

#endregion

#endif