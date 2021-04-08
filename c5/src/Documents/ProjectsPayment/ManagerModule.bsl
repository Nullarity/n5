#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.ProjectsPayment.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	makePayments ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )
	
	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );

EndProcedure 

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Amount as Amount, Documents.Invoice as Invoice
	|from Document.ProjectsPayment as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure makePayments ( Env )
	
	movement = Env.Registers.ProjectDebts.AddExpense ();
	movement.Period = Env.Fields.Date;
	movement.Invoice = Env.Fields.Invoice;
	movement.Amount = Env.Fields.Amount;
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	Env.Registers.ProjectDebts.Write = true;
	
EndProcedure

#endregion

#endif