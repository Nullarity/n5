
&AtClient
Procedure CommandProcessing ( UsersList, CommandExecuteParameters )

	params = new Structure ( "Users", UsersList );
	OpenForm ( "Catalog.Users.Form.Notification", params, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
