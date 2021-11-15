
Call ( "Common.Init" );
CloseAll ();

date = CurrentDate ();
receiveDate = date - 86400 * 2;
invoiceDate = receiveDate + 86400;
warehouse = "_Invoice Warehouse";
customer = "_Customer: " + date;
paymentOptions = "0-1-5#";
terms = "100% prepay, 0-1-5#";

// ***********************************
// Create PaymentOption
// ***********************************

params = Call ( "Catalogs.PaymentOptions.Create.Params" );
params.Description = paymentOptions;
rows = params.Discounts;
row = Call ( "Catalogs.PaymentOptions.Create.Row" );
row.During = 0;
row.Discount = 15;
rows.Add ( row );
row = Call ( "Catalogs.PaymentOptions.Create.Row" );
row.During = 1;
row.Discount = 10;
rows.Add ( row );
row = Call ( "Catalogs.PaymentOptions.Create.Row" );
row.During = 5;
row.Discount = 5;
rows.Add ( row );

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
p.Date = receiveDate;
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
// Create Invoice
// ***********************************

p = Call ( "Documents.Invoice.Sale.Params" );
p.Date = invoiceDate;
p.Warehouse = warehouse;
p.Customer = customer;
p.Terms = terms;

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
// Payment on the same day
// ***********************************

Call ( "Common.OpenList", Meta.Documents.Payment );
Click ( "#FormCreate" );
form = With ( "Customer Payment (create)" );

Set ( "#Date", invoiceDate + 1 );
Set ( "#Customer", customer );
Set ( "#Amount", 5000 );
Set ( "#Currency", "USD" );

form.GotoNextItem ();

Click ( "#FormPost" );
Run ( "Logic" );
Run ( "Debts", customer );
//Run ( "DebtDetails", customer );
