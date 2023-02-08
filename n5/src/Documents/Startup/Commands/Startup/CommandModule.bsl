
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = List;
	name = "Startup";
	p.Key = name;
	p.Template = name;
	Print.Print ( p );
	
EndProcedure
