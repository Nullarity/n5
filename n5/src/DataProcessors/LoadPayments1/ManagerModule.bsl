#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetParams () export
	
	p = new Structure();
	p.Insert("File");
	p.Insert("Application");
	p.Insert("Company");
	p.Insert("BankAccount");
	p.Insert("BankAccountCurrency");
	p.Insert("Address");
	p.Insert("Account");
	p.Insert("InternalMovement");
	p.Insert("OtherExpense");
	p.Insert("OtherReceipt");
	p.Insert("Date");
	return p;
	
EndFunction 

Procedure Exec ( Params, JobKey ) export
	
	SetPrivilegedMode ( true );
	obj = Create ();
	obj.Parameters = Params;
	obj.JobKey = JobKey;
	obj.Exec ();
	
EndProcedure 

#endif