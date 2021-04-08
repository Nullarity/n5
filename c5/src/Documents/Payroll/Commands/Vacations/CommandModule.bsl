
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Vacations";
	p.Name = "Vacations";
	Print.Print ( p );
	
EndProcedure
