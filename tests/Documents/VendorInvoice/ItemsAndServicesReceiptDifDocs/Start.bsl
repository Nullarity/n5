Call ( "Common.Init" );
CloseAll ();

date = CurrentDate ();
warehouse = "_VendorInvoice Warehouse: " + date;

p = Call ( "Documents.VendorInvoice.Buy.Params" );
p.Date = date - 86400;
p.Vendor = "_Vendor: " + date;
p.Warehouse = warehouse;
p.Expenses = "_TestExpense: " + date;

goods = new Array ();

row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
row.Item = "_Item1: " + date;
row.CountPackages = false;
row.CostMethod = "FIFO";
row.Quantity = "150";
row.Price = "7";
goods.Add ( row );

row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
row.Item = "_Item2, countPkg: " + date;
row.CountPackages = true;
row.CostMethod = "Avg";
row.Quantity = "65";
row.Price = "70";
goods.Add ( row );

p.Items = goods;
p.DateBeforeVendor = false;
itemDocParams = Call ( "Documents.VendorInvoice.Buy", p );
Close ();

//Services document

p.Items = new Array ();

goods = new Array ();

row = Call ( "Documents.VendorInvoice.Buy.ServicesRow" );
row.Item = "_Service1: " + date;
row.Account = "8111";
row.Quantity = "150";
row.Price = "7";
goods.Add ( row );

row = Call ( "Documents.VendorInvoice.Buy.ServicesRow" );
row.Item = "_Service2: " + date;
row.Account = "8111";
row.Quantity = "65";
row.Price = "70";
goods.Add ( row );

p.Services = goods;

p.ServicesIntoItems = true;
p.ServicesIntoDocument = itemDocParams.Number;

Call ( "Documents.VendorInvoice.Buy", p );
Call ( "Documents.VendorInvoice.ItemsAndServicesReceiptDifDocs.Logic" );

