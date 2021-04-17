// Creates InvoiceRecord from LVI Transfer and check form InvoiceRecord
// 1. Create LVI Transfer
// 2. Generate Invoice Record from LVI Tranfer
// 3. Check Print form

Call ( "Common.Init" );
CloseAll ();

StandardProcessing = false;

id = Call ( "Common.ScenarioID", "2B6A986E" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/Document.InvoiceRecord" );
With ();

p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );

Click ( "#ListContextMenuChange" );
form = With ();
Click ( "#FormPrint" );
With ();
Call ( "Common.CheckLogic", "#TabDoc" );
Close ();

With ( form );
CheckState ( "#Warning", "Visible" );

With ( form );
Put ( "#Status", "Saved" );
Click ( "#FormWrite" );
CheckState ( "#Warning", "Visible", false );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "LVI", "_LVI Transfer " + ID );
	p.Insert ( "DepartmentSender", "LVI Department sender " + ID );
	p.Insert ( "DepartmentReceiver", "LVI Department receiver " + ID );
	p.Insert ( "EmployeeSender", "LVI Employee sender " + ID );
	p.Insert ( "EmployeeReceiver", "LVI Employee receiver " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.DepartmentSender;
	Call ( "Catalogs.Departments.Create", p );
	p.Description = Env.DepartmentReceiver;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.EmployeeSender;
	Call ( "Catalogs.Employees.Create", p );
	p.Description = Env.EmployeeReceiver;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.LVI;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// LVI Tranfer
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Document.LVITransfer" );
	With ();
	form = With ();
	Put ( "#Memo", id );

	table = Activate ("#Items" );
	Call ( "Table.Clear", table );

	Click ( "#ItemsAdd" );
	Set ( "#ItemsItem", env.LVI, table );
	Set ( "#ItemsQuantity", 1, table );

	table = Activate ("#Items" );
	Put ( "#ItemsDepartmentReceiver", env.DepartmentReceiver );
	Put ( "#ItemsDepartment", env.DepartmentSender );
	Put ( "#ItemsEmployeeReceiver", env.EmployeeReceiver );
	Put ( "#ItemsEmployee", env.EmployeeSender );

		
	Click ( "#NewInvoiceRecord" );
	With ();
	Click ("OK");
	
	With ();
	Get ( "#Range" ).Clear ();
	Put ( "#Number", id );
	Set ("#DeliveryDate", "05/20/2020");
	Put ( "#Memo", id );
	Click ( "#FormWriteAndClose" );

	Close ( form );
	
	RegisterEnvironment ( id );
	
EndProcedure
