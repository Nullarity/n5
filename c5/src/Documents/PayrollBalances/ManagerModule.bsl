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
	|	Employees.Individual as Employee, Employees.Balance as Balance
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
	enddo; 
	
EndProcedure 

Procedure commitCompensation ( Params, Row )
	
	zero = ChartsOfAccounts.General._0;
	account = Row.Account;
	employee = Row.Employee;
	compensation = Row.Compensation;
	balance = Row.Balance;
	if ( balance <> 0 ) then
		Params.AccountDr = zero;
		Params.AccountCr = account;
		Params.Amount = balance;
		Params.DimCr1 = employee;
		Params.DimCr2 = compensation;
		GeneralRecords.Add ( Params );
	endif;
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	general = Env.Registers.General;
	general.Write = true;
	
EndProcedure

#endregion

#endif