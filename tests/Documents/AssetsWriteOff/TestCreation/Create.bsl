date = CurrentDate ();
yearStart = BegOfYear ( date );
id = _;
warehouse = "_Warehouse: " + id;
expense = "_Expenses: " + id;
employee = "_Employee: " + id;
department = "_Department: " + id;
shedule = "_Shedule";
expenseMethod = "_Expense method: " + id;
if ( Call ( "Common.AppIsCont" ) ) then
	expenseAccount = "7141";
	assetAccount = "1231";
	amortizationAccount = "1241";
else
	expenseAccount = "8111";
	assetAccount = "15000";
	amortizationAccount = "17000";
endif;	

// ***********************************
// Create ReceiveItems
// ***********************************

p = Call ( "Documents.ReceiveItems.Receive.Params" );
p.Date = date - 86400;
p.Warehouse = warehouse;
p.Account = expenseAccount;
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
params.CreateScenario = "Catalogs.Employees.Create";
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
params.CreateScenario = "Catalogs.Departments.Create";
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
	Put ( "#Item", row.Item );
	Set ( "#Quantity", row.Quantity );
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#Account", account );
	endif;
	f = Get ( "#FixedAsset" );
	f.OpenDropList ();
	f.Create ();
	formAssets = With ( "Fixed Assets (create)" );
	
	Set ( "#Account", assetAccount );
	Set ( "#AmortizationAccount", amortizationAccount );
	
	rng = new RandomNumberGenerator ();
	Set ( "#InventoryNo", rng.RandomNumber ( 100, 100000 ) );
	Set ( "#CertificateNo", 444444 );
	Choose ( "#AssetType" );
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.AssetTypes;
	params.Search = "AssetType " + BegOfDay ( CurrentDate () );
	params.CreateScenario = "Catalogs.AssetTypes.Create";
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
	params.CreateScenario = "Catalogs.DepreciationSchedules.Create";
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
	params.CreateScenario = "Catalogs.ExpenseMethods.Create";
	Call ( "Common.Select", params );
		
	With ( "Fixed Asset" );

	Set ( "#LiquidationValue", 150 );
	Set ( "#UsefulLife", 2 );
	Click ( "#FormOK" );
	
	With ( form );
enddo;
Click ( "#FormPost" );

// ***********************************
// Create Entry
// ***********************************

array = new Array ();
i = 1;
for each row in p.Items do
	array.Add ( new Structure ( "Asset, Amount", row.Item, 100 * i ) );
	i = i + 1;
enddo;
param = new Structure ( "Date, Assets", date, array );
Run ( "CreateEntryDepreciation", param );

// ***********************************
// Create AssetsWriteOff
// ***********************************


Call ( "Common.OpenList", Meta.Documents.AssetsWriteOff );
Click ( "#FormCreate" );
form = With ( "Assets Write Off (create)" );

Set ( "#ExpenseAccount", expenseAccount );
form.GotoNextItem ();
Set ( "#Dim1", expense );
form.GotoNextItem ();
Put ( "#Dim2", department );


table = Activate ( "#Items" );
firstRow = true;
for each row in p.Items do
	if ( firstRow ) then
		firstRow = false;
	else
		Click ( "#ItemsAdd" );
	endif;
	
	Choose ( "#ItemsItem", table );
	With ( "Fixed assets" );
	list = Activate ( "#List" );
	Click ( "Command bar / View mode / List" );
	search = new Map ();
	search.Insert ( "Description", row.Item );
	list.GotoRow ( search, RowGotoDirection.Down );
	Click ( "Command bar / Select" );
	With ( form );
enddo;
Call ( "Table.CopyEscapeDelete", table );

employees = hireEmployees ( date, yearStart, id );
fillStakeholders ( form, employees );

Call ( "Common.CheckCurrency", form );

Click ( "#FormPost" );

Function hireEmployees ( Date, DateStart, id )

	id = Call ( "Common.ScenarioID", id );
	compensation = "_Wage " + id;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = compensation;
	if ( Call ( "Common.AppIsCont" ) ) then
		p.Account = "5344";
	endif;	
	Call ( "CalculationTypes.Compensations.Create", p );

    p = Call ( "Documents.Hiring.Create.Params" );
	employees = new Array ();
	employees.Add ( newEmployee ( "_Approved: " + id, DateStart, "Administration", "Director", compensation ) );
	employees.Add ( newEmployee ( "_Head: " + id, DateStart, "Administration", "Manager", compensation ) );
	employees.Add ( newEmployee ( "_Member1: " + id, DateStart, "Administration", "Accountant", compensation ) );
	employees.Add ( newEmployee ( "_Member2: " + id, DateStart, "Administration", "Stockman", compensation ) );
	p.Employees = employees;
	
	params = Call ( "Catalogs.Employees.Create.Params" );
	for each row in employees do
	    params.Description = row.Employee;
	    Call ( "Catalogs.Employees.Create", params );
	enddo;
	
	p.Insert ( "App" );
	if ( not RegisterEnvironment ( id ) ) then
		Call ( "Documents.Hiring.Create", p );
		RegisterEnvironment ( id );
	endif;
	return employees;

EndFunction

Function newEmployee ( Employee, DateStart, Department, Position, Compensation )

 	p = Call ( "Documents.Hiring.Create.Row" );
	p.Insert ( "Employee", Employee );
	p.Insert ( "DateStart", DateStart );
	p.Insert ( "Department", Department );
	p.Insert ( "Position", Position );
	p.Insert ( "Compensation", Compensation );
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


