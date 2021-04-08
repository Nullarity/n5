
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Sickness";
	p.Name = "Sickness";
	Print.Print ( p );
	
EndProcedure
