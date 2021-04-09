Call ( "Common.Init" );
CloseAll ();

date = CurrentDate ();
warehouse = "_Invoice Warehouse";
customer = "_Customer: " + date;
paymentOptions = "nodiscount#";
terms = "100% prepay, nodiscount#";

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
// Receive Items
// ***********************************

p = Call ( "Documents.ReceiveItems.Receive.Params" );
p.Date = date - 86400 * 2;
p.Warehouse = warehouse;
p.Account = "8111";
p.Expenses = "_Invoice";

goods = new Array ();

row = Call ( "Documents.ReceiveItems.Receive.Row" );
row.Item = "_Item1: " + date;
row.CountPackages = false;
row.Quantity = "150";
row.Price = "7";
goods.Add ( row );

row = Call ( "Documents.ReceiveItems.Receive.Row" );
row.Item = "_Item2, countPkg: " + date;
row.CountPackages = true;
row.Quantity = "65";
row.Price = "70";
goods.Add ( row );

p.Items = goods;

Call ( "Documents.ReceiveItems.Receive", p );

// ***********************************
// Create Customer
// ***********************************

params = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
params.Description = customer;
params.Terms = terms;

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Organizations;
p.Description = params.Description;
p.CreateScenario = "Catalogs.Organizations.CreateCustomer";
p.CreationParams = params;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Invoice
// ***********************************

p = Call ( "Documents.Invoice.Sale.Params" );
p.Date = date - 86400;
p.Warehouse = warehouse;
p.Customer = customer;

invoiceItems = new Array ();
for each row in goods do
	itemRow = Call ( "Documents.Invoice.Sale.ItemsRow" );
	FillPropertyValues ( itemRow, row );
	itemRow.Price = Number ( row.Price ) * 2;
	invoiceItems.Add ( itemRow );
enddo;

invoiceServices = new Array ();
row = Call ( "Documents.Invoice.Sale.ServicesRow" );
row.Item = "_Service1: " + date;
row.Quantity = "1";
row.Price = "1500";
invoiceServices.Add ( row );

row = Call ( "Documents.Invoice.Sale.ServicesRow" );
row.Item = "_Service2: " + date;
row.Quantity = "2";
row.Price = "500";
invoiceServices.Add ( row );

p.Items = invoiceItems;
p.Services = invoiceServices;
Call ( "Documents.Invoice.Sale", p );

// ***********************************
// Payment
// ***********************************

Call ( "Common.OpenList", Meta.Documents.Payment );
Click ( "#FormCreate" );
form = With ( "Customer Payment (create)" );

Set ( "#Customer", customer );
Set ( "#Amount", 6000 );
Set ( "#Currency", "USD" );

form.GotoNextItem ();

Click ( "#FormPost" );
Run ( "Logic" );
Run ( "Debts", customer );
//Run ( "DebtDetails", customer );
