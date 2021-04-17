// Create Sales Order
// Send to Approval
// Mark for deletion
// Clear deletion mark
// Open SO again

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "26E5A056" );
env = getEnv ( id );
createEnv ( env );

// Create Sales Order
Commando ( "e1cib/list/Document.SalesOrder" );
list = With ( "Sales Orders" );

Click ( "#FormCreate" );
With ( "Sales Order (cr*" );
Set ( "#Customer", env.Customer );
Click ( "#ItemsTableAdd" );
Set ( "#ItemsItem", env.Item );
Set ( "#ItemsQuantityPkg", "1" );
Set ( "#ItemsPrice", "100" );

// Send to Approval
Click ( "#FormSendForApproval" );
Click ( "Yes", DialogsTitle );

// Mark for deletion
With ( list );
Click ( "#FormSetDeletionMark" );
Click ( "Yes", "1?:*" );

// Clear deletion mark
Click ( "#FormSetDeletionMark" );
Click ( "Yes", "1?:*" );

// Open SO again
Click ( "#FormChange" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Warehouse", "Main" );
	p.Insert ( "Division", "Administration" );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );

	RegisterEnvironment ( id );

EndProcedure
