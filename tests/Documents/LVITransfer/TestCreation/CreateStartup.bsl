StandardProcessing = false;

date = _.Date;
curDate = CurrentDate ();
warehouse = "_Startup Warehouse: " + date;

p = Call ( "Documents.VendorInvoice.Buy.Params" );
p.Date = date - 86400;
p.Vendor = "_Vendor: " + date;
p.Warehouse = warehouse;

goods = new Array ();

row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
row.Item = _.LVI;
row.CountPackages = false;
row.CostMethod = "FIFO";
row.Quantity = "1";
row.Price = "1000";
goods.Add ( row );

p.Items = goods;
Call ( "Documents.VendorInvoice.Buy", p );

With ( "Vendor invoice*" );
Click ( "#FormDocumentStartupCreateBasedOn" );

formMain = With ( "LVI Startup (create)*" );
Set ( "#CostLimit", 200 );
Put ( "#Memo", _.ID );

With ( formMain );
table = Activate ("#Items" );
Activate ( "!ItemsItem [ 1 ]", table );
Click ( "#ItemsChange" );

form = With ( "LVI" );
Choose ( "#Employee" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Employees;
p.CreateScenario = "Catalogs.Employees.Create";
p.Search = _.EmployeeSender;
//p.App = "Core";
par = Call ( "Catalogs.Employees.Create.Params" );
par.Description = p.Search;
p.CreationParams = par;
Call ( "Common.Select", p );

With ( form );
Choose ( "#ItemsExpense" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Expenses;
p.CreateScenario = "Catalogs.Expenses.Create";
p.Search = _.Expense;
Call ( "Common.Select", p );
	
With ( form );
Choose ( "#Department" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Departments;
p.CreateScenario = "Catalogs.Departments.Create";
p.Search = _.DepartmentSender;
par = Call ( "Catalogs.Departments.Create.Params" );
par.Description = p.Search;
par.Company = "ABC Distributions";
p.CreationParams = par;
Call ( "Common.Select", p );

With ( form );
Set ( "#ExpenseAccount", "7141" );
if ( _.Property ( "ResidualValue" ) ) then
	Set ( "!ResidualValue", _.ResidualValue );
endif;	

Click ( "#FormOK" );

With ( formMain );
Activate ( "#GroupMore" );
Set ( "#ExploitationAccount", "2132" );
Set ( "#AmortizationAccount", "2141" );

Click ( "#FormPost" );