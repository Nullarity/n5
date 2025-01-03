﻿Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27237FCA" );
env = getEnv ( id );
createEnv ( env );


Commando ("e1cib/list/Document.IntangibleAssetsWriteOff");
list = With ( "Intangible Assets Write Offs" );
p = Call ( "Common.Find.Params");
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );
Click ( "#ListContextMenuChange" );

With ( "Intangible Assets Write Off*" );

Click ( "#FormDataProcessorAssetsWriteOffWriteOff" );
With ( "Write Off: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	date = CurrentDate ();
	p.Insert ( "Date", date );
	p.Insert ( "YearStart", BegOfYear ( date ) );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Expense", "Expenses " + ID );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "ExpenseMethod", "Expense method " + ID );
	if ( Call ( "Common.AppIsCont" ) ) then
		p.Insert ( "ExpenseAccount", "7141" );
		p.Insert ( "AssetAccount", "1125" );
		p.Insert ( "AmortizationAccount", "1135" );
	else
		p.Insert ( "ExpenseAccount", "8111" );
		p.Insert ( "AssetAccount", "17100" );
		p.Insert ( "AmortizationAccount", "17200" );
	endif;
	return p;

EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	date = Env.Date;
	yearStart = Env.YearStart;
	warehouse = Env.Warehouse;
	expense = Env.Expense;
	employee = Env.Employee;
	department = Env.Department;
	expenseMethod = Env.ExpenseMethod;
	expenseAccount = Env.ExpenseAccount;
	assetAccount = Env.AssetAccount;
	amortizationAccount = Env.AmortizationAccount;
	
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
	// Create Intangible Assets Commissioning
	// ***********************************

	Commando ( "e1cib/data/Document.IntangibleAssetsCommissioning" );
	form = With ( "Intangible Assets Commissioning (create)" );

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
		
		With ( "Intangible Asset" );
		Put ( "#Item", row.Item );
		Set ( "#Quantity", row.Quantity );
		account = row.Account;
		if ( account <> undefined ) then
			Set ( "#Account", account );
		endif;
		f = Get ( "#IntangibleAsset" );
		f.OpenDropList ();
		f.Create ();
		formAssets = With ( "Intangible Assets (create)" );
		
		Set ( "#Account", assetAccount );
		Set ( "#AmortizationAccount", amortizationAccount );
		
		Choose ( "#AssetType" );
		params = Call ( "Common.Select.Params" );
		params.Object = Meta.Catalogs.AssetTypes;
		params.Search = "AssetType " + BegOfDay ( CurrentDate () );
		params.CreateScenario = "Catalogs.AssetTypes.Create";
		Call ( "Common.Select", params );
		With ( formAssets );
		
		Click ( "#FormWrite" );
		Close ();
		
		With ( "Intangible Asset" );

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
			
		With ( "Intangible Asset" );

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
	// Create IntangibleAssetsWriteOff
	// ***********************************


	Commando ("e1cib/data/Document.IntangibleAssetsWriteOff");
	form = With ( "Intangible Assets Write Off (create)" );

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
		With ( "Intangible assets" );
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
	Put ("#Memo",id);
	Click ( "#FormPost" );

	RegisterEnvironment ( id );

EndProcedure

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


