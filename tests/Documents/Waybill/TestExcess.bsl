// Test Waybill creation with excess:
// - Create Waybill without Inventory
// - Create Waybill with Inventory
// - Post & CheckLogic

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A17G" );
env = getEnv ( id );
createEnv ( env );

// **********************************
// Create Waybill without Inventory
// **********************************

Commando ( "e1cib/data/Document.Waybill" );
form = With ( "Waybill (cr*" );

Put ( "#DateOpening", env.DateOpening1 );
Put ( "#Date", env.Date1 );
Put ( "#Car", env.Car );
Put ( "#Driver1", env.Driver );
   
Activate ( "#PageMain" );
Put ( "#OdometerStart", 0 );
Put ( "#OdometerEnd", 100 );
Put ( "#MileageCity", 100 );

Activate ( "#PageMore" );
Put ( "#WaybillType", "11" );

Click ( "#FormPost" );
Close ( form );

// **********************************
// Create Waybill with Inventory Economy
// **********************************

Commando ( "e1cib/data/Document.Waybill" );
form = With ( "Waybill (cr*" );

Put ( "#DateOpening", env.DateOpening2 );
Put ( "#Date", env.Date2 );
Put ( "#Car", env.Car );
Put ( "#Driver1", env.Driver );
   
Activate ( "#PageMain" );
Put ( "#OdometerEnd", 300 );
Put ( "#MileageCity", 100 );

Click ( "#FuelInventory" );
table = Get ( "#FuelBalances" );
GotoRow ( table, "Fuel", "Fuel: " + Env.ID );
Put ( "#FuelBalancesQuantity", 25, table );

Activate ( "#PageMore" );
Put ( "#WaybillType", "11" );
Put ( "#Account", "7111" );
Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
With ( "Records: Waybill *" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "DateOpening1", "01.04.2019" );
	p.Insert ( "Date1", "08.04.2019" );
	p.Insert ( "DateOpening2", "10.04.2019" );
	p.Insert ( "Date2", "12.04.2019" );
	p.Insert ( "Driver", "Driver: " + ID );
	p.Insert ( "Warehouse", "Warehouse: " + ID );
	p.Insert ( "Fuel", "Fuel: " + ID );
	p.Insert ( "CarType", "CarType: " + ID );
	p.Insert ( "Car", "Car: " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Driver;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	p.Class = "Car";
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Fuel
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Fuel;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create CarType
	// *************************
	
	p = Call ( "Catalogs.CarTypes.Create.Params" );
	p.Description = Env.CarType;
	p.Type = "Cars";
	p.FuelMain = Env.Fuel;
	p.TankCapacity = 70;
	p.OdometerWinter = 15;
	p.OdometerWinterCity = 20;
	p.OdometerSummer = 10;
	p.OdometerSummerCity = 15;
	Call ( "Catalogs.CarTypes.Create", p );
	
	// *************************
	// Create Car
	// *************************
	
	p = Call ( "Catalogs.Cars.Create.Params" );
	p.Description = Env.Car;
	p.Warehouse = Env.Warehouse;
	p.CarType = Env.CarType;
	Call ( "Catalogs.Cars.Create", p );
	
	// *************************
	// Create Receive Items
	// *************************
	
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = "03/31/2019";
	p.Warehouse = Env.Warehouse;
	p.Account = "7141";
	p.Expenses = "Expenses " + id;
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = Env.Fuel;
	row.Quantity = 70;
	row.Price = 18;
	items.Add ( row );
	p.Items = items; 
	Call ( "Documents.ReceiveItems.Receive", p );
	
	RegisterEnvironment ( id );

EndProcedure
