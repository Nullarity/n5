Call ( "Common.Init" );
CloseAll ();

// *****************************
// Init variables
// *****************************

date = CurrentDate ();
yearStart = BegOfYear ( date );
warehouse = "_WriteOff Warehouse";

// *****************************
// Receive items
// *****************************

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

// Write off

Call ( "Common.OpenList", Meta.Documents.WriteOff );
Click ( "#FormCreate" );
form = With ( "Write Off (create)" );

Call ( "Common.CheckCurrency", form );

Set ( "#Warehouse", warehouse );
Set ( "#ExpenseAccount", "8111" );
form.GotoNextItem ();
Set ( "#Dim1", "_WriteOff" );

table = Activate ( "#ItemsTable" );
Call ( "Table.AddEscape", table );
for each row in p.Items do
	Click ( "#ItemsTableAdd" );
	
	Set ( "#ItemsItem", row.Item, table );
	Set ( "#ItemsQuantity", row.Quantity, table );
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#ItemsAccount", account, table );
	endif;
enddo;
Call ( "Table.CopyEscapeDelete", table );

employees = hireEmployees ( date, yearStart );
fillStakeholders ( form, employees );

Click ( "#FormPost" );
Run ( "Logic" );
With ( form );
Run ( "PrintForm" );

// ***********************************
// Procedures
// ***********************************

Function hireEmployees ( Date, DateStart )

	compensation = "_Wage " + CurrentDate ();
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = compensation;
	Call ( "CalculationTypes.Compensations.Create", p );
	p = Call ( "Documents.Hiring.Create.Params" );
	employees = new Array ();
	employees.Add ( newEmployee ( "_Approved: " + Date, DateStart, "Administration", "Director", compensation ) );
	employees.Add ( newEmployee ( "_Head: " + Date, DateStart, "Administration", "Manager", compensation ) );
	employees.Add ( newEmployee ( "_Member1: " + Date, DateStart, "Administration", "Accountant", compensation ) );
	employees.Add ( newEmployee ( "_Member2: " + Date, DateStart, "Administration", "Stockman", compensation ) );
	p.Employees = employees;
	Call ( "Documents.Hiring.Create", p );
	return employees;

EndFunction

Function newEmployee ( Employee, DateStart, Department, Position, Compensation )

	p = Call ( "Documents.Hiring.Create.Row" );
	p.Insert ( "Employee", Employee );
	p.Insert ( "DateStart", DateStart );
	p.Insert ( "Department", Department );
	p.Insert ( "Position", Position );
	p.Insert ( "Compensation", Compensation );
	p.PutAll = false;
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