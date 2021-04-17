Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.GetID" );
date = CurrentDate ();
receiveDate = date - 86400;
customer = "_SO Customer: " + date;
warehouse = "_SO Warehouse# " + id;
department = "_Sales with Shipmets " + id;
user = Call ( "Common.User" );
userSettings = Call ( "Catalogs.UserSettings.Get" );
company = userSettings.Company;
paymentOptions = "nodiscount#";
terms = "100% prepay, 0-1-5#";

// ***********************************
// Create Department
// ***********************************

params = Call ( "Catalogs.Departments.Create.Params" );
params.Description = department;
params.Shipments = true;
params.Company = company;

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Departments;
p.Description = params.Description;
p.CreationParams = params;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Create PaymentOption
// ***********************************

params = Call ( "Catalogs.PaymentOptions.Create.Params" );
params.Description = paymentOptions;

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.PaymentOptions;
p.Description = params.Description;
p.CreationParams = params;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Create Terms
// ***********************************

params = Call ( "Catalogs.Terms.Create.Params" );
params.Description = terms;
payments = params.Payments;
row = Call ( "Catalogs.Terms.Create.Row" );
row.Option = paymentOptions;
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
Put ( "#User", user );
Pick ( "#Role", "Department Head" );
Set ( "#Department", department );
CurrentSource.GotoNextItem ();
Click ( "#Apply" );

//With ( DialogsTitle );
//Click ( "Yes" );

// ***********************************
// Roles: Warehouse manager
// ***********************************

MainWindow.ExecuteCommand ( "e1cib/list/Document.Roles" );
list = With ( "Roles" );
Click ( "#FormCreate" );
With ( "Roles (create)" );
Put ( "#User", user );
Pick ( "#Role", "Warehouse Manager" );
Click ( "#Apply" );

//With ( DialogsTitle );
//Click ( "Yes" );

// ***********************************
// Receive Items
// ***********************************

p = Call ( "Documents.ReceiveItems.Receive.Params" );
p.Date = receiveDate;
p.Warehouse = warehouse;
p.Account = "8111";
p.Expenses = "_SalesOrder";

goods = new Array ();

row = Call ( "Documents.ReceiveItems.Receive.Row" );
row.Item = "_Item1: " + date;
row.CountPackages = false;
row.Quantity = "150";
row.Price = "7";
//row.UseItemsQuantityPkg = true;
goods.Add ( row );

row = Call ( "Documents.ReceiveItems.Receive.Row" );
row.Item = "_Item2, countPkg: " + date;
row.CountPackages = true;
row.Quantity = "65";
row.Price = "70";
//row.UseItemsQuantityPkg = true;
goods.Add ( row );

p.Items = goods;
Call ( "Documents.ReceiveItems.Receive", p );

// ***********************************
// Create Sales Order
// ***********************************

p = Call ( "Documents.SalesOrder.CreateApproveOneUser.Params" );
p.Date = date;
p.Warehouse = warehouse;
p.Customer = customer;
p.Terms = terms;
p.Department = department;

orderItems = new Array ();
for each row in goods do
	itemRow = Call ( "Documents.SalesOrder.CreateApproveOneUser.ItemsRow" );
	FillPropertyValues ( itemRow, row );
	itemRow.Price = Number ( row.Price ) * 2;
	itemRow.Reservation = "None";
	itemRow.UseQuantity = true;
	orderItems.Add ( itemRow );
enddo;

orderServices = new Array ();
row = Call ( "Documents.Invoice.Sale.ServicesRow" );
row.Item = "_Service1: " + date;
row.Quantity = "1";
row.Price = "1500";
orderServices.Add ( row );

row = Call ( "Documents.Invoice.Sale.ServicesRow" );
row.Item = "_Service2: " + date;
row.Quantity = "2";
row.Price = "500";
orderServices.Add ( row );

p.Items = orderItems;
p.Services = orderServices;
Call ( "Documents.SalesOrder.CreateApproveOneUser", p );

// ***********************************
// Test Invoice
// ***********************************

Call ( "Common.OpenList", Meta.Documents.Invoice );
Set ( "#CustomerFilter", customer );
Clear ( "#WarehouseFilter" );
Click ( "#FormChange" );
With ( "Invoice #*" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Invoice*" );
CheckTemplate ( "TabDoc" );
