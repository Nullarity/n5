&AtServer
var Base;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	updateChangesPermission ();

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setCreator ();
		updateChangesPermission ();
	endif; 
	if ( TypeOf ( Parameters.Basis ) = Type ( "DocumentRef.ProjectsInvoice" ) ) then
		fillByInvoice ();
	endif;
	StandardButtons.Arrange ( ThisObject );
		
EndProcedure

&AtServer
Procedure setCreator ()
	
	Object.Creator = SessionParameters.User;
	
EndProcedure 

#region Filling

&AtServer
Procedure fillByInvoice ()
	
	getInvoiceData ();
	fillHeaderByInvoice ();
	
EndProcedure 

&AtServer
Procedure getInvoiceData ()
	
	initBase ();
	sqlInvoice ();
	SQL.Perform ( Base );
	
EndProcedure

&AtServer
Procedure initBase ()
	
	Base = new Structure ();
	SQL.Init ( Base );
	Base.Q.SetParameter ( "Base", Parameters.Basis );
	
EndProcedure 

&AtServer
Procedure sqlInvoice ()
	
	s = "
	|// @Fields
	|select allowed Invoices.Customer as Customer, Payments.AmountBalance as Amount
	|from Document.ProjectsInvoice as Invoices
	|	//
	|	// Payments
	|	//
	|	left join AccumulationRegister.ProjectDebts.Balance ( , Invoice = &Base ) as Payments
	|	on Payments.Invoice = Invoices.Ref
	|where Invoices.Ref = &Base
	|";
	Base.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure fillHeaderByInvoice ()
	
	Object.Customer = Base.Fields.Customer;
	Object.Amount = Base.Fields.Amount;
	Object.Invoice = Parameters.Basis;
	
EndProcedure 

#endregion

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure InvoiceOnChange ( Item )
	
	setAmount ();
	
EndProcedure

&AtClient
Procedure setAmount ()
	
	Object.Amount = getAmount ( Object.Invoice );
	
EndProcedure 

&AtServerNoContext
Function getAmount ( val Invoice )
	
	s = "
	|select Balances.AmountBalance as Amount
	|from AccumulationRegister.ProjectDebts.Balance ( , Invoice = &Invoice ) as Balances
	|";
	q = new Query ( s );
	q.SetParameter ( "Invoice", Invoice );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, 0, table [ 0 ].Amount );
	
EndFunction 
