Call ( "Common.Init" );
CloseAll ();
id = Call ( "Common.ScenarioID", "2811C425" );
env = getEnv ( id );
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Projects" );
With ( "Projects" );
clearFilters ();
checkProjects ( env );

Function getEnv ( ID )
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date1", "01/01/2018" );
	p.Insert ( "Date2", "08/01/2018" );
	p.Insert ( "Customer", "_Customer:" + ID );
	p.Insert ( "Employee", "_Employee: " + ID );
	p.Insert ( "Description", "_Description: " + ID );
	p.Insert ( "Amount", "Amount" );
	return p;
EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	createEmployee ( Env );
	createCustomer ( Env );
	createProject ( Env, 0 );
	createProject ( Env, 1 );
	createProject ( Env, 2 );
	Call ( "Common.StampData", id );

EndProcedure


Procedure createEmployee ( Params )
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Employees" );
	With ( "Individuals (create)" );
	Set ( "#FirstName", Params.Employee );
	Click ( "#FormWriteAndClose" );
EndProcedure

Procedure createCustomer ( Params )
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (create)" );
	Set ( "#Description", Params.Customer );
	Click ( "#Customer" );
	Click ( "#FormWriteAndClose" );
EndProcedure

Procedure createProject ( env, Code )
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Projects" );
	With ( "Projects (cre*" );
	Set ( "#Description", env.Description + Code );
	Set ( "#Owner", env.Customer );
	// "Calculation"
	Put ( "#DateStart", env.Date1 );
	Put ( "#DateEnd", env.Date2 );
	Set ( "#Pricing", env.Amount );
	// "Tasks"	
	table = Activate ( "#Tasks" );
	commands = table.GetCommandBar ();
	Call ( "Table.AddEscape", table );
	Click ( "Add", commands );
	Choose ( "Performer", table );
	Call ( "Select.Employee", env.Employee );
	Click ( "Save" );
	Close ();
EndProcedure

Procedure clearFilters ()
	With ( "Projects" );
	Clear ( "#CustomerFilter" );
	Clear ( "#EmployeeFilter" );
	Clear ( "#FilterByStatus" );
	Clear ( "#InvoceFilter" );
EndProcedure

Procedure checkProjects ( Params )
	table = Get ( "#List" );
	find = Call ( "Common.Find.Params" );
	find.Where = "Description";
	find.What = Params.Description;
	Call ( "Common.Find", find );
	table.GotoFirstRow ();
	table.GotoNextRow ();
	table.GotoNextRow ();
EndProcedure