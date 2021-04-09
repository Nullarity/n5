Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

// ***********************************
// Open Report
// ***********************************

p = Call ( "Common.Report.Params" );
p.Path = "Sales / Sales";
p.Title = "Sales*";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
item.ValueFrom = env.ValueFrom;
item.ValueTo = env.ValueTo;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Department";
item.Value = env.Department;
filters.Add ( item );

p.Filters = filters;
p.UseOpenMenu = false;
Commando("e1cib/app/Report.Sales");
form = With ( Call ( "Common.Report", p ) );

settings = Activate ( "#UserSettings" );
settings.GotoFirstRow ();
search = new Map ();
search.Insert ( "Setting", "Chart" );
settings.GotoRow ( search );

Activate ( "#UserSettingsUse", settings );
Click ( "#UserSettingsUse", settings );

With ( form );
Click ( "#GenerateReport" );

CheckTemplate ( "#Result" );

Run ( "ByClients", env );
Run ( "ByMonths", env );

Function getEnv ()
	
	env = new Structure ();
	id = Call ( "Common.ScenarioID", "#286FB231" );//!!! change date if change id
	env.Insert ( "ID", id );
	//date = Date ( 2017, 2, 8 );
	date = BegOfDay ( CurrentDate () );
	env.Insert ( "Date", date );
	receiveDate = date - 86400;
	env.Insert ( "ValueFrom", BegOfMonth ( date ) );
	env.Insert ( "ValueTo", EndOfMonth ( date ) );
	env.Insert ( "ReceiveDate", receiveDate );
	env.Insert ( "Customer", "_SO Customer: " + id );
	env.Insert ( "Warehouse", "_SO Warehouse#" + id );
	env.Insert ( "Department", "_Sales with Shipmets#" + id );
	env.Insert ( "User", "admin" );
	env.Insert ( "Company", "ABC Distributions" );
	env.Insert ( "PaymentOptions", "nodiscount#" );
	env.Insert ( "Terms", "100% prepay, 0-1-5#" );
	return env;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// ***********************************
	// Create Department
	// ***********************************
	
	params = Call ( "Catalogs.Departments.Create.Params" );
	params.Description = Env.department;
	params.Shipments = true;
	params.Company = Env.company;
	
	p = Call ( "Common.CreateIfNew.Params" );
	p.Object = Meta.Catalogs.Departments;
	p.Description = params.Description;
	p.CreationParams = params;
	Call ( "Common.CreateIfNew", p );
	
	// ***********************************
	// Create PaymentOption
	// ***********************************
	
	params = Call ( "Catalogs.PaymentOptions.Create.Params" );
	params.Description = Env.paymentOptions;
	
	p = Call ( "Common.CreateIfNew.Params" );
	p.Object = Meta.Catalogs.PaymentOptions;
	p.Description = params.Description;
	p.CreationParams = params;
	Call ( "Common.CreateIfNew", p );
	
	// ***********************************
	// Create Terms
	// ***********************************
	
	params = Call ( "Catalogs.Terms.Create.Params" );
	params.Description = Env.terms;
	payments = params.Payments;
	row = Call ( "Catalogs.Terms.Create.Row" );
	row.Option = Env.paymentOptions;
	row.Variant = "On delivery";
	row.Percent = "100";
	payments.Add ( row );
	
	p = Call ( "Common.CreateIfNew.Params" );
	p.Object = Meta.Catalogs.Terms;
	p.Description = params.Description;
	p.CreationParams = params;
	Call ( "Common.CreateIfNew", p );
	
	// ***********************************
	// Roles: Division head
	// ***********************************
	
	MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
	list = With ( "Roles" );
	Click ( "#FormCreate" );
	With ( "Roles (create)" );
	Put ( "#User", Env.user );
	Pick ( "#Role", "Department Head" );
	Set ( "#Department", Env.department );
	CurrentSource.GotoNextItem ();
	Click ( "#Apply" );
	
	// ***********************************
	// Roles: Warehouse manager
	// ***********************************
	
	MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
	list = With ( "Roles" );
	Click ( "#FormCreate" );
	With ( "Roles (create)" );
	Put ( "#User", Env.user );
	Pick ( "#Role", "Warehouse Manager" );
	Click ( "#Apply" );
	
	// ***********************************
	// Receive Items
	// ***********************************
	
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = Env.receiveDate;
	p.Warehouse = Env.warehouse;
	p.Account = "8111";
	p.Expenses = "_SalesOrder";
	
	goods = new Array ();
	
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = "_Item1: " + id;
	row.CountPackages = false;
	row.Quantity = "150";
	row.Price = "7";
	goods.Add ( row );
	
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = "_Item2, countPkg: " + id;
	row.CountPackages = true;
	row.Quantity = "65";
	row.Price = "70";
	goods.Add ( row );
	
	p.Items = goods;
	Call ( "Documents.ReceiveItems.Receive", p );
	
	// ***********************************
	// Create Sales Order
	// ***********************************
	
	p = Call ( "Documents.SalesOrder.CreateApproveOneUser.Params" );
	p.Date = Env.date;
	p.Warehouse = Env.warehouse;
	p.Customer = Env.customer;
	p.Terms = Env.terms;
	p.Department = Env.department;
	
	orderItems = new Array ();
	i = 1;
	for each row in goods do
		itemRow = Call ( "Documents.SalesOrder.CreateApproveOneUser.ItemsRow" );
		FillPropertyValues ( itemRow, row );
		price = Number ( row.Price );
		itemRow.Price = ( price * 2 ) + ( price * i ) + 50;
		itemRow.Reservation = "None";
		itemRow.UseQuantity = true;
		orderItems.Add ( itemRow );
		i = i + 1;
	enddo;
	
	orderServices = new Array ();
	row = Call ( "Documents.Invoice.Sale.ServicesRow" );
	row.Item = "_Service1: " + id;
	row.Quantity = "1";
	row.Price = "1500";
	orderServices.Add ( row );
	
	row = Call ( "Documents.Invoice.Sale.ServicesRow" );
	row.Item = "_Service2: " + id;
	row.Quantity = "2";
	row.Price = "500";
	orderServices.Add ( row );
	
	p.Items = orderItems;
	p.Services = orderServices;
	Call ( "Documents.SalesOrder.CreateApproveOneUser", p );
	
	Call ( "Common.StampData", id );
	
	
EndProcedure

