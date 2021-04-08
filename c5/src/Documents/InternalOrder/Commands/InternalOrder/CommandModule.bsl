
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	name = "InternalOrder" + CurrentLanguage ();
	p.Key = name;
	p.Name = name;
	Print.Print ( p );
	
EndProcedure
