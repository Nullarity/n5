// 1. Test Entry without numerator
// 1.1 Create entry1
// 1.2 Create entry2 and check verify numbers

// 2. Test Entry with numerator
// 2.1 Create entry1
// 2.2 Create entry2 and check verify numbers

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2766464E" );
env = getEnv ( id );
createEnv ( env );

prefix = getPrefix ();

// Test Without Numerator 
number = parseNumber ( getNumberEntry (), prefix );
nextNumber = getNextNumber ( number, prefix );
if ( getNumberEntry () <> nextNumber ) then
	Stop ( "Number must be: " + nextNumber );
endif;

// Test With Numerator 
Commando ( "e1cib/list/Document.Entry" );
list = With ( "Accounting Entries" );
Put ( "#OperationFilter", env.Operation );
Click ( "#FormCreate" );

prefix = prefix + Env.Numerator;
number = parseNumber ( getNumberEntry ( false ), prefix );

With ( list );
Click ( "#FormCreate" );

nextNumber = getNextNumber ( number, prefix );
if ( getNumberEntry ( false ) <> nextNumber ) then
	Stop ( "Number must be: " + nextNumber );
endif;

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	env = new Structure ( "ID", ID );
	env.Insert ( "Operation", "Operation " + ID );
	env.Insert ( "Numerator", "KK" );
	return env;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// Create numerator
	Commando ( "e1cib/list/Catalog.Numeration" );
	With ( "Numerations" );
	
	p = Call ( "Common.Find.Params" );
	p.What = Env.Numerator;
	p.Where = "Description";
	Call ( "Common.Find", p );
	try
		Click ( "#FormChange" );
		form = With ( Env.Numerator + " (Numeration)" );
		Close ( form );
	except
		Commando ( "e1cib/data/Catalog.Numeration" );
		With ( "Numeration (create)" );
		Put ( "#Description", Env.Numerator );
		Click ( "#FormWriteAndClose" );
	endtry;
	
	// Create Operation
	Commando ( "e1cib/data/Catalog.Operations" );
	With ( "Operations (create)" );
	Put ( "#Operation", "Cash Receipt" );
	Put ( "#Description", Env.Operation );
	Put ( "#Numerator", Env.Numerator );
	Click ( "#FormWriteAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure

Function getPrefix ()
	
	OpenMenu ( "Settings / Application" );
	With ( "Application Settings" );
	node = Fetch ( "#Prefix" );
	Close ();
	
	Commando ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );
	
	p = Call ( "Common.Find.Params" );
	p.What = "ABC Distributions";
	p.Where = "Description";
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ( "ABC Distributions (Companies)" );
	company = Fetch ( "#Prefix" );
	Close ();
	return node + company;
	
EndFunction

Function getNumberEntry ( DoComando = true )
	
	if ( DoComando ) then
		Commando ( "e1cib/data/Document.Entry" );
	endif;
	With ( "Entry (create)" );
	Click ( "#FormWrite" );
	number = Fetch ( "#Number" );
	Close ();
	return number;
	
EndFunction

Function parseNumber ( Number, Prefix )
	
	return Right ( number, StrLen ( number ) - StrLen ( Prefix )  );
	
EndFunction

Function getNextNumber ( Number, Prefix )
	
	return Prefix + Format ( Number ( Number ) + 1, "NG=;NLZ=;ND=" + StrLen ( Number ) );
	
EndFunction

