Call ( "Common.Init" );
CloseAll ();

date = CurrentDate ();
tomorrow = date + 86400;

warehouseName = "_Transactions Report: " + date;
itemName = "_Test Transactions Report#";
accountDr = "12100";
accountCr = "00000";
amount = "-700";
quantityDr = "-5";

// ***********************************
// Create Warehouse
// ***********************************

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Description = warehouseName;
p.CreationParams = warehouseName;
Call ( "Common.CreateIfNew", p );

// ***********************************
// Create Item
// ***********************************

Call ( "Catalogs.Items.CreateIfNew", itemName );

// ***********************************
// Create Entry
// ***********************************

p = Call ( "Documents.Entry.Create.Params" );

// Dr

row = Call ( "Documents.Entry.Create.Row" );
row.AccountDr = accountDr;
row.DimDr1 = itemName;
row.DimDr2 = warehouseName;
row.QuantityDr = quantityDr;

// Cr

row.AccountCr = accountCr;

row.Amount = amount;
p.Records.Add ( row );
row = Call ( "Documents.Entry.Create", p );

// ***********************************
// Open Report
// ***********************************

p = Call ( "Common.Report.Params" );
p.Path = "Accounting / Transactions";
p.Title = "Transactions*";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
item.ValueFrom = date;
item.ValueTo = date;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Account";
item.Value = accountDr;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Warehouses";
item.Value = warehouseName;
filters.Add ( item );

p.Filters = filters;
With ( Call ( "Common.Report", p ) );
CheckTemplate ( "#Result" );

// ***********************************
// Check balances on the next day
// ***********************************

Close ();

p = Call ( "Common.Report.Params" );
p.Path = "Accounting / Transactions";
p.Title = "Transactions*";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
item.ValueFrom = tomorrow;
item.ValueTo = tomorrow;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Account";
item.Value = accountDr;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Warehouses";
item.Value = warehouseName;
filters.Add ( item );

p.Filters = filters;
With ( Call ( "Common.Report", p ) );
Run ( "InitialBalance" );
