env = getEnv ( _ );
id = Env.ID;
if ( EnvironmentExists(id) ) then
	return env;
endif;

// ***********************************
// Create Compensation
// ***********************************

p = Call ( "CalculationTypes.Compensations.Create.Params" );
p.Description = Env.Compensation;
Call ( "CalculationTypes.Compensations.Create", p );

// ***********************************
// Create ReceiveItems
// ***********************************

p = Call ( "Documents.ReceiveItems.Receive.Params" );
p.Date = Call ( "Common.USFormat", env.date - 86400 );
p.Warehouse = Env.Warehouse;

if ( Call ( "Common.AppIsCont" ) ) then
	p.Account = "7141";
else
	p.Account = "8111";
endif;
p.Expenses = Env.expense;
message ( AppName );
p.Items = Env.Items;
Call ( "Documents.ReceiveItems.Receive", p );

// Employees

// create
p = Call ( "Catalogs.Employees.Create.Params" );
for each row in Env.Employees do
	p.Description = row.Employee;
	Call ( "Catalogs.Employees.Create", p );
enddo;

Call ( "Common.OpenList", Meta.Documents.Commissioning );
Click ( "#FormCreate" );
form = With ( "Commissioning (create)" );
Activate ( "Stakeholders" );
p = Call ( "Documents.Hiring.Create.Params" );
p.Employees = Env.Employees;
p.Insert ( "App" );
Call ( "Documents.Hiring.Create", p );

CloseAll ();

// ***********************************
// Create Commissioning
// ***********************************

Call ( "Common.OpenList", Meta.Documents.Commissioning );
Click ( "#FormCreate" );
form = With ( "Commissioning (create)" );

Set ( "#Warehouse", Env.warehouse );
Put ( "#Memo", env.ID );
Choose ( "#Employee" );
employeeName = Env.employee;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Employees;
params.Search = employeeName;
creation = Call ( "Catalogs.Employees.Create.Params" );
creation.Description = employeeName;
params.CreationParams = creation;
params.CreateScenario = "Catalogs.Employees.Create";
Call ( "Common.Select", params );
	
With ( form );

Choose ( "#Department" );
departmentName = Env.department;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Departments;
params.Search = departmentName;
creation = Call ( "Catalogs.Departments.Create.Params" );
creation.Description = departmentName;
userSettings = Call ( "Catalogs.UserSettings.Get" );
company = userSettings.Company;
creation.Company = company;
params.CreationParams = creation;
params.CreateScenario = "Catalogs.Departments.Create";
Call ( "Common.Select", params );
	
With ( form );

table = Activate ( "#Items" );
firstRow = true;
fixedAssetAccount = env.FixedAssetAccount;
for each row in env.Items do
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
	Set ( "#CertificateNo", "444444" );
	Choose ( "#AssetType" );
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.AssetTypes;
	params.Search = "AssetType " + Env.ID;
	params.CreateScenario = "Catalogs.AssetTypes.Create";
	Call ( "Common.Select", params );
	With ( formAssets );
	Set ( "#ProductionDate", Format ( CurrentDate (), "DLF = 'D'" ) );
	
	Click ( "#FormWrite" );
	Close ();
	
	With ( "Fixed Asset" );

	Choose ( "#Schedule" );
	sheduleName = env.shedule;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.DepreciationSchedules;
	params.Search = sheduleName;
	creation = Call ( "Catalogs.DepreciationSchedules.Create.Params" );
	creation.Description = sheduleName;
	params.CreationParams = creation;
	params.CreateScenario = "Catalogs.DepreciationSchedules.Create";
	Call ( "Common.Select", params );
		
	With ( "Fixed Asset" );

	Choose ( "#Expenses" );
	expenseName = env.expenseMethod;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.ExpenseMethods;
	params.Search = expenseName;
	creation = Call ( "Catalogs.ExpenseMethods.Create.Params" );
	creation.Description = expenseName;
	creation.Expense = env.expense;
	creation.Account = env.expenseAccount;
	params.CreationParams = creation;
	params.CreateScenario = "Catalogs.ExpenseMethods.Create";
	Call ( "Common.Select", params );
		
	With ( "Fixed Asset" );

	Set ( "#LiquidationValue", 150 );
	Set ( "#UsefulLife", 2 );
	
	Click ( "#FormOK" );
	
	With ( form );
enddo;
table.DeleteRow ();
Click ( "#FormPost" );

fillStakeholders ( form, env.Employees );
With ( form );
Click ( "#FormPost" );
RegisterEnvironment(id);
return env;

// ***********************************
// Procedures
// ***********************************

Function getEnv ( ID )

	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Date", CurrentDate () );
	env.Insert ( "Warehouse", "_Warehouse: " + id );
	env.Insert ( "Expense", "_Expenses: " + id );
	env.Insert ( "Employee", "_Employee: " + id );
	env.Insert ( "Department", "_Department: " + id );
	if ( Call ( "Common.AppIsCont" ) ) then
		env.Insert ( "FixedAssetAccount", "1231" );
		env.Insert ( "ExpenseAccount", "7141" );
	else
		env.Insert ( "FixedAssetAccount", "15000" );
		env.Insert ( "ExpenseAccount", "8111" );
	endif;	
	env.Insert ( "Shedule", "_Shedule" );
	env.Insert ( "ExpenseMethod", "_Expense method: " + id );
	env.Insert ( "Recieve", "65" );
	env.Insert ( "Overlimit", "80" );             
	//tested capacity = 5
	env.Insert ( "RecievePkg", "13" );
	env.Insert ( "OverlimitPkg", "16" );
	compensation = "_Compensation" + id;
	env.Insert ( "Compensation", compensation );             
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
	row.Quantity = Env.recieve;
	row.Price = "70";
	goods.Add ( row );
	
	row = Call ( "Documents.ReceiveItems.Receive.Row" );
	row.Item = "_Item3: " + id;
	row.CountPackages = true;
	row.Quantity = "10";
	row.Price = "20";
	goods.Add ( row );
	
	env.Insert ( "Items", goods );
	
	employees = new Array ();
	date = BegOfYear ( Env.Date );
	department = "Administration";
	
	employees.Add ( newEmployee ( "_Approved: " + id, date, department, "Director", compensation ) );
	employees.Add ( newEmployee ( "_Head: " + id, date, department, "Manager", compensation ) );
	employees.Add ( newEmployee ( "_Member1: " + id, date, department, "Accountant", compensation ) );
	employees.Add ( newEmployee ( "_Member2: " + id, date, department, "Stockman", compensation ) );
	env.Insert ( "Employees", employees );
	return env;

EndFunction

Function newEmployee ( Employee, DateStart, Department, Position, Compensation )

 	p = Call ( "Documents.Hiring.Create.Row" );
	p.Employee = Employee;
	p.DateStart = DateStart;
	p.Department = Department;
	p.Position = Position;
	p.Compensation = Compensation;
	return p;

EndFunction

Procedure fillStakeholders ( Form, Employees )
	
	Activate ( "Stakeholders" );
	
    approved = Employees [ 0 ];
	head = Employees [ 1 ];

	setValue ( "#Approved", approved.Employee );
	Activate ( "#ApprovedPosition" );
	Check ( "#ApprovedPosition", approved.Position );

	setValue ( "#Head", head.Employee );
	Activate ( "#HeadPosition" );
	Check ( "#HeadPosition", head.Position );
	
	// *********************
	// Fill members
	// *********************
	
	table = Activate ( "#Members" );
	Call ( "Table.Clear", table );
	for i = 2 to 3 do
		member = Employees [ i ];

		Click ( "#MembersAdd" );
		setValue ( "#MembersMember", member.Employee );
		table.EndEditRow ();
		
		Check ( "#MembersPosition", member.Position, table );
	enddo;
	
EndProcedure

Procedure setValue ( Field, Value )

	form = CurrentSource;
	Choose ( Field );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", "Employees" );
	Click ( "#OK" );
	With ( "Employees" );
	GotoRow ( "#List", "Description", Value );
	Click ( "#FormChoose" );
	CurrentSource = form;
	
EndProcedure
