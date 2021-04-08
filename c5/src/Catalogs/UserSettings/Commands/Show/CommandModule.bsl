
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	OpenForm ( "Catalog.UserSettings.ObjectForm", new Structure ( "Key", Logins.Settings ( "Ref" ).Ref ) );
	
EndProcedure

//&AtServer
//Function getSettings ()
//	
//	Logins.Settings ( "Ref" )
//	s = "
//	|select Settings.Ref 
//	|from
//	|where
//	|";
//	q = new Query ( s );
//	return q.Execute ().Unload () [ 0 ].Ref;
//	
//EndFunction