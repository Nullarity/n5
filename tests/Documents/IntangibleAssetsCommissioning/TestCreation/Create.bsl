env = getEnv ( _ );
createEnv ( env );

Commando ( "e1cib/data/Document.IntangibleAssetsCommissioning" );
form = With ( "Intangible Assets Commissioning (create)" );

Activate ( "#Items" );
Close ( "Intangible Asset" );

Put ( "#Warehouse", Env.Warehouse );
Put ( "#Department", Env.Department );
Put ( "#Employee", Env.Responsible );
Put ( "#Memo", env.IDMemo );

fillStakeholders ( form, env );

With ( form );
table = Activate ( "#Items" );
firstRow = true;
i = 1;
for each item in Env.Items do

	if ( firstRow ) then
		firstRow = false;
	else
		Click ( "#ItemsAdd", table );
	endif;
	
	With ( "Intangible Asset" );
	Set ( "#Item", item.Name );
	Set ( "#Quantity", item.Quantity );
	Set ( "#IntangibleAsset", item.Name );
	Set ( "#UsefulLife", i );
	i = i + 1;
	Click ( "#Charge" );
	Set ( "#Starting", "01012027" );
	Put ( "#Expenses", Env.Expenses );
	Click ( "#FormOK" );
	
	With ( form );

enddo;

Click ( "#FormPost" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	env = new Structure ();
	env.Insert ( "ID", ID );
	env.Insert ( "IDMemo", ID );
	env.Insert ( "Date", CurrentDate () );
	env.Insert ( "Warehouse", "Main" );
	if ( Call ( "Common.AppIsCont" ) ) then
		env.Insert ( "ReceiveAccount", "6118" );
		env.Insert ( "Account", "112" );
		env.Insert ( "Amortization", "113" );
		env.Insert ( "ExpenseAccount", "7141" );
	else
		env.Insert ( "ReceiveAccount", "70100" );
		env.Insert ( "Account", "17100" );
		env.Insert ( "Amortization", "17200" );
		env.Insert ( "ExpenseAccount", "8111" );
	endif;	
	env.Insert ( "Department", "Administration" );
	env.Insert ( "Responsible", "_Responsible " + ID );
	env.Insert ( "Approved", "Approved " + ID );
	env.Insert ( "Head", "Head " + ID );
	env.Insert ( "Member1", "Member1 " + ID );
	env.Insert ( "Member2", "Member2 " + ID );
	env.Insert ( "ApprovedPosition", "ApprovedPosition " + ID );
	env.Insert ( "HeadPosition", "HeadPosition " + ID );
	env.Insert ( "Member1Position", "Member1Position " + ID );
	env.Insert ( "Member2Position", "Member2Position " + ID );
	
	env.Insert ( "Expenses", "_Expenses Method " + ID );
	env.Insert ( "Expense", "_Expense " + ID );

	items = new Array ();
	items.Add ( newItem ( "_Item " + ID, 5, 150, false ) );
	items.Add ( newItem ( "_Item, pkg " + ID, 5, 250, true ) );
	env.Insert ( "Items", items );
	return env;

EndFunction

Function newItem ( Name, Quantity, Price, CountPackages )

	p = new Structure ( "Name, Quantity, Price, CountPackages" );
	p.Name = Name;
	p.Quantity = Quantity;
	p.Price = Price;
	p.CountPackages = CountPackages;
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Expense
	// *************************
	expense = Env.Expense;
	Call ( "Catalogs.Expenses.Create", expense );
	
	// *************************
	// Create Expenses
	// *************************
	
	p  = Call ( "Catalogs.ExpenseMethods.Create.Params" );	
	p.Description = Env.Expenses;
	p.Account = Env.ExpenseAccount;
	p.Expense = expense;
	Call ( "Catalogs.ExpenseMethods.Create", p );
	
	// ***********************
	// Create IntangibleAssetAccounts
	// ***********************
	
	Commando ( "e1cib/list/InformationRegister.IntangibleAssetAccounts" );
	With ( "Intangible Assets" );

	list = Activate ( "#List" );
	search = new Map ();
	search.Insert ( "Company", "ABC Distributions" );
	search.Insert ( "Account", Env.Account );
	search.Insert ( "Amortization", Env.Amortization );
	search.Insert ( "Intangible Asset", "" );

	try
		found = list.GotoRow ( search, RowGotoDirection.Down );
	except
		found = false;
	endtry;

	if ( not found ) then
		Click ( "#FormCreate" );
		With ( "Intangible Assets (create)" );
		Put ( "#Company", "ABC Distributions" );
		Put ( "#Account", Env.Account );
		Put ( "#Amortization", Env.Amortization );
		Click ( "#FormWriteAndClose" );
	endif;
	CloseAll ();
	
	// ***********************
	// Create Items
	// ***********************

	for each item in Env.Items do
		p = Call ( "Catalogs.Items.Create.Params" );
		p.Description = item.Name;
		p.CountPackages = item.CountPackages;
		Call ( "Catalogs.Items.Create", p );
	enddo;
	
	// ***********************
	// Create Assets
	// ***********************
	
	for each item in Env.Items do
		p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
		p.Description = item.Name;
		Call ( "Catalogs.IntangibleAssets.Create", p );
	enddo;
	
	// ***********************
	// Create Employees
	// ***********************
	
	createEmployee ( Env.Responsible );
	if ( env.IDMemo <> undefined ) then
	    createEmployee ( Env.Approved );
		createEmployee ( Env.Head );
		createEmployee ( Env.Member1 );
		createEmployee ( Env.Member2 );
		
		// ***********************
		// Create Positions
		// ***********************
		
		createPosition ( Env.ApprovedPosition );
		createPosition ( Env.HeadPosition );
		createPosition ( Env.Member1Position );
		createPosition ( Env.Member2Position );
	endif;
	
	// ***********************
	// Receice Items
	// ***********************
	
	p = Call ( "Documents.ReceiveItems.Receive.Params" );
	p.Date = Env.Date - 86400;
	p.Warehouse = Env.Warehouse;
	p.Account = Env.ReceiveAccount;
	items = p.Items;
	for each item in Env.Items do
		row = Call ( "Documents.ReceiveItems.Receive.Row" );
		FillPropertyValues ( row, item );
		row.Item = item.Name;
		items.Add ( row );
	enddo;
	Call ( "Documents.ReceiveItems.Receive", p );
	
	RegisterEnvironment ( id );

EndProcedure

Procedure createEmployee ( Employee )

	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Employee;
	Call ( "Catalogs.Employees.Create", p );

EndProcedure

Procedure createPosition ( Position )

	p = Call ( "Catalogs.Positions.Create.Params" );
	p.Description = Position;
	Call ( "Catalogs.Positions.Create", p );

EndProcedure

Procedure fillStakeholders ( Form, Env )
	
	Activate ( "Stakeholders" );
	
	setValueEmployee ( "#Approved", Env.Approved );
	setValuePosition ( "#ApprovedPosition", Env.ApprovedPosition );
	setValueEmployee ( "#Head", Env.Head );
	setValuePosition ( "#HeadPosition", Env.HeadPosition );
	
	// *********************
	// Fill members
	// *********************
	
	table = Activate ( "#Members" );
	Call ( "Table.Clear", table );
	for i = 1 to 2 do
		Click ( "#MembersAdd" );
		setValueEmployee ( "#MembersMember", Env [ "Member" + i ] );
		setValuePosition ( "#MembersPosition", Env [ "Member" + i + "Position" ] );
		table.EndEditRow ();
	enddo;
	
EndProcedure

Procedure setValueEmployee ( Field, Value )

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

Procedure setValuePosition ( Field, Value )

	form = CurrentSource;
	Choose ( Field );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", "Positions" );
	Click ( "#OK" );
	With ( "Positions" );
	GotoRow ( "#List", "Description, Ro", Value );
	Click ( "#FormChoose" );
	CurrentSource = form;
	
EndProcedure
