//1. Create Socially significant item
//2. Create Invoice
//2.1 add in tab. section socially significant item
//3. test print form

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6A8D53" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/Document.InvoiceRecord" );
With ( "Invoice Records" );
p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );

Click ( "#ListContextMenuChange" );
With ( "Invoice Record #*" );
Set ( "#Type", "Invoice" );
Click ( "#FormPrint" );
form = With ( "Invoice: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( form );
With ();
Put ( "#Status", "Saved" );
Click ( "#FormWrite" );
CloseAll ();

// *************************
// Procedures
// *************************

Function getEnv ( ID )

p = new Structure ();
p.Insert ( "ID", ID );
p.Insert ( "Customer", "Customer " + ID );
p.Insert ( "Item1", "Item1: " + ID );
return p;

EndFunction

Procedure createEnv ( Env )

id = Env.ID;
if ( Call ( "Common.DataCreated", id ) ) then
return;
endif;

// *************************
// Create Customer
// *************************
Commando ( "e1cib/data/Catalog.Organizations" );
With ( "Organizations (create)" );
Put ( "#Description", Env.Customer );
Click ( "#Customer" );
Click ( "#FormWriteAndClose" );

// *************************
// Items
// *************************

p = Call ( "Catalogs.Items.Create.Params" );
p.Description = Env.Item1;
p.Feature = "Feature";
p.CountPackages = true;
p.Social = true;
Call ( "Catalogs.Items.Create", p );

// *************************
// InvoiceRecord
// *************************

Commando ( "e1cib/Data/Document.InvoiceRecord" );
Put ( "#VATUse", "Included in Price" );
Put ( "#Date", "08/14/2017" );
Choose ( "#Customer" );
With ( "Select data type" );
GotoRow ( "#TypeTree", "", "Organizations" );
Click ( "#OK" );
With ( "Organizations" );
GotoRow ( "#List", "Name", Env.Customer );
Click ( "#FormChoose" );
With ();
table = Get ( "#Items" );
Click ( "#ItemsAdd" );
setValue ( "#ItemsItem", env.Item1, "Items" );
Next ();
Put ( "#ItemsFeature", "Feature", table );
Set ( "#ItemsQuantity", 1, table );
Set ( "#ItemsPrice", 100, table );
Set ( "#ItemsProducerPrice", 50, table );
Get ( "#Range" ).Clear ();
Put ( "#Number", "AA" + id );
Put ( "#Memo", id );

Click ( "#FormWrite" );
Close ();

Call ( "Common.StampData", id );

EndProcedure

Procedure setValue ( Field, Value, Object, GoToRow = "Description" )

form = CurrentSource;
Choose ( Field );
With ( "Select data type" );
GotoRow ( "#TypeTree", "", Object );
Click ( "#OK" );
if ( Object = "Companies" ) then
With ( "Addresses*" );
Put ( "#Owner", Value );
else
With ( Object );
GotoRow ( "#List", GoToRow, Value );
Click ( "#FormChoose" );
CurrentSource = form;
endif;

EndProcedure