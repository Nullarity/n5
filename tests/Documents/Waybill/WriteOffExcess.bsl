// Test overconsumption writing off

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A17M" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region writeOff
Commando("e1cib/command/Document.WriteOff.Create");
Set("#Warehouse", this.Warehouse);
Set("#ExpenseAccount", "7111");
Set ( "#CarExpenses", "Overconsumption" );
Click ( "#ItemsTableFillByCar" );
With ();
Click ( "#FormFill" );
With ();
Click("#FormPost");
With();
Click ( "#FormFuel" );
With ();

#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "DateOpening", "01.04.2019" );
	this.Insert ( "Date", "08.04.2019" );
	this.Insert ( "Driver", "Driver: " + id );
	this.Insert ( "Warehouse", "Warehouse: " + id );
	this.Insert ( "Fuel", "Fuel: " + id );
	this.Insert ( "CarType", "CarType: " + id );
	this.Insert ( "Car", "Car: " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region newEmployee
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = this.Driver;
	Call ( "Catalogs.Employees.Create", p );
	#endregion
	
	#region newWarehouse
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = this.Warehouse;
	p.Class = "Car";
	Call ( "Catalogs.Warehouses.Create", p );
	#endregion
	
	#region newFuel
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Fuel;
	Call ( "Catalogs.Items.Create", p );
	#endregion
	
	#region newCarType
	p = Call ( "Catalogs.CarTypes.Create.Params" );
	p.Description = this.CarType;
	p.Type = "Cars";
	p.FuelMain = this.Fuel;
	p.TankCapacity = 70;
	p.OdometerWinter = 15;
	p.OdometerWinterCity = 20;
	p.OdometerSummer = 10;
	p.OdometerSummerCity = 15;
	Call ( "Catalogs.CarTypes.Create", p );
	#endregion
	
	#region newCar
	p = Call ( "Catalogs.Cars.Create.Params" );
	p.Description = this.Car;
	p.Warehouse = this.Warehouse;
	p.CarType = this.CarType;
	Call ( "Catalogs.Cars.Create", p );
	#endregion
	
	#region receiveFuel
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = "03/31/2019";
	p.Warehouse = this.Warehouse;
	p.Account = "7141";
	p.Expenses = "Expenses " + id;
	items = new Array ();
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = this.Fuel;
	row.Quantity = 70;
	row.Price = 18;
	items.Add ( row );
	p.Items = items; 
	Call ( "Documents.ReceiveItems.Receive", p );
	#endregion

	#region waybillOverconsumption
	Commando ( "e1cib/data/Document.Waybill" );
	
	Put ( "#DateOpening", this.DateOpening );
	Put ( "#Date", this.Date );
	Put ( "#Car", this.Car );
	Put ( "#Driver1", this.Driver );
	   
	Activate ( "#PageMain" );
	Put ( "#OdometerEnd", 300 );
	Put ( "#MileageCity", 100 );
	
	Click ( "#FuelInventory" );
	table = Get ( "#FuelBalances" );
	GotoRow ( table, "Fuel", "Fuel: " + this.ID );
	Put ( "#FuelBalancesQuantity", 25, table );
	
	Activate ( "#PageMore" );
	Put ( "#WaybillType", "11" );
	Put ( "#Account", "7111" );
	Click ( "#FormPost" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
