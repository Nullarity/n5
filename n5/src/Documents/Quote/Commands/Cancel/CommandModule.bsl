
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = new Structure ();
	p.Insert ( "Quote", CommandParameter );
	OpenForm ( "InformationRegister.RejectedQuotes.RecordForm", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window );
	
EndProcedure
