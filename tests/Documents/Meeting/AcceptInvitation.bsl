// Create a Meeting
// Add Accountant
// Form Meeting
// Run Accountant session
// Accept invitation
// Open meeting again and check statistics

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28ADE892" );
env = getEnv ( id );
createEnv ( env );

Commando("e1cib/command/Document.Meeting.Create");
With();
Put("#Room", env.Room);
begins = CurrentDate () + 5*60;
ends = begins + 15*60;
Set("#Start", begins);
Set("#Finish", ends);
Set("#Subject", "Test Accountant Invitation" );
memoID = Call("Common.GetID");
Set("#Memo", memoID);

// Add Accountant
Click("#MembersAdd");
Put("#MembersMember", "Accountant");

// Form Meeting
Click("#FormOK");

// Run a new 1C session with Member
memberPort = env.MemberPort;
try
	Connect ( , memberPort );
	connected = true;
except
	connected = false;	
endtry;
if ( connected ) then
	CloseAll();
	Disconnect(true);
endif;
p = Call ("Tester.Run.Params");
p.User = "Accountant";
p.IBase = env.Infobase;
p.Port = memberPort;
p.Parameters = "/len /Z""FFD0B42561""";
Call("Tester.Run", p);

// Open & complete his task
Commando("e1cib/list/Document.Meeting");
With();
GotoRow("#List", "Memo", memoID);
Click("#FormChange");
With();
Set("#YourAnswer", "Yes");
Set("#YourComment", "I will come with friend");
Click("#Confirm");

// Connect to the Creator's session
Disconnect(true);
Connect(, env.CreatorPort);

// Open this Meeting again
Commando("e1cib/list/Document.Meeting");
With();
GotoRow("#List", "Memo", memoID);
Click("#FormChange");
With();

// Check brief info
Check("#SaidYes", 2);
Check("#SaidNo", 0);
Check("#SaidMaybe", 0);
Check("#SaidNothing", 0);

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Room", "Room " + ID );
	port = AppData.Port;
	p.Insert ( "CreatorPort", port );
	p.Insert ( "MemberPort", port + 1 );
	p.Insert ( "Infobase" );
	if ( __.TestServer ) then
		p.Infobase = "Core, develop";
	else
		p.Infobase = "Core, sources";
	endif;
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Room
	// *************************
	
	p = Call ( "Catalogs.Rooms.Create.Params" );
	p.Description = Env.Room;
	Call ( "Catalogs.Rooms.Create", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
