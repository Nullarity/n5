// Create a new Opening Balance
// Set account = Accounts Receivable
// Check dimensions work
// Post the document

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2863AE17" );
env = getEnv ( id );
createEnv ( env );

// Create document
Commando ( "e1cib/list/DocumentJournal.Balances" );
With ( "Opening Balances" );
if ( Date(Fetch ( "#BalanceDate" )) = Date(1, 1, 1) ) then
	Set("#BalanceDate", Format(CurrentDate(), "DLF=D"));
endif;
Click ( "#FormCreateByParameterBalances" );
With ( "Opening Balances (cr*" );

Put ( "#Account", "11000" );
table = Get ( "#Details" );

Set ( "#DetailsDim1", env.Customer, table );
Set ( "#DetailsAmount", 100, table );

// Local currency and records currency are local and they equal USD
Check ( "#DetailsCurrencyAmount", 100, table );
CheckState ( "#DetailsCurrencyAmount", "ReadOnly", , table );

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records:*" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer: " + ID );
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
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
