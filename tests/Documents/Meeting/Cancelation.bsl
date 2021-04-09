// Create a Meeting
// Add Accountant
// Form Meeting
// Open this Meeting again
// Cancel

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28B09605" );
env = getEnv ( id );
createEnv ( env );

Commando("e1cib/command/Document.Meeting.Create");
With();
Put("#Room", env.Room);
begins = CurrentDate () + 5*60;
ends = begins + 15*60;
Set("#Start", begins);
Set("#Finish", ends);
Set("#Subject", "Will be canceled" );
memoID = Call("Common.GetID");
Set("#Memo", memoID);

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

// Cancel
Click("#FormCancel");
With();
Set("#Comment", "We lost organizer");
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
