
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )

	p = new Structure ( "Owner", CommandExecuteParameters.Source.Employee.Ref );
	OpenForm ( "Catalog.BankAccounts.ListForm", new Structure ( "Filter", p ), CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
