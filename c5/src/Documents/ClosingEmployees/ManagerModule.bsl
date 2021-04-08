#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.ClosingEmployees.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	commitRecords ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Procedure getData ( Env )
	
	sqlFields ( Env );
	sqlDebts ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.DebtAccount as DebtAccount
	|from Document.ClosingEmployees as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlDebts ( Env )
	
	s = "
	|// #Debts
	|select Debts.Amount as Amount, Debts.CloseDebt as CloseDebt, Debts.Employee as Employee, Debts.Account as Account
	|from Document.ClosingEmployees.Debts as Debts
	|where Debts.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure commitRecords ( Env )
	
	fields = Env.Fields;
	debtAccount = fields.DebtAccount;
	closeDebts = OutputCont.CloseEmployeeDebts ();
	formationDebts = OutputCont.FormationEmployeeDebts ();
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	for each row in Env.Debts do
		if ( row.CloseDebt ) then
			employeeType = "Cr";
			debtType = "Dr";
			p.Content = closeDebts;
		else
			employeeType = "Dr";
			debtType = "Cr";
			p.Content = formationDebts;
		endif;
		p [ "Account" + employeeType ] = row.Account;
		p [ "Account" + debtType ] = debtAccount;
		employee = row.Employee;
		p.DimDr1 = employee;
		p.DimCr1 = employee;
		p.Amount = row.Amount;
		GeneralRecords.Add ( p );
	enddo; 

EndProcedure

Procedure flagRegisters ( Env )
	
	Env.Registers.General.Write = true;
	
EndProcedure

#endregion

#endif
