Call ( "Common.Init" );
CloseAll ();

date = CurrentDate ();
invoiceDate = BegOfDay ( date );
warehouse = "_Invoice Warehouse";
customer = "_Customer: " + date;
paymentOptions = "15#";
terms = "100% prepay, 15#";

// ***********************************
// Create PaymentOption
// ***********************************

params = Call ( "Catalogs.PaymentOptions.Create.Params" );
params.Description = paymentOptions;
rows = params.Discounts;
row = Call ( "Catalogs.PaymentOptions.Create.Row" );
row.During = 15;
row.Discount = 2;
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
// Create Customer
// ***********************************

params = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
params.Description = customer;
params.Terms = terms;

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Organizations;
p.Description = customer;
p.CreateScenario = "Catalogs.Organizations.CreateCustomer";
p.CreationParams = params;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Create Invoice
// ***********************************

MainWindow.ExecuteCommand ( "e1cib/data/Document.Invoice" );

form = With ( "Invoice (create)" );
Set ( "Date", invoiceDate ); // It is important to be first

Choose ( "#Customer" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Organizations;
p.CreateScenario = "Catalogs.Organizations.CreateCustomer";
customerData = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
customerData.Description = customer;
p.CreationParams = customerData;
p.Search = customer;
Call ( "Common.Select", p );

With ( form );

Choose ( "#Warehouse" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = warehouse;
Call ( "Common.Select", p );

With ( form );
Set ( "#Warehouse", warehouse );
form.GotoNextItem ();

Check ( "#PaymentOption", paymentOptions );
Check ( "#PaymentDate", Fetch ( "#Date" ) );
