﻿// Create Vendor Payment
// Create Vendor Invoice
// Create Vendor Refund
// Create Vendor Return based on Vendor Invoice

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0VO" );
env = getEnv ( id );
createEnv ( env );

vendor = env.Vendor;
contract = env.Contract;
warehouse = env.Warehouse;
items = env.Items;

// *************************
// Create Vendor Payment
// *************************

Commando("e1cib/command/Document.VendorPayment.Create");
form = With ( "Vendor Payment (cr*" );
Put ( "#Vendor", vendor );
Put ( "#Memo", id );
Put ( "#Amount", env.Amount );
Put ( "#Account", "2422" );
Click ( "#FormPost", form );
Close ( form );

// *************************
// Create Vendor Invoice
// *************************

Commando("e1cib/command/Document.VendorInvoice.Create");
invoiceForm = With ( "Vendor Invoice (cr*" );
Put ( "#Vendor", vendor );
Put ( "#Warehouse", warehouse );
Put ( "#Memo", id );
table = Activate ( "#ItemsTable" );
for each row in items do
	Click ( "#ItemsTableAdd" );
	Put ( "#ItemsItem", row.Item, table );
	Put ( "#ItemsQuantity", row.Quantity, table );
	Put ( "#ItemsPrice", row.Price, table );
enddo;
Click ( "#FormPost", invoiceForm );

// *************************
// Create Vendor Refund
// *************************

Commando ( "e1cib/command/Document.VendorRefund.Create" );
Set ( "#Vendor", vendor );
Put ( "#Amount", env.Amount );
Put ( "#Account", env.Account );
Put ( "#Memo", id );
Click ( "#FormPost" );
CheckErrors ();

// *************************
// Create Vendor Return
// *************************

With ( invoiceForm, true );
Click ( "#FormDocumentVendorReturnCreateBasedOn", invoiceForm );
Close ( invoiceForm );
returnForm = With ( "Return to Vendor (cr*" );
Put ( "#Memo", id );
Click ( "#FormPost", returnForm );

// *************************
// Check Records
// *************************

Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Contract", "General" );
	p.Insert ( "Items", getItems ( ID ) );
	p.Insert ( "Amount", "180.00" );
	p.Insert ( "Account", "2422" );
	return p;

EndFunction

Function getItems ( ID )

	list = new Array ();
	list.Add ( getItem ( "Item1 " + ID, "10.00", "5" ) );
	list.Add ( getItem ( "Item2 " + ID, "15.00", "10" ) );
	list.Add ( getItem ( "Item3 " + ID, "35.00", "20" ) );
	return list;

EndFunction

Function getItem ( Description, Price, Quantity )

	p = new Structure ();
	p.Insert ( "Item", Description );
	p.Insert ( "Price", Price );
	p.Insert ( "Quantity", Quantity );
	return p;	

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	for each row in env.Items do
		p.Description = row.Item;
		Call ( "Catalogs.Items.Create", p );
	enddo;
		
	RegisterEnvironment ( id );
	
EndProcedure