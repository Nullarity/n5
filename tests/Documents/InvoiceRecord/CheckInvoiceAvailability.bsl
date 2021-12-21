// Create an Invoice
// Create an Invoice Record and print it
// Check if Invoice is not available for changes anymore

Call("Common.Init");
CloseAll();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0HB" ) );
getEnv ();
createEnv ();

// Create an Invoice
invoice = Commando("e1cib/command/Document.Invoice.Create");
CheckState("#ItemsSelectItems, #ItemsScan, #ItemsApplySalesOrders", "Enable");
Put ( "#Customer", this.Customer );
Click("#JustSave");

// Create an Invoice Record and print it
Click("#NewInvoiceRecord");
record = With();
Get ( "#Range" ).Clear ();
Set ( "#Number", "" + new UUID () );
Click("#FormWrite");
try
	Click("#FormPrint");
except
	DebugStart ();
endtry;
Close();

// Check if Invoice is not available for changes anymore
With(invoice, true);
CheckState("#ItemsSelectItems, #ItemsScan, #ItemsApplySalesOrders", "Enable", false);

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
