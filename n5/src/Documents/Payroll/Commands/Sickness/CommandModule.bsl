
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "Sickness";
	p.Template = "Sickness";
	Print.Print ( p );
	
EndProcedure
