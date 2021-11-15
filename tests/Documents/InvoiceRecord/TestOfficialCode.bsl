Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6A984A" );
env = getEnv ( id );
createEnv ( env );

With ();
Choose ( "#Customer" );
With ();
Click ( "OK" );

With ();
Put ( "#Customer", "Customer" );
Click ( "OK" );

// Open InvoiceRecord
Commando ( "e1cib/list/Document.InvoiceRecord" );
With ();
p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );
Click ( "#FormDocumentInvoiceRecordPrint" );
With ();
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Service", "Service " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	createItems ( Env );
	createInvoiceRecord ( Env );
	
	RegisterEnvironment ( id );

EndProcedure

Procedure createItems ( Env )
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	p.OfficialCode = "Official " + Env.ID;
	Call ( "Catalogs.Items.Create", p );
	p.Description = Env.Service;
	p.OfficialCode = undefined;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );

EndProcedure

Procedure createInvoiceRecord ( Env )
	
	Commando ( "e1cib/data/Document.InvoiceRecord" );
	form = With ();
	Get ( "#Range" ).Clear ();
	Set ( "#DeliveryDate", "01/01/2020" );
	Next ();
	Set ( "#Number", Env.ID );
	Put ( "#Memo", Env.ID );
	Put ( "#Status", "Printed" );
	table = Get ( "#Items" );
	Click ( "#ItemsAdd" );
	Choose ( "#ItemsItem" );
	With ();
	GotoRow ( "#TypeTree", "", "Items" );
	Click ( "OK" );
	With ();
	GotoRow ( "#List", "Description", Env.Item );
	Click ( "#FormChoose" );
	With ( form );
	Put ( "#ItemsQuantity", 10, table );
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	Put ( "#ServicesItem", Env.Service, table );
	Click ( "#FormWriteAndClose" );

EndProcedure




