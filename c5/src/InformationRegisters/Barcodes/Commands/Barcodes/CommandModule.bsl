
&AtClient
Procedure CommandProcessing ( Item, CommandExecuteParameters )
	
	p = new Structure ( "Filter", new Structure () );
	p.Filter.Insert ( "Item", Item );
	OpenForm ( "InformationRegister.Barcodes.ListForm", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
