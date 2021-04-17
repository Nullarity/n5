// Create a Meeting
// Check if first row is me
// Add Accountant
// Form Meeting
// Open this Meeting again
// Check brief info
// Change and post

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28A33CF9" );
env = getEnv ( id );
createEnv ( env );

Commando("e1cib/command/Document.Meeting.Create");
With();
Put("#Room", env.Room);
begins = CurrentDate () + 5*60;
ends = begins + 15*60;
Set("#Start", begins);
Set("#Finish", ends);
Set("#Subject", "Drugs and Alcohol during work time" );
memoID = Call("Common.GetID");
Set("#Memo", memoID);

// Check if first row is me
Check("#Members / #MembersMember", "admin");

// And I am an organizer
Check("#Members / #MembersOrganizer", "Yes");

// Add Accountant
Click("#MembersAdd");
Put("#MembersMember", "Accountant");

// Form Meeting
Click("#FormOK");

// Open this Meeting again
Commando("e1cib/list/Document.Meeting");
With();
GotoRow("#List", "Memo", memoID);
Click("#FormChange");
With();

// Check brief info
Check("#SaidYes", 1);
Check("#SaidNo", 0);
Check("#SaidMaybe", 0);
Check("#SaidNothing", 1);

// Change and post
Set("#Subject", "Will talk about healthy food");
Click("#FormOK");
With();
Set("#Comment", "Hurry up boys!");
Click("#FormOK");

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Room", "Room " + ID );
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
