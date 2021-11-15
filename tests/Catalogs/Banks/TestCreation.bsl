Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27387777" );
env = getEnv ( id );
createEnv ( env );

Call ( "Common.OpenList", Meta.Catalogs.Banks );

if ( Call ( "Common.AppIsCont" ) ) then
	Click ( "#FormCreate" );
	form = With ( "Banks Classifier" );
	
	p = Call ( "Common.Find.Params" );
	p.Where = "Code";
	p.What = id;
	Call ( "Common.Find", p );
	
	Click ( "#FormSelect" );

	With ( "Banks" );
else
	With ( "Banks" );
	p = Call ( "Common.Find.Params" );
	p.Where = "Code";
	p.What = id;
	Call ( "Common.Find", p );
endif;

Click ( "#FormChange" );
bank = Env.Bank;
With ( bank + " (Banks)" );
if ( Fetch ( "#Description" ) <> bank ) then
	Stop ( "Description must be: " + bank );
endif;
CheckState ( "Address", "Enable" );	

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Bank", "Bank " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Bank
	// *************************
	
	if ( Call ( "Common.AppIsCont" ) ) then
		p = Call ( "Catalogs.BanksClassifier.Create.Params" );
		p.Code = id;
		p.Description = Env.Bank;
		Call ( "Catalogs.BanksClassifier.Create", p );
	else
		p = Call ( "Catalogs.Banks.Create.Params" );
		p.Code = id;
		p.Description = Env.Bank;
		Call ( "Catalogs.Banks.Create", p );
	endif;	
	
	RegisterEnvironment ( id );
	
EndProcedure

