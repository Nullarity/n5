Call ( "Common.Init" );
CloseAll ();

date = CurrentDate ();
warehouse = "_Warehouse: " + date;
expense = "_Expenses: " + date;
employee = "_Employee: " + date;
department = "_Department: " + date;
fixedAssetAccount = "15000";
shedule = "_Shedule";
expenseMethod = "_Expense method: " + date;
expenseAccount = "8111";

// ***********************************
// Create ReceiveItems
// ***********************************

p = Call ( "Documents.ReceiveItems.Receive.Params" );
p.Date = date - 86400;
p.Warehouse = warehouse;
p.Account = "8111";
p.Expenses = "_WriteOff";

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
// Create Commissioning
// ***********************************

Call ( "Common.OpenList", Meta.Documents.Commissioning );
Click ( "#FormCreate" );
form = With ( "Commissioning (create)" );

Set ( "#Warehouse", warehouse );
Choose ( "#Employee" );
employeeName = employee;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Employees;
params.Search = employeeName;
creation = Call ( "Catalogs.Employees.Create.Params" );
creation.Description = employeeName;
params.CreationParams = creation;
Call ( "Common.Select", params );
	
With ( form );

Choose ( "#Department" );
departmentName = department;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Departments;
params.Search = departmentName;
creation = Call ( "Catalogs.Departments.Create.Params" );
creation.Description = departmentName;
userSettings = Call ( "Catalogs.UserSettings.Get" );
company = userSettings.Company;
creation.Company = company;
params.CreationParams = creation;
Call ( "Common.Select", params );
	
With ( form );

table = Activate ( "#Items" );
firstRow = true;
for each row in p.Items do
	if ( firstRow ) then
		firstRow = false;
	else
		Click ( "#ItemsAdd" );
	endif;
	
	With ( "Fixed Asset" );
	Set ( "#Item", row.Item );
	Set ( "#Quantity", row.Quantity );
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#Account", account );
	endif;
	f = Get ( "#FixedAsset" );
	f.OpenDropList ();
	f.Create ();
	formAssets = With ( "Fixed Assets (create)" );
	Set ( "#Account", fixedAssetAccount );
	Set ( "#AmortizationAccount", fixedAssetAccount );
	rng = new RandomNumberGenerator ();
	Set ( "#InventoryNo", rng.RandomNumber ( 100, 100000 ) );
	Set ( "#CertificateNo", 444444 );
	Set ( "#TaxGroup", "Group1" );
	Choose ( "#AssetType" );
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.AssetTypes;
	params.Search = "AssetType " + BegOfDay ( CurrentDate () );
	Call ( "Common.Select", params );
	With ( formAssets );
	Set ( "#ProductionDate", CurrentDate () );
	
	Click ( "#FormWrite" );
	Close ();
	
	With ( "Fixed Asset" );

	Choose ( "#Schedule" );
	sheduleName = shedule;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.DepreciationSchedules;
	params.Search = sheduleName;
	creation = Call ( "Catalogs.DepreciationSchedules.Create.Params" );
	creation.Description = sheduleName;
	params.CreationParams = creation;
	Call ( "Common.Select", params );
		
	With ( "Fixed Asset" );

	Choose ( "#Expenses" );
	expenseName = expenseMethod;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.ExpenseMethods;
	params.Search = expenseName;
	creation = Call ( "Catalogs.ExpenseMethods.Create.Params" );
	creation.Description = expenseName;
	creation.Expense = expense;
	creation.Account = expenseAccount;
	params.CreationParams = creation;
	Call ( "Common.Select", params );
	method = Fetch ( "#Method" );	
	With ( "Fixed Asset" );

	Set ( "#LiquidationValue", 150 );
	Set ( "#UsefulLife", 2 );
	Click ( "#FormOK" );
	
	With ( form );
enddo;
Click ( "#FormPost" );

// ***********************************
// Create DepreciationSetup
// ***********************************

Call ( "Common.OpenList", Meta.Documents.DepreciationSetup );
Click ( "#FormCreate" );
form = With ( "Depreciation Setup (create)" );

testControls ();

Choose ( "#Department" );
departmentName = department;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Departments;
params.Search = departmentName;
creation = Call ( "Catalogs.Departments.Create.Params" );
creation.Description = departmentName;
userSettings = Call ( "Catalogs.UserSettings.Get" );
company = userSettings.Company;
creation.Company = company;
params.CreationParams = creation;
Call ( "Common.Select", params );
	
With ( form );

Click ( "#MethodChange" );

Put ( "#Method", method );

Choose ( "#Schedule" );
sheduleName = shedule;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.DepreciationSchedules;
params.Search = sheduleName;
creation = Call ( "Catalogs.DepreciationSchedules.Create.Params" );
creation.Description = sheduleName;
params.CreationParams = creation;
Call ( "Common.Select", params );
	
With ( form );

Set ( "#LiquidationValue", 200 );

Click ( "#FormPost" );
Run ( "Logic" );

// ***********************************
// Functions
// ***********************************

Procedure testControls ()

	// ***********************************
	// Test Disabled & Enabled items
	// ***********************************

	CheckState ( "#Method, #Acceleration, #Schedule, #LiquidationValue, #UsefulLife, #Expenses", "Enable", false );
	CheckState ( "#MethodChange, #UsefulLifeChange, #ExpensesChange, #Charge", "Enable" );

	Click ( "#MethodChange" );
	CheckState ( "#Method, #LiquidationValue", "Enable" );
	CheckState ( "#Acceleration, #Schedule", "Enable", false );

	Click ( "#UsefulLifeChange" );
	CheckState ( "#UsefulLife", "Enable" );

	Click ( "#ExpensesChange" );
	CheckState ( "#Expenses", "Enable" );
	
	// Return all options back
	Click ( "#MethodChange" );
	Click ( "#UsefulLifeChange" );
	Click ( "#ExpensesChange" );
	
EndProcedure
