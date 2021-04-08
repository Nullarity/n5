#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.PayrollBalances.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	commit ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	sqlEmployees ( Env );
	getFields ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select dateadd ( Documents.Date, second, - 1 ) as Date, Documents.Company as Company
	|from Document.PayrollBalances as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlEmployees ( Env )
	
	s = "
	|// #Employees
	|select Employees.Account as Account, Employees.Compensation as Compensation,
	|	Employees.Individual as Employee, Employees.IncomeTax as IncomeTax,
	|	Employees.IncomeTaxAccount as IncomeTaxAccount, Employees.Medical as Medical,
	|	Employees.MedicalAccount as MedicalAccount, Employees.Paid as Paid, Employees.Balance as Balance,
	|	Employees.Social as Social, Employees.EmployeesDebt as EmployeesDebt,
	|	Employees.SocialAccrued as SocialAccrued
	|from Document.PayrollBalances.Employees as Employees
	|where Employees.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure commit ( Env )
	
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	for each row in Env.Employees do
		commitCompensation ( p, row );
		commitSocial ( env, p, row );
		commitMedical ( env, p, row );
		commitIncomeTax ( p, row );
	enddo; 
	
EndProcedure 

Procedure commitCompensation ( Params, Row )
	
	paid = Row.Paid;
	zero = ChartsOfAccounts.General._0;
	account = Row.Account;
	employee = Row.Employee;
	compensation = Row.Compensation;
	if ( paid <> 0 ) then
		Params.AccountDr = zero;
		Params.AccountCr = account;
		Params.Amount = paid;
		Params.DimCr1 = employee;
		Params.DimCr2 = compensation;
		GeneralRecords.Add ( Params );
	endif;
	balance = paid - Row.Balance;
	if ( balance <> 0 ) then
		Params.AccountDr = account;
		Params.AccountCr = zero;
		Params.Amount = balance;
		Params.DimDr1 = Row.Employee;
		Params.DimDr2 = compensation;
		GeneralRecords.Add ( Params );
	endif; 
	
EndProcedure 

Procedure commitSocial ( Env, Params, Row )
	
	employee = Row.Employee;
	employeesDebt = Row.EmployeesDebt;
	accrued = row.SocialAccrued;
	if ( accrued <> 0 ) then
		Params.AccountDr = employeesDebt;
		account = Row.Account;
		Params.AccountCr = account;
		Params.Amount = accrued;
		Params.DimDr1 = employee;
		GeneralRecords.Add ( Params );
		Params.AccountCr = employeesDebt;
		Params.AccountDr = account;
		Params.Amount = accrued;
		Params.DimCr1 = employee;
		GeneralRecords.Add ( Params );
	endif; 
	balance = Row.Social;
	if ( balance <> 0 ) then
		Params.AccountDr = employeesDebt;
		Params.AccountCr = ChartsOfAccounts.General._0;
		Params.Amount = balance;
		Params.DimDr1 = employee;
		GeneralRecords.Add ( Params );
	endif; 
	
EndProcedure 

Procedure commitMedical ( Env, Params, Row )
	
	amount = row.Medical;
	if ( amount = 0 ) then
		return;
	endif;
	account = Row.Account;
	accountTax = Row.MedicalAccount;
	employee = Row.Employee;
	compensation = Row.Compensation;
	Params.AccountDr = account;
	Params.AccountCr = accountTax;
	Params.Amount = amount;
	Params.DimDr1 = employee;
	Params.DimDr2 = compensation;
	GeneralRecords.Add ( Params );
	Params.AccountDr = accountTax;
	Params.AccountCr = account;
	Params.Amount = amount;
	Params.DimCr1 = employee;
	Params.DimCr2 = compensation;
	GeneralRecords.Add ( Params );
	
EndProcedure 

Procedure commitIncomeTax ( Params, Row )
	
	amount = Row.IncomeTax;
	if ( amount = 0 ) then
		return;
	endif;
	account = Row.Account;
	accountTax = Row.IncomeTaxAccount;
	employee = Row.Employee;
	compensation = Row.Compensation;
	Params.AccountDr = accountTax;
	Params.AccountCr = account;
	Params.Amount = amount;
	Params.DimCr1 = employee;
	Params.DimCr2 = compensation;
	Params.DimDr1 = employee;
	GeneralRecords.Add ( Params );
	Params.AccountDr = account;
	Params.AccountCr = accountTax;
	Params.Amount = amount;
	Params.DimCr1 = employee;
	Params.DimDr1 = employee;
	Params.DimDr2 = compensation;
	GeneralRecords.Add ( Params );
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	general = Env.Registers.General;
	general.Write = true;
	
EndProcedure

#endregion

#endif