Function Post ( Env ) export
	
	setContext ( Env );
	getData ( Env );
	prepareTables ( Env );
	commitTaxes ( Env );
	commitNet ( Env );
	if ( Env.Advances ) then
		makeAdvances ( Env );
	endif;
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure setContext ( Env )
	
	advances = ( Env.Document = "PayAdvances" );
	Env.Insert ( "Advances", advances );
	Env.Insert ( "EmployeeField" );
	if ( advances ) then
		Env.EmployeeField = "Individual";
	else
		Env.EmployeeField = "Employee";
	endif;
	
EndProcedure

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
	|	Documents.Method as Method, Documents.BankAccount as BankAccount, Documents.CashFlow as CashFlow,
	|	Documents.Location as Location, Documents.Account as Account
	|from Document." + Env.Document + " as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlCompensations ( Env )
	
	s = "
	|// #Compensations
	|select Compensations.LineNumber as LN, Compensations.Account as AccountDr,
	|	Compensations.Compensation as Compensation, Compensations." + Env.EmployeeField + " as Individual,
	|";
	if ( Env.Advances ) then
		s = s + "case when Compensations.InHand then Compensations.Result else Compensations.Amount end as Amount, Compensations.Employee as Employee";
	else
		s = s + "Compensations.Amount as Amount";
	endif;
	s = s + ",
	|	case when IncomeTax.Compensation is null then false else true end as IncomeTax
	|from Document." + Env.Document + ".Compensations as Compensations
	|	//
	|	// IncomeTax
	|	//
	|	left join (
	|		select distinct Taxes.Employee as Employee, Compensations.CalculationType as Compensation
	|		from Document." + Env.Document + ".Taxes as Taxes
	|			//
	|			// Compensations
	|			//
	|			join ChartOfcalculationTypes.Taxes.BaseCalculationTypes as Compensations
	|			on Compensations.Ref = Taxes.Tax
	|		where Taxes.Ref = &Ref
	|		and Taxes.Tax.Method = value ( Enum.Calculations.IncomeTax )
	|	) as IncomeTax
	|	on IncomeTax.Employee = Compensations." + Env.EmployeeField + "
	|	and IncomeTax.Compensation = Compensations.Compensation
	|where Compensations.Ref = &Ref
	|order by LN
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlTaxes ( Env )
	
	s = "
	|// #Taxes
	|select Taxes.Account as AccountCr, Taxes.Compensation as Compensation, Taxes.Employee as Individual,
	|	Taxes.Result as Result, Taxes.Base as Amount, Taxes.Tax.Method as Method,
	|	Taxes.Tax.Description as Description
	|from Document." + Env.Document + ".Taxes as Taxes
	|where Taxes.Ref = &Ref
	|and Taxes.Tax.Method <> value ( Enum.Calculations.IncomeTax )
	|;
	|// #IncomeTax
	|select Taxes.Account as AccountCr, Taxes.Employee as Individual, Taxes.Result as Result,
	|	Taxes.Tax.Description as Description
	|from Document." + Env.Document + ".Taxes as Taxes
	|where Taxes.Ref = &Ref
	|and Taxes.Tax.Method = value ( Enum.Calculations.IncomeTax )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlTotals ( Env )
	
	s = "
	|// #Totals
	|select Totals.Employee as Individual, Totals.Net as Amount
	|from Document." + Env.Document + ".Totals as Totals
	|where Totals.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure prepareTables ( Env )
	
	Env.Insert ( "DistributedTaxes", distributeTaxes ( Env ) );
	if ( Env.Advances ) then
		Env.Insert ( "AdvancesTable", prepareAdvances ( Env ) );
	endif;

EndProcedure

Function distributeTaxes ( Env )
	
	p = new Structure ();
	p.Insert ( "FilterColumns", "Individual, Compensation" );
	p.Insert ( "DistribColumnsTable1", "Result" );
	p.Insert ( "KeyColumn", "Amount" );
	p.Insert ( "AssignСоlumnsTаble1", "AccountCr, Method, Description" );
	p.Insert ( "AssignColumnsTable2", "LN" + ? ( Env.Advances, ", Employee", "" ) );
	p.Insert ( "DistributeTables" );
	compensations = Env.Compensations;
	base = compensations.Copy ();
	taxes = Env.Taxes;
	amountType = Metadata.AccountingRegisters.General.Resources.Amount.Type;
	CollectionsSrv.Adjust ( taxes, "Result", amountType );
	result = CollectionsSrv.Combine ( taxes, base, p );
	p.FilterColumns = "Individual";
	p.AssignСоlumnsTаble1 = "AccountCr, Description";
	base = compensations.Copy ( new Structure ( "IncomeTax", true ) );
	taxes = Env.IncomeTax;
	CollectionsSrv.Adjust ( taxes, "Result", amountType );
	incomeTax = CollectionsSrv.Combine ( taxes, base, p );
	CollectionsSrv.Join ( result, incomeTax );
	return result;
	
EndFunction 

Function prepareAdvances ( Env )
	
	compensations = Env.Compensations;
	table = compensations.Copy ();
	table.Columns.Add ( "Paid", new TypeDescription ( "Number" ) );
	table.LoadColumn ( table.UnloadColumn ( "Amount" ), "Paid" );
	taxes = Env.DistributedTaxes;
	for each taxRow in taxes do
		newRow = table.Add ();
		newRow.Paid = - taxRow.Result;
		compensationRow = compensations [ taxRow.LN - 1 ];
		newRow.AccountDr = compensationRow.AccountDr;
		newRow.Employee = compensationRow.Employee;
		newRow.Compensation = compensationRow.Compensation;
	enddo;
	table.GroupBy ( "Employee, Compensation, AccountDr", "Amount, Paid" );
	return table;

EndFunction

Procedure commitTaxes ( Env )
	
	Env.Insert ( "Buffer", GeneralRecords.Frame () );
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Buffer;
	compensations = Env.Compensations;
	for each taxRow in Env.DistributedTaxes do
		amount = taxRow.Result;
		compensationRow = compensations [ taxRow.LN - 1 ];
		p.AccountDr = compensationRow.AccountDr;
		compensationRow.Amount = compensationRow.Amount - amount;
		p.AccountCr = taxRow.AccountCr;
		employee = compensationRow.Individual;
		p.Amount = amount;
		p.DimDr1 = employee;
		p.DimDr2 = compensationRow.Compensation;
		p.DimCr1 = employee;
		p.Content = taxRow.Description;
		GeneralRecords.Add ( p );
	enddo; 

EndProcedure 

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
			p.DimDr1 = row.Individual;
			p.DimDr2 = row.Compensation;
			p.DimCr1 = row.Individual;
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
			p.DimDr1 = row.Individual;
			p.DimDr2 = row.Compensation;
			GeneralRecords.Add ( p );
		enddo; 
	endif;
	
EndProcedure 

Procedure makeAdvances ( Env )
	
	date = Env.Fields.Date;
	ref = Env.Ref;
	recordset = Env.Registers.PayAdvances;
	for each row in Env.AdvancesTable do
		record = recordset.Add ();
		record.Period = date;
		record.Document = ref;
		record.Employee = row.Employee;
		record.Compensation = row.Compensation;
		record.Account = row.AccountDr;
		record.Amount = row.Amount;
		record.Paid = row.Paid;
	enddo;

EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	if ( Env.Advances ) then
		registers.PayAdvances.Write = true;
	endif;
	general = registers.General;
	GeneralRecords.Flush ( general, Env.Buffer );
	general.Write = true;
	
EndProcedure
