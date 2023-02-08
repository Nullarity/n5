// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	loadParams ();
	fillTable ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormContinueUpdate show Total = 1;
	|FormTerminateSessions show Total > 1 and ServerMode
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure init ()
	
	MySession = InfoBaseSessionNumber ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	ServerMode = Parameters.ServerMode;
	
EndProcedure

&AtServer
Procedure fillTable ()
	
	Table.Clear ();
	SessionParameters.TenantUse = false;
	list = GetInfoBaseSessions ();
	SessionParameters.TenantUse = true;
	for each connection in list do
		app = connection.ApplicationName;
		if ( Lower ( app ) = "srvrconsole" ) then
			continue;
		endif;
		row = Table.Add ();
		row.User = connection.User;
		row.Application = app;
		row.Computer = connection.ComputerName;
		row.Started = connection.SessionStarted;
		row.Session = connection.SessionNumber;
	enddo;
	Table.Sort ( "User, Started" );
	Total = Table.Count ();
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Update ( Command )
	
	refresh ();
	
EndProcedure

&AtServer
Procedure refresh ()
	
	fillTable ();
	Appearance.Apply ( ThisObject, "Total" );
	
EndProcedure

&AtClient
Procedure TerminateSessions ( Command )
	
	Output.DisconnectUsers ( ThisObject );
	
EndProcedure

&AtClient
Procedure DisconnectUsers ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	disconnectAll ();
	
EndProcedure

&AtServer
Procedure disconnectAll ()
	
	Connections.LeaveMeAlone ();
	refresh ();
	
EndProcedure

&AtClient
Procedure ContinueUpdate ( Command )
	
	Close ( true );
	
EndProcedure
