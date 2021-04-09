StandardProcessing = false;

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BE5AB30" );
env = getEnv ( id );
createEnv ( env );

Call ( "Common.OpenList", Meta.Documents.LVIInventory );
With ( "LVI Inventories" );
Click ( "#FormCreate" );
from = With ( "LVI Inventory*" );
Put ( "#Department", env.Department );
Put ( "#Account", "2132" );

table = Activate ( "#ItemsTable" );
Click ( "#ItemsTableDelete" );
Click ( "#ItemsFill" );

question = App.FindObject ( Type ( "TestedForm" ), DialogsTitle );
//if ( question <> undefined ) then
try
    With ();
    Click ( "Yes", question );
except
endtry;
//endif;

With ();
table = Activate ( "#ItemsTable" );
p = Call ( "Common.Row.Params");
p.Table = table;
p.Column = "#ItemsQuantity";
p.Row = 1;
Call ( "Common.Row", p );
table.ChangeRow ();
Set ( "#ItemsQuantity", 4, table );
table.EndEditRow ();

p = Call ( "Common.Row.Params");
p.Table = table;
p.Column = "#ItemsQuantityPkg";
p.Row = 2;
Call ( "Common.Row", p);
table.ChangeRow ();
Set ( "#ItemsQuantity", 100, table );
table.EndEditRow ();

Click ( "#FormPost" );

Click ( "#FormCopy" );
copy = "LVI Inventory (create)";
if ( not Waiting ( copy ) ) then
	Stop ( "The copy of document shoul be appeared" );
endif;
Close ( copy );

Click ( "#FormReportRecordsShow" );
records = With ( "Records: LVI Inventory*" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ( records );

form = With ( "LVI Inventory*" );
Click ( "#FormDocumentLVIWriteOffCreateBasedOn" );
Run ( "LVIWriteOffTestBased", env );

With ( form );
Click ( "#FormDocumentReceiveItemsCreateBasedOn" );
Run ( "ReceiveItemsBasedOn", env );

Run ( "PrintForm" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	env = new Structure ();
	env.Insert ( "ID", ID );
	env.Insert ( "Date", CurrentDate () );
	env.Insert ( "Department", "Department " + ID );
	env.Insert ( "Employee", "Employee " + ID );
	env.Insert ( "Expense", "Expense " + ID );
	return env;

EndFunction

Procedure createEnv ( Env )

 	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// ***********************************
	// Create Startup
	// ***********************************

	params = Call ( "Documents.Startup.TestCreation.CreateDoc.Params" );
	FillPropertyValues ( params, Env );
	Call ( "Documents.Startup.TestCreation.CreateDoc", params );
	CloseAll ();

	// ***********************************
	// Create Expense Method
	// ***********************************
	
	params = Call ( "Catalogs.ExpenseMethods.Create.Params" );
	params.Description = env.Expense;
	params.Account = "7141";
	params.Expense = "Others";
	Call ( "Catalogs.ExpenseMethods.Create", params );

	Call ( "Common.StampData", id );

EndProcedure


