
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	FormParameters = New Structure ( "Objects", CommandParameter );
	OpenForm ( "DataProcessor.PrintTest.Form", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window );
	
EndProcedure
