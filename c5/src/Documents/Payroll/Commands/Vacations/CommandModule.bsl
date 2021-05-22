
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Vacations";
	p.Template = "Vacations";
	Print.Print ( p );
	
EndProcedure
