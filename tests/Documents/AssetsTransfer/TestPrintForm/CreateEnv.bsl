Call ( "Common.Init" );
CloseAll ();

env = getEnv ( _ );
createEnv ( env );

Call ( "Common.OpenList", Meta.Documents.AssetsTransfer );

p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = env.id;
Call ( "Common.Find", p );
With ( "Assets Transfers" );

Click ( "#FormChange" );
form = With ( "Assets Transfer #*" );
fillStakeholders ( form, env.Employees );

With ( form );
Click ( "#FormPostAndClose" );

// ***********************************
// Procedures
// ***********************************

Function getEnv ( ID )

	env = new Structure ();
	env.Insert ( "ID", ID );
	env.Insert ( "Date", CurrentDate () );
	employees = new Array ();
	date = BegOfYear ( env.Date );
	department = "Administration";
	employees.Add ( newEmployee ( "_Approved: " + ID, date, department, "Director" ) );
	employees.Add ( newEmployee ( "_Head: " + ID, date, department, "Manager" ) );
	employees.Add ( newEmployee ( "_Member1: " + ID, date, department, "Accountant" ) );
	employees.Add ( newEmployee ( "_Member2: " + ID, date, department, "Stockman" ) );
	env.Insert ( "Employees", employees );
	return env;

EndFunction

Function newEmployee ( Employee, DateStart, Department, Position )

 	p = Call ( "Documents.Hiring.Create.Row" );
	p.Insert ( "Employee", Employee );
	p.Insert ( "DateStart", DateStart );
	p.Insert ( "Department", Department );
	p.Insert ( "Position", Position );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// ***********************************
	// Create AssetsTransfer 
	// ***********************************
	Call ( "Documents.AssetsTransfer.TestCreation.Create", id );
	
	RegisterEnvironment ( id );

EndProcedure

Procedure fillStakeholders ( Form, Employees )
	
	try
		Activate ( "Stakeholders" );
	except
		return;
	endtry;

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


