
env = getEnv ( _ );
createEnv ( env );

Call ( "Common.OpenList", Meta.Documents.AssetsInventory );
Click ( "#FormCreate" );

form = With ( "Assets Inventory (create)" );

Set ( "#Department",env.Department );
Set ( "#Employee", env.Employee );
Put ( "#Memo", env.IDMemo );

table = Activate ( "#ItemsTable" );
Click ( "#ItemsTableDelete" );
Click ( "#ItemsFill" );
Click ( "Yes", DialogsTitle );
p = Call ( "Common.Row.Params");
p.Table = table;
p.Column = "#ItemsAvailability";
p.Row = 1;
Call ( "Common.Row", p );
table.ChangeRow ();
With ( "Assets Inventory (create) *" );
Click ( "#ItemsAvailability" );
table.EndEditRow ();

Click ( "#FormPost" );
Click ( "#FormDocumentAssetsWriteOffCreateBasedOn" );
if ( not Call ( "Common.AppIsCont" ) ) then
	Run ( "WriteOffBaseOn", env );
endif;	

return env;

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	env = new Structure ();
	env.Insert ( "ID", ID );
	env.Insert ( "Date", CurrentDate () );
	env.Insert ( "IDMemo", ID );
	env.Insert ( "Warehouse", "_Warehouse: " + ID );
	env.Insert ( "Expense" , "_Expenses: " + ID );
	env.Insert ( "Employee", "_Employee: " + ID );
	env.Insert ( "Department", "_Department: " + ID );
	if ( Call ( "Common.AppIsCont" ) ) then
		expenseAccount = "7141";
		assetAccount = "1231";
		account = "2171";
	else
		expenseAccount = "8111";
		assetAccount = "15000";
		account = "2171";
	endif;
	env.Insert ( "FixedAssetAccount", assetAccount );
	env.Insert ( "Shedule", "_Shedule" );
	env.Insert ( "ExpenseMethod", "_Expense method: " + ID );
	env.Insert ( "ExpenseAccount", expenseAccount );
	env.Insert ( "Recieve", "65" );
	env.Insert ( "Overlimit", "80" );             
	env.Insert ( "Item3", "_Item3: " + id );
	//tested capacity", 5
	env.Insert ( "RecievePkg", "13" );
	env.Insert ( "OverlimitPkg", "16" );
	env.Insert ( "Account", account );
	return env;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// ***********************************
	// Create ReceiveItems
	// ***********************************
	
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = Env.Date - 86400;
	p.Warehouse = Env.Warehouse;
	p.Account = Env.ExpenseAccount;
	p.Expenses = Env.Expense;
	
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
	row.Quantity = Env.Recieve;
	row.Price = "70";
	goods.Add ( row );
	
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = "_Item3: " + id;
	row.CountPackages = false;
	row.Quantity = "200";
	row.Price = "7";
	goods.Add ( row );
	
	p.Items = goods;
	Call ( "Documents.ReceiveItems.Receive", p );
	
	// ***********************************
	// Create Commissioning
	// ***********************************
	
	Call ( "Common.OpenList", Meta.Documents.Commissioning );
	Click ( "#FormCreate" );
	form = With ( "Commissioning (create)" );
	
	Set ( "#Warehouse", Env.Warehouse );
	Choose ( "#Employee" );
	employeeName = Env.Employee;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.Employees;
	params.Search = employeeName;
	creation = Call ( "Catalogs.Employees.Create.Params" );
	creation.Description = employeeName;
	params.CreationParams = creation;
	//params.App = "Core";
	Call ( "Common.Select", params );
	
	With ( form );
	
	Choose ( "#Department" );
	departmentName = Env.Department;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.Departments;
	params.Search = departmentName;
	creation = Call ( "Catalogs.Departments.Create.Params" );
	creation.Description = departmentName;
	userSettings = Call ( "Catalogs.UserSettings.Get" );
	company = userSettings.Company;
	creation.Company = company;
	params.CreationParams = creation;
	//params.App = "Core";
	Call ( "Common.Select", params );
	
	With ( form );
	
	table = Activate ( "#Items" );
	firstRow = true;
	i = 1;
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
		Set ( "#Account", Env.FixedAssetAccount );
		Set ( "#AmortizationAccount", Env.FixedAssetAccount );
		rng = new RandomNumberGenerator ();
		Set ( "#InventoryNo", rng.RandomNumber ( 100, 100000 ) );
		Set ( "#CertificateNo", 444444 );
		if ( AppName <> "c5" ) then
			Set ( "#TaxGroup", "Group1" );
		endif;
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
		sheduleName = Env.Shedule;
		params = Call ( "Common.Select.Params" );
		params.Object = Meta.Catalogs.DepreciationSchedules;
		params.Search = sheduleName;
		creation = Call ( "Catalogs.DepreciationSchedules.Create.Params" );
		creation.Description = sheduleName;
		params.CreationParams = creation;
		//params.App = "Core";
		Call ( "Common.Select", params );
		
		With ( "Fixed Asset" );
		
		Choose ( "#Expenses" );
		expenseName = Env.ExpenseMethod;
		params = Call ( "Common.Select.Params" );
		params.Object = Meta.Catalogs.ExpenseMethods;
		params.Search = expenseName;
		creation = Call ( "Catalogs.ExpenseMethods.Create.Params" );
		creation.Description = expenseName;
		creation.Expense = Env.Expense;
		creation.Account = Env.ExpenseAccount;
		params.CreationParams = creation;
		//params.App = "Core";
		Call ( "Common.Select", params );
		
		With ( "Fixed Asset" );
		
		Set ( "#LiquidationValue", 150 );
		Set ( "#UsefulLife", 2 );
		if ( i = 3 ) then
			Click ( "#FormClose" );
		else
			Click ( "#FormOK" );
		endif;	
		
		With ( form );
		i = i + 1;
	enddo;
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure

