#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Termination.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	if ( not allHired ( Env ) ) then
		return false;
	endif; 
	makeEmployees ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlTerminated ( Env );
	sqlEmployees ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlTerminated ( Env )
	
	s = "
	|select Employees.Employee as Employee, max ( Statuses.Period ) as Period
	|into LastChanges
	|from Document.Termination.Employees as Employees
	|	//
	|	// Statuses
	|	//
	|	join InformationRegister.Employees as Statuses
	|	on Statuses.Employee = Employees.Employee
	|	and Statuses.Period <= Employees.Date
	|where Employees.Ref = &Ref
	|group by Employees.Employee
	|index by Employee
	|;
	|// #Terminated
	|select Employees.LineNumber as LN, Employees.Employee as Employee
	|from Document.Termination.Employees as Employees
	|	//
	|	// Statuses
	|	//
	|	left join (
	|		select Statuses.Employee as Employee
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
	|where Employees.Ref = &Ref
	|and Statuses.Employee is null
	|order by LN
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlEmployees ( Env )
	
	s = "
	|// #Employees
	|select Employees.Employee as Employee, Employees.Date as Date
	|from Document.Termination.Employees as Employees
	|where Employees.Ref = &Ref
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
		Output.EmployeeAlreadyTerminated ( msg, Output.Row ( "Employees", row.LN, "Employee" ), ref );
	enddo; 
	return false;
	
EndFunction 

Procedure makeEmployees ( Env )
	
	employees = Env.Registers.Employees;
	for each row in Env.Employees do
		record = employees.Add ();
		record.Period = row.Date;
		record.Employee = row.Employee;
		record.Hired = false;
	enddo; 
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Employees.Write = true;
	
EndProcedure

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	putPages ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	tabDoc.PerPage = 1;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	sqlFields ( Env );
	getFields ( Env, Params );
	sqlPrintData ( Env );
	Env.Q.SetParameter ( "Date", Env.Fields.Date );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Document.Number as Number, Document.Company.FullDescription as Company, Document.Date as Date
	|from Document.Termination as Document
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env, Params ) 

	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );

EndProcedure

Procedure sqlPrintData ( Env )
	
	s = "
	|// Employees
	|select distinct Employees.Employee as Employee, Employees.Date as Date, Employees.Reason as Reason
	|into Employees
	|from Document.Termination.Employees as Employees
	|where Employees.Ref = &Ref
	|index by Employees.Employee
	|;
	|// #Employees
	|select presentation ( Employees.Employee ) as Employee, Employees.Date as Date, Employees.Employee as EmployeeRef
	|from Employees as Employees
	|;
	|// #Compensations
	|select presentation ( Personnel.Department ) as Department, Employees.Employee as Employee, presentation ( Personnel.Position ) as Position, 
	|	presentation ( Employees.Reason ) as Reason, Rates.Rate as Rate, presentation ( Rates.Currency ) as Currency, Employees.Employee.Code as Code, 
	|	case when Compensation.Method in ( value ( Enum.Calculations.HourlyRate ), value ( Enum.Calculations.MonthlyRate ) ) then 1	else 2 end as Sort,
	|	presentation ( Rates.Compensation ) as Compensation
	|from Employees as Employees
	|	//
	|	// Personnel
	|	//
	|	left join InformationRegister.Personnel.SliceLast ( &Date, Employee in ( select Employee from Employees ) ) as Personnel
	|	on Personnel.Employee = Employees.Employee
	|	//
	|	// EmployeeRates
	|	//
	|	left join InformationRegister.EmployeeRates.SliceLast ( &Date, Employee in ( select Employee from Employees )
	|		and Actual ) as Rates
	|	on Rates.Employee = Employees.Employee
	|order by case when Compensation.Method in ( value ( Enum.Calculations.HourlyRate ), value ( Enum.Calculations.MonthlyRate ) ) then 1 else 2 end
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putPages ( Params, Env ) 

	for each row in Env.Employees do
		putHeader ( Params, Env, row );
		putRow ( Params, Env, row.EmployeeRef );
		putFooter ( Params, Env, row )
	enddo;

EndProcedure

Procedure putHeader ( Params, Env, Row )
	
	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	p.Fill ( Row );
	fields = Env.Fields;
	p.Company = fields.Company;
	p.Number = fields.Number;
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putRow ( Params, Env, Employee )
	
	area = Env.T.GetArea ( "Row" );
	p = area.Parameters;
	tabDoc = Params.TabDoc;
	filter = new Structure ( "Employee", Employee );
	for each row in Env.Compensations.FindRows ( filter ) do
		p.Fill ( row );
		p.Size = Conversion.NumberToMoney ( row.Rate, row.Currency );
		tabDoc.Put ( area );
	enddo;
	
EndProcedure

Procedure putFooter ( Params, Env, Row )
	
	area = Env.T.GetArea ( "Footer" );
	p = area.Parameters;
	p.Fill ( Row );
	tabDoc = Params.TabDoc;
	tabDoc.Put ( area );
	tabDoc.PutHorizontalPageBreak ();
	
EndProcedure

#endregion

#endif
