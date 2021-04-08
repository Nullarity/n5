
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = new Structure ( "Document", CommandParameter );
	OpenForm ( "Report.Records.Form", p, CommandExecuteParameters.Source, CommandExecuteParameters.Source.UUID, CommandExecuteParameters.Window );
	
EndProcedure
