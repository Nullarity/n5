#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print ( Params, Env ) export
	
	setContext ( Params, Env );
	if ( Params.Key = Enums.PrintForms.Paysheet ) then
		printPaysheet ( Params, Env );	
	else
		printStatement ( Params, Env );	
	endif;
	return true;
	
EndFunction

Procedure setContext ( Params, Env )
	
	type = TypeOf ( Params.Reference );
	Env.Insert ( "IsPayEmployees", type = Type ( "DocumentRef.PayEmployees" ) );
	Env.Insert ( "Document", Metadata.FindByType ( type ).Name );
	
EndProcedure

Procedure printPaysheet ( Params, Env )
	
	setPageSettings ( Params );
	getPaysheetPrintData ( Params, Env );
	putPaysheetTitle ( Params, Env );
	putPaysheetHeader ( Params, Env );
	putPaysheetTable ( Params, Env );
	putPaysheetFooter ( Params, Env );
	
EndProcedure

Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Landscape;
	tabDoc.FitToPage = true;
	
EndProcedure 
 
Procedure getPaysheetPrintData ( Params, Env )
	
	sqlPrintFields ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	sqlPaysheetPrintData ( Env );
	Env.Q.SetParameter ( "Period", Env.Fields.Date );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlPrintFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Company.FullDescription as Company, 
	|	Documents.Number as Number, Documents.Date as Date
	|from Document." + Env.Document + " as Documents 
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlPaysheetPrintData ( Env )
	
	document = Env.Document;
	s = "
	|// #Compensations
	|select Compensations.Employee as Employee, Compensations.Compensation as Compensation,
	|	sum ( Compensations.Amount ) as Amount
	|from Document." + document + ".Compensations as Compensations
	|where Compensations.Ref = &Ref
	|group by Compensations.Employee, Compensations.Compensation
	|;
	|// #Taxes
	|select Taxes.Employee as Employee, Taxes.Tax as Tax, 
	|	sum ( Taxes.Result ) as Amount
	|from Document." + document + ".Taxes as Taxes
	|where Taxes.Ref = &Ref
	|group by Taxes.Employee, Taxes.Tax
	|;
	|// #Totals
	|select Totals.Employee as Employee, sum ( Totals.Amount ) as Amount,
	|	sum ( Totals.Net ) as Net, sum ( Totals.Amount - Totals.Net ) as Retained
	|from Document." + document + ".Totals as Totals
	|where Totals.Ref = &Ref
	|group by Totals.Employee
	|;";
	if ( Env.IsPayEmployees ) then
		s = s + "
		|// #Personnel
		|select Compensations.Employee as EmployeeRef, Compensations.Employee.Description as Employee, 
		|	Personnel.Position.Description as Position,
		|	Employees.Code as Code
		|from Document.PayEmployees.Compensations as Compensations
		|	//
		|	// Employees
		|	//
		|	join Catalog.Employees as Employees
		|	on Employees.Individual = Compensations.Employee
		|	//
		|	// Personnel
		|	//
		|	join InformationRegister.Personnel.SliceLast ( &Period ) as Personnel
		|	on Personnel.Employee = Employees.Ref
		|where Compensations.Ref = &Ref
		|order by Compensations.LineNumber
		|";
	else
		s = s + "
		|// #Personnel
		|select Compensations.Individual as EmployeeRef, Compensations.Individual.Description as Employee, 
		|	Personnel.Position.Description as Position, Compensations.Employee.Code as Code
		|from Document.PayAdvances.Compensations as Compensations
		|	//
		|	// Personnel
		|	//
		|	join InformationRegister.Personnel.SliceLast ( &Period ) as Personnel
		|	on Personnel.Employee = Compensations.Employee
		|where Compensations.Ref = &Ref
		|order by Compensations.LineNumber
		|";
	endif;
	s = s + "
	|;
	|// #CompensationsList
	|select Compensations.Compensation as Compensation, sum ( Compensations.Amount ) as Amount 
	|from Document." + document + ".Compensations as Compensations
	|where Compensations.Ref = &Ref
	|group by Compensations.Compensation
	|;
	|// #TaxesList
	|select Taxes.Tax as Tax, sum ( Taxes.Result ) as Amount 
	|from Document." + document + ".Taxes as Taxes
	|where Taxes.Ref = &Ref
	|group by Taxes.Tax";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putPaysheetTitle ( Params, Env )
	
	area = Env.T.GetArea ( ? ( Env.IsPayEmployees, "Title", "TitleAdvances" ) );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.Date = Format ( Env.Fields.Date, "DLF=D" );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putPaysheetHeader ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putPaysheetTable ( Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "TableHeader|Employees" );
	tabDoc.Put ( area );
	joinHeaderCompensations ( Params, Env );
	joinHeaderTaxes ( Params, Env );
	joinHeaderTotals ( Params, Env );
	area = t.GetArea ( "TableRow|Employees" );
	p = area.Parameters;
	lineNumber = 1;
	for each row in Env.Personnel do
		p.Fill ( row );
		p.LineNumber = lineNumber;
		tabDoc.Put ( area );
		employee = row.EmployeeRef;
		joinRowCompensations ( employee, Params, Env );
		joinRowTaxes ( employee, Params, Env );
		joinRowTotals ( employee, Params, Env );
		lineNumber = lineNumber + 1;
	enddo;
	area = t.GetArea ( "TableFooter|Employees" );
	tabDoc.Put ( area );
	joinFooterCompensations ( Params, Env );
	joinFooterTaxes ( Params, Env );
	joinFooterTotals ( Params, Env );
	
EndProcedure

Procedure joinHeaderCompensations ( Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "TableHeader|Compensations" );
	p = area.Parameters;
	for each row in Env.CompensationsList do
		p.Compensation = row.Compensation;
		tabDoc.Join ( area );	
	enddo;
	area = t.GetArea ( "TableHeader|CompensationsTotal" );
	tabDoc.Join ( area );	
	
EndProcedure

Procedure joinHeaderTaxes ( Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "TableHeader|Taxes" );
	p = area.Parameters;
	for each row in Env.TaxesList do
		p.Tax = row.Tax;
		tabDoc.Join ( area );	
	enddo;
	area = t.GetArea ( "TableHeader|TaxesTotal" );
	tabDoc.Join ( area );	
	
EndProcedure

Procedure joinHeaderTotals ( Params, Env )
	
	area = Env.T.GetArea ( "TableHeader|Totals" );
	Params.TabDoc.Join ( area );	
	
EndProcedure

Procedure joinRowCompensations ( Employee, Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	compensations = Env.Compensations;
	totals = Env.Totals.Find ( Employee, "Employee" );
	filter = new Structure ( "Employee, Compensation" );
	filter.Employee = Employee; 
	for each row in Env.CompensationsList do
		area = t.GetArea ( "TableRow|Compensations" );
		filter.Compensation = row.Compensation; 
		rows = compensations.FindRows ( filter );
		if ( rows.Count () > 0 ) then
			area.Parameters.Fill ( rows [ 0 ] );
		endif;
		tabDoc.Join ( area );	
	enddo;
	area = t.GetArea ( "TableRow|CompensationsTotal" );
	area.Parameters.Amount = totals.Amount;
	tabDoc.Join ( area );
	
EndProcedure

Procedure joinRowTaxes ( Employee, Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	taxes = Env.Taxes;
	totals = Env.Totals.Find ( Employee, "Employee" );
	filter = new Structure ( "Employee, Tax" );
	filter.Employee = Employee;
	for each row in Env.TaxesList do
		area = t.GetArea ( "TableRow|Taxes" );
		filter.Tax = row.Tax; 
		rows = taxes.FindRows ( filter );
		if ( rows.Count () > 0 ) then
			area.Parameters.Fill ( rows [ 0 ] );
		endif;
		tabDoc.Join ( area );	
	enddo;
	area = t.GetArea ( "TableRow|TaxesTotal" );
	area.Parameters.Amount = totals.Retained;
	tabDoc.Join ( area );
	
EndProcedure

Procedure joinRowTotals ( Employee, Params, Env )
	
	totals = Env.Totals.Find ( Employee, "Employee" );
	area = Env.T.GetArea ( "TableRow|Totals" );
	area.Parameters.Amount = totals.Net;
	Params.TabDoc.Join ( area );	
	
EndProcedure

Procedure joinFooterCompensations ( Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "TableFooter|Compensations" );
	p = area.Parameters;
	compensations = Env.CompensationsList;
	for each row in compensations do
		p.Amount = row.Amount;
		tabDoc.Join ( area );	
	enddo;
	area = t.GetArea ( "TableFooter|CompensationsTotal" );
	area.Parameters.Amount = compensations.Total ( "Amount" );
	tabDoc.Join ( area );
	
EndProcedure

Procedure joinFooterTaxes ( Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "TableFooter|Taxes" );
	p = area.Parameters;
	taxes = Env.TaxesList;
	for each row in taxes do
		p.Amount = row.Amount;
		tabDoc.Join ( area );	
	enddo;
	area = t.GetArea ( "TableFooter|TaxesTotal" );
	area.Parameters.Amount = taxes.Total ( "Amount" );
	tabDoc.Join ( area );
	
EndProcedure

Procedure joinFooterTotals ( Params, Env )
	
	area = Env.T.GetArea ( "TableFooter|Totals" );
	area.Parameters.Amount = Env.Totals.Total ( "Net" );
	Params.TabDoc.Join ( area );
	
EndProcedure

Procedure putPaysheetFooter ( Params, Env )
	
	area = Env.T.GetArea ( "Footer" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );		
	
EndProcedure

Procedure printStatement ( Params, Env )
	
	setPageSettings ( Params );
	getStatementPrintData ( Params, Env );
	putStatementHeader ( Params, Env );
	putStatementTable ( Params, Env );
	putStatementFooter ( Params, Env );	
	
EndProcedure

Procedure getStatementPrintData ( Params, Env )
	
	sqlPrintFields ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	sqlStatementPrintData ( Env );
	Env.Q.SetParameter ( "Period", Env.Fields.Date );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlStatementPrintData ( Env )
	
	if ( Env.IsPayEmployees ) then
		s = "
		|// #Totals
		|select Totals.LineNumber as LineNumber, Totals.Employee.Description as Employee, 
		|	Personnel.Position.Description as Position, Employees.Code as Code, Totals.Net as Amount
		|from Document.PayEmployees.Totals as Totals
		|	//
		|	// Employees
		|	//
		|	join Catalog.Employees as Employees
		|	on Employees.Individual = Totals.Employee
		|	//
		|	// Personnel
		|	//
		|	join InformationRegister.Personnel.SliceLast ( &Period ) as Personnel
		|	on Personnel.Employee = Employees.Ref
		|where Totals.Ref = &Ref
		|order by Totals.LineNumber
		|";
	else
		s = "
		|// #Totals
		|select Totals.LineNumber as LineNumber, Totals.Employee.Description as Employee, 
		|	Personnel.Position.Description as Position, Employees.Employee.Code as Code, Totals.Net as Amount
		|from Document.PayAdvances.Totals as Totals
		|	//
		|	// Employees
		|	//
		|	join (
		|		select Compensations.Employee as Employee, Compensations.Individual as Individual
		|		from Document.PayAdvances.Compensations as Compensations
		|			//
		|			// First employees
		|			//
		|			join (
		|				select min ( Compensations.LineNumber ) as Row, Compensations.Individual as Individual
		|				from Document.PayAdvances.Compensations as Compensations
		|				where Compensations.Ref = &Ref
		|				group by Compensations.Individual
		|			) as Employees
		|			on Employees.Row = Compensations.LineNumber
		|		where Compensations.Ref = &Ref
		|	) as Employees
		|	on Employees.Individual = Totals.Employee
		|	//
		|	// Personnel
		|	//
		|	join InformationRegister.Personnel.SliceLast ( &Period ) as Personnel
		|	on Personnel.Employee = Employees.Employee
		|where Totals.Ref = &Ref
		|order by Totals.LineNumber
		|";
	endif;
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putStatementHeader ( Params, Env )
	
	fields = Env.Fields;
	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	p.Fill ( fields );
	p.Date = Format ( fields.Date, "DLF=D" );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putStatementTable ( Params, Env )
	
	tabDoc = Params.TabDoc;
	area = Env.T.GetArea ( "TableRow" );
	p = area.Parameters;
	for each row in Env.Totals do
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo;
	
EndProcedure

Procedure putStatementFooter ( Params, Env )
	
	area = Env.T.GetArea ( "Footer" );
	area.Parameters.Amount = Env.Totals.Total ( "Amount" );
	Params.TabDoc.Put ( area );		
	
EndProcedure

#endif