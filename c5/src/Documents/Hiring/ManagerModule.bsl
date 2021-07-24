#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Hiring.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	if ( not allNew ( Env ) ) then
		return false;
	endif; 
	makeEmployees ( Env );
	makeRates ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlHired ( Env );
	sqlEmployees ( Env );
	sqlRates ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlHired ( Env )
	
	s = "
	|// Personnel
	|select Personnel.Employee as Employee, max ( Personnel.Period ) as Period
	|into Personnel
	|from InformationRegister.Employees as Personnel
	|	//
	|	// Personnel
	|	//
	|	join Document.Hiring.Employees as Employees
	|	on Employees.Employee = Personnel.Employee
	|	and Employees.DateStart >= Personnel.Period
	|	and Employees.Ref = &Ref
	|where Personnel.Recorder <> &Ref
	|group by Personnel.Employee
	|index by Employee
	|;
	|// #Hired
	|select Employees.LineNumber as LN, Employees.Employee as Employee
	|from Document.Hiring.Employees as Employees
	|	//
	|	// Personnel
	|	//
	|	join Personnel as Personnel
	|	on Personnel.Employee = Personnel.Employee
	|	//
	|	// Statuses
	|	//
	|	join InformationRegister.Employees as Statuses
	|	on Statuses.Employee = Personnel.Employee
	|	and Statuses.Period = Personnel.Period
	|	and Statuses.Hired
	|where Employees.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlEmployees ( Env )
	
	s = "
	|// #Employees
	|select Employees.DateEnd as DateEnd, Employees.DateStart as DateStart, Employees.Department as Department,
	|	Employees.Employee as Employee, Employees.Position as Position, Employees.Schedule as Schedule,
	|	Employees.Expenses as Expenses, Employees.Employment as Employment
	|from Document.Hiring.Employees as Employees
	|where Employees.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlRates ( Env )
	
	s = "
	|// #Rates
	|select Employees.DateStart as DateStart, Employees.Employee as Employee, Employees.Compensation as Compensation,
	|	Employees.Rate as Rate, Employees.Currency as Currency
	|from Document.Hiring.Employees as Employees
	|where Employees.Ref = &Ref
	|union all
	|select Employees.DateStart, Additions.Employee, Additions.Compensation, Additions.Rate, Additions.Currency
	|from Document.Hiring.Additions as Additions
	|	//
	|	// Employees
	|	//
	|	join Document.Hiring.Employees as Employees
	|	on Employees.Employee = Additions.Employee
	|where Additions.Ref = &Ref
	|;
	|// #InHand
	|select Employees.DateStart as DateStart, Employees.Employee as Employee, Employees.InHand as Yes
	|from Document.Hiring.Employees as Employees
	|where Employees.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function allNew ( Env )
	
	errors = Env.Hired;
	if ( errors.Count () = 0 ) then
		return true;
	endif; 
	ref = Env.Ref;
	for each row in errors do
		Output.EmployeeAlreadyHired ( , Output.Row ( "Employees", row.LN, "Employee" ), ref );
	enddo; 
	return false;
	
EndFunction 

Procedure makeEmployees ( Env )
	
	registers = Env.Registers;
	employees = registers.Employees;
	personnel = registers.Personnel;
	employment = registers.Employment;
	emptyDate = Date ( 1, 1, 1 );
	for each row in Env.Employees do
		dateStart = row.DateStart;
		dateEnd = row.DateEnd;
		employee = row.Employee;
		record = employees.Add ();
		record.Period = dateStart;
		record.Employee = employee;
		record.Hired = true;
		if ( dateEnd <> emptyDate ) then
			record = employees.Add ();
			record.Period = EndOfDay ( dateEnd );
			record.Employee = employee;
			record.Hired = false;
		endif; 
		record = personnel.Add ();
		record.Period = dateStart;
		record.Employee = employee;
		record.Department = row.Department;
		record.Position = row.Position;
		record.Schedule = row.Schedule;
		record.Expenses = row.Expenses;
		record = employment.Add ();
		record.Employee = employee;
		record.Employment = row.Employment;
	enddo; 
	
EndProcedure 

Procedure makeRates ( Env )
	
	register = Env.Registers.EmployeeRates;
	for each row in Env.Rates do
		record = register.Add ();
		record.Period = row.DateStart;
		record.Employee = row.Employee;
		record.Compensation = row.Compensation;
		record.Currency = row.Currency;
		record.Rate = row.Rate;
		record.Actual = true;
	enddo; 
	register = Env.Registers.SalaryInHand;
	for each row in Env.InHand do
		record = register.Add ();
		record.Period = row.DateStart;
		record.Employee = row.Employee;
		record.Yes = row.Yes;
	enddo; 
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Employees.Write = true;
	registers.Personnel.Write = true;
	registers.EmployeeRates.Write = true;
	registers.SalaryInHand.Write = true;
	registers.Employment.Write = true;
	
EndProcedure

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	putHeader ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	sqlData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlData ( Env )
	
	s = "
	|// @Fields
	|select Document.Company.FullDescription as Company
	|from Document.Hiring as Document
	|where Document.Ref = &Ref
	|;
	|// #Employees
	|select presentation ( Employees.Employee ) as Employee, presentation ( Employees.Department ) as Department, Employees.DateStart as DateStart,
	|	presentation ( Employees.Position ) as Position, Employees.Rate as Rate, presentation ( Employees.Currency ) as Currency, 
	|	Employees.Employee as EmployeeRef, Employees.Employee.Code as Code
	|from Document.Hiring.Employees as Employees
	|where Employees.Ref = &Ref
	|order by Employees.LineNumber
	|;
	|// #Additions
	|select Additions.Employee as EmployeeRef, Additions.Rate as Rate, presentation ( Additions.Currency ) as Currency,
	|	presentation ( Additions.Compensation ) as Compensation
	|from Document.Hiring.Additions as Additions
	|where Additions.Ref = &Ref
	|order by Additions.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putHeader ( Params, Env )
	
	company = Env.Fields.Company;
	t = Env.T;
	area = t.GetArea ( "Header" );
	p = area.Parameters;
	areaBack = t.GetArea ( "Back" );
	pBack = areaBack.Parameters;
	tabDoc = Params.TabDoc;
	additions = Env.Additions;
	additions.Indexes.Add ( "EmployeeRef" );
	filter = new Structure ( "EmployeeRef" );
	for each row in Env.Employees do
		p.Fill ( row );
		p.Company = company;
		p.Size = Conversion.NumberToMoney ( row.Rate, row.Currency );
		filter.EmployeeRef = row.EmployeeRef;
		p.AditionalCompensation = aditionalCompensation ( additions, filter );
		tabDoc.Put ( area );
		tabDoc.PutHorizontalPageBreak ();
		pBack.Employee = row.Employee;
		tabDoc.Put ( areaBack );
		tabDoc.PutHorizontalPageBreak ();
	enddo;
	
EndProcedure

Function aditionalCompensation ( Table, Filter ) 

	s = "";
	for each row in Table.FindRows ( Filter ) do
		s = s + row.Compensation + " " + Conversion.NumberToMoney ( row.Rate, row.Currency ) + " ";
	enddo;
	return s;

EndFunction

#endregion

#endif