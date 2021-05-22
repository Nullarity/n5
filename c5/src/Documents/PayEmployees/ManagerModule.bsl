#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.PayEmployees.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	commitTaxes ( Env );
	commitNet ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	sqlCompensations ( Env );
	sqlTaxes ( Env );
	sqlTotals ( Env );
	getFields ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.DepositLiabilities as DepositLiabilities,
	|	Documents.EmployeesDebt as EmployeesDebt, Documents.EmployerDebt as EmployerDebt, Documents.Method as Method,
	|	Documents.BankAccount as BankAccount, Documents.CashFlow as CashFlow, Documents.Location as Location,
	|	Documents.Account as Account
	|from Document.PayEmployees as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlCompensations ( Env )
	
	s = "
	|// #Compensations
	|select Compensations.LineNumber as LN, Compensations.Account as AccountDr, Compensations.Amount as Amount,
	|	Compensations.Compensation as Compensation, Compensations.Employee as Employee,
	|	case when IncomeTax.Compensation is null then false else true end as IncomeTax
	|from Document.PayEmployees.Compensations as Compensations
	|	//
	|	// IncomeTax
	|	//
	|	left join (
	|		select distinct Taxes.Employee as Employee, Compensations.CalculationType as Compensation
	|		from Document.PayEmployees.Taxes as Taxes
	|			//
	|			// Compensations
	|			//
	|			join ChartOfcalculationTypes.Taxes.BaseCalculationTypes as Compensations
	|			on Compensations.Ref = Taxes.Tax
	|		where Taxes.Ref = &Ref
	|		and Taxes.Tax.Method in (
	|			value ( Enum.Calculations.IncomeTax ),
	|			value ( Enum.Calculations.FixedIncomeTax )
	|		)
	|	) as IncomeTax
	|	on IncomeTax.Employee = Compensations.Employee
	|	and IncomeTax.Compensation = Compensations.Compensation
	|where Compensations.Ref = &Ref
	|order by LN
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlTaxes ( Env )
	
	s = "
	|// #Taxes
	|select Taxes.Account as AccountCr, Taxes.Compensation as Compensation, Taxes.Employee as Employee,
	|	Taxes.Result as Result, Taxes.Base as Amount, Taxes.Tax.Method as Method,
	|	Taxes.Tax.Description as Description
	|from Document.PayEmployees.Taxes as Taxes
	|where Taxes.Ref = &Ref
	|and not Taxes.Tax.Method in (
	|	value ( Enum.Calculations.IncomeTax ),
	|	value ( Enum.Calculations.FixedIncomeTax )
	|)
	|;
	|// #IncomeTax
	|select Taxes.Account as AccountCr, Taxes.Employee as Employee, Taxes.Result as Result,
	|	Taxes.Tax.Description as Description
	|from Document.PayEmployees.Taxes as Taxes
	|where Taxes.Ref = &Ref
	|and Taxes.Tax.Method in (
	|	value ( Enum.Calculations.IncomeTax ),
	|	value ( Enum.Calculations.FixedIncomeTax )
	|)
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlTotals ( Env )
	
	s = "
	|// #Totals
	|select Totals.Employee as Employee, Totals.Net as Amount
	|from Document.PayEmployees.Totals as Totals
	|where Totals.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure commitTaxes ( Env )
	
	Env.Insert ( "Buffer", GeneralRecords.Frame () );
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Buffer;
	employeesDebt = fields.EmployeesDebt;
	employerDebt = fields.EmployerDebt;
	compensations = Env.Compensations;
	table = distributeTaxes ( Env );
	for each taxRow in table do
		amount = taxRow.Result;
		compensationRow = compensations [ taxRow.LN - 1 ];
		method = taxRow.Method;
		if ( method = Enums.Calculations.MedicalInsurance ) then
			p.AccountDr = employerDebt;
		else
			p.AccountDr = compensationRow.AccountDr;
			compensationRow.Amount = compensationRow.Amount - amount;
		endif; 
		if ( method = Enums.Calculations.SocialInsuranceEmployee ) then
			p.AccountCr = employeesDebt;
		else
			p.AccountCr = taxRow.AccountCr;
		endif; 
		employee = compensationRow.Employee;
		p.Amount = amount;
		p.DimDr1 = employee;
		p.DimDr2 = compensationRow.Compensation;
		p.DimCr1 = employee;
		p.Content = taxRow.Description;
		GeneralRecords.Add ( p );
	enddo; 

EndProcedure 

Function distributeTaxes ( Env )
	
	p = new Structure ();
	p.Insert ( "FilterColumns", "Employee, Compensation" );
	p.Insert ( "DistribColumnsTable1", "Result" );
	p.Insert ( "KeyColumn", "Amount" );
	p.Insert ( "AssignСоlumnsTаble1", "AccountCr, Method, Description" );
	p.Insert ( "AssignColumnsTable2", "LN" );
	p.Insert ( "DistributeTables" );
	compensations = Env.Compensations;
	base = compensations.Copy ();
	taxes = Env.Taxes;
	amountType = Metadata.AccountingRegisters.General.Resources.Amount.Type;
	CollectionsSrv.Adjust ( taxes, "Result", amountType );
	result = CollectionsSrv.Combine ( taxes, base, p );
	p.FilterColumns = "Employee";
	p.AssignСоlumnsTаble1 = "AccountCr, Description";
	base = compensations.Copy ( new Structure ( "IncomeTax", true ) );
	taxes = Env.IncomeTax;
	CollectionsSrv.Adjust ( taxes, "Result", amountType );
	incomeTax = CollectionsSrv.Combine ( taxes, base, p );
	CollectionsSrv.Join ( result, incomeTax );
	return result;
	
EndFunction 

Procedure commitNet ( Env )
	
	fields = Env.Fields;
	method = fields.Method;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Buffer;
	if ( method.IsEmpty () ) then
		p.Content = Output.PayrollNetAmount ();
		p.AccountCr = fields.DepositLiabilities;
		for each row in Env.Compensations do
			p.AccountDr = row.AccountDr;
			p.Amount = row.Amount;
			p.DimDr1 = row.Employee;
			p.DimDr2 = row.Compensation;
			p.DimCr1 = row.Employee;
			GeneralRecords.Add ( p );
		enddo; 
	else
		p.Content = Output.PayrollPayment ();
		p.AccountCr = fields.Account;
		p.CurrencyCr = Application.Currency ();
		cash = ( method = Enums.PaymentMethods.Cash );
		p.DimCr1 = ? ( cash, fields.Location, fields.BankAccount );
		p.DimCr2 = fields.cashFlow;
		for each row in Env.Compensations do
			p.AccountDr = row.AccountDr;
			p.Amount = row.Amount;
			p.DimDr1 = row.Employee;
			p.DimDr2 = row.Compensation;
			GeneralRecords.Add ( p );
		enddo; 
	endif;
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	general = Env.Registers.General;
	GeneralRecords.Flush ( general, Env.Buffer );
	general.Write = true;
	
EndProcedure

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	if ( Params.Template = "Payroll" ) then
		printPayroll ( Params, Env );	
	elsif ( Params.Template = "Paysheet" ) then
		printPaysheet ( Params, Env );	
	endif;
	return true;
	
EndFunction

Procedure printPayroll ( Params, Env )
	
	setPageSettings ( Params );
	getPayrollPrintData ( Params, Env );
	putPayrollHeader ( Params, Env );
	putPayrollTable ( Params, Env );
	putPayrollFooter ( Params, Env );
	
EndProcedure

Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Landscape;
	tabDoc.FitToPage = true;
	
EndProcedure 
 
Procedure getPayrollPrintData ( Params, Env )
	
	sqlPrintFields ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	sqlPayrollPrintData ( Env );
	Env.Q.SetParameter ( "Period", Env.Fields.Date );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlPrintFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Company.FullDescription as Company, 
	|	Documents.Number as Number, Documents.Date as Date
	|from Document.PayEmployees as Documents 
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlPayrollPrintData ( Env )
	
	s = "
	|// #Compensations
	|select Compensations.Employee as Employee, Compensations.Compensation as Compensation,
	|	sum ( Compensations.Amount ) as Amount
	|from Document.PayEmployees.Compensations as Compensations
	|where Compensations.Ref = &Ref
	|group by Compensations.Employee, Compensations.Compensation
	|;
	|// #Taxes
	|select Taxes.Employee as Employee, Taxes.Tax as Tax, 
	|	sum ( Taxes.Result ) as Amount
	|from Document.PayEmployees.Taxes as Taxes
	|where Taxes.Ref = &Ref
	|group by Taxes.Employee, Taxes.Tax
	|;
	|// #Totals
	|select Totals.Employee as Employee, sum ( Totals.Amount ) as Amount,
	|	sum ( Totals.Net ) as Net, sum ( Totals.Amount - Totals.Net ) as Retained
	|from Document.PayEmployees.Totals as Totals
	|where Totals.Ref = &Ref
	|group by Totals.Employee
	|;
	|// #Personnel
	|select Compensations.Employee as EmployeeRef, 
	|	Compensations.Employee.Description as Employee, 
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
	|;
	|// #CompensationsList
	|select Compensations.Compensation as Compensation, sum ( Compensations.Amount ) as Amount 
	|from Document.PayEmployees.Compensations as Compensations
	|where Compensations.Ref = &Ref
	|group by Compensations.Compensation
	|;
	|// #TaxesList
	|select Taxes.Tax as Tax, sum ( Taxes.Result ) as Amount 
	|from Document.PayEmployees.Taxes as Taxes
	|where Taxes.Ref = &Ref
	|group by Taxes.Tax";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putPayrollHeader ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.Date = Format ( Env.Fields.Date, "DLF=D" );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putPayrollTable ( Params, Env )
	
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
		employee = row.EmployeeRef;
		p.Fill ( row );
		p.LineNumber = lineNumber;
		tabDoc.Put ( area );
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

Procedure putPayrollFooter ( Params, Env )
	
	area = Env.T.GetArea ( "Footer" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );		
	
EndProcedure

Procedure printPaysheet ( Params, Env )
	
	setPageSettings ( Params );
	getPaysheetPrintData ( Params, Env );
	putPaysheetHeader ( Params, Env );
	putPaysheetTable ( Params, Env );
	putPaysheetFooter ( Params, Env );	
	
EndProcedure

Procedure getPaysheetPrintData ( Params, Env )
	
	sqlPrintFields ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	sqlPaysheetPrintData ( Env );
	Env.Q.SetParameter ( "Period", Env.Fields.Date );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlPaysheetPrintData ( Env )
	
	s = "
	|// #Totals
	|select Totals.LineNumber as LineNumber, Totals.Employee.Description as Employee, 
	|	Personnel.Position.Description as Position, 
	|	Employees.Code as Code, Totals.Net as Amount
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
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putPaysheetHeader ( Params, Env )
	
	fields = Env.Fields;
	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	p.Fill ( fields );
	p.Date = Format ( fields.Date, "DLF=D" );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putPaysheetTable ( Params, Env )
	
	tabDoc = Params.TabDoc;
	area = Env.T.GetArea ( "TableRow" );
	p = area.Parameters;
	for each row in Env.Totals do
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo;
	
EndProcedure

Procedure putPaysheetFooter ( Params, Env )
	
	area = Env.T.GetArea ( "Footer" );
	area.Parameters.Amount = Env.Totals.Total ( "Amount" );
	Params.TabDoc.Put ( area );		
	
EndProcedure

#endregion

#endif