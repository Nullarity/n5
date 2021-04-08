
&AtClient
Procedure CommandProcessing ( User, CommandExecuteParameters )

	params = new Structure ( "User", User );
	OpenForm ( "InformationRegister.Tracking.ListForm", params, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
