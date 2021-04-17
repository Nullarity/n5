// Create Closing Advance (Receipt USD) and check movemnts
// 1. create Payment
// 2. create closing advances and check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A6C2F69" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Closing Advances
// *************************
MainWindow.ExecuteCommand ( "e1cib/list/DocumentJournal.Calculations" );
With ();
p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );
Try
	Click ( "#FormChange" );
	form = With ();
	try
		Click ( "#FormUndoPosting" )
	except
	endtry;
Except
	Click ( "#FormCreateByParameterClosingAdvances" );
	form = With ();
EndTry;

Put ( "#Date", "01/31/2017" );
Put ( "#Memo", id );
Put ( "#Company", Env.Company );
Click ( "#AdvancesFill" );

With ( "Closing Advances: Setup Filters" );
table = Get ( "#UserSettings" );
GotoRow ( table, "Setting", "Customer Account" );
table.ChangeRow ();
Put ( "#UserSettingsValue", "2212", table );
table.EndEditRow ();
GotoRow ( table, "Setting", "Customer" );
table.ChangeRow ();
Put ( "#UserSettingsValue", env.Customer, table );
table.EndEditRow ();
Click ( "#FormFill" );
Waiting ( form );
With ( form );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Closing Advances*" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Company", "Company " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Company
	// *************************
	
	p = Call ( "Catalogs.Companies.Create.Params" );
	p.Description = Env.Company;
	Call ( "Catalogs.Companies.Create", p );
	
	// *************************
	// Set Advance Account
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/list/InformationRegister.OrganizationAccounts" );
	With ();
	Click ( "#FormCreate" );
	With ();
	Put ( "#Company", Env.Company );
	Put ( "#AdvanceGiven", "5232" );
	Put ( "#AdvanceTaken", "5232" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Customer
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Organizations" );
	form = With ( "Organizations (create)" );
	Put ( "#Description", Env.Customer );
	Click ( "#Customer" );
	Click ( "#FormWrite" );
	Click ( "Contracts", GetLinks () );
	With ( "Contracts" );
	Click ( "#ListContextMenuChange" );
	With ( "General (Contracts)" );
	Put ( "#Currency", "USD" );
	Put ( "#Company", Env.Company );
	Click ( "#Export" );
	
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Payment
	// *************************
	
	Commando ( "e1cib/data/Document.Payment" );
	With ( "Customer Payment (create)" );
	Put ( "#Date", "01/01/2017" );
	Put ( "#Company", Env.Company );
	Put ( "#Customer", Env.Customer );
	Put ( "#Amount", "100" );
	Put ( "#Currency1", "USD" );
	Put ( "#ContractRate", "18" );
	Put ( "#Account", "2422" );
	Put ( "#CustomerAccount", "2212" ); 
	Put ( "#AdvanceAccount", "2212" );  
	Click ( "#FormPostAndClose" );

	RegisterEnvironment ( id );

EndProcedure
