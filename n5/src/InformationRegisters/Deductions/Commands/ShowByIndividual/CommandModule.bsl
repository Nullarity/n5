
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )

	p = new Structure ( "Employee", CommandExecuteParameters.Source.Employee.Ref );
	OpenForm ( "InformationRegister.Deductions.Form.Embedded", new Structure ( "Filter", p ), CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
