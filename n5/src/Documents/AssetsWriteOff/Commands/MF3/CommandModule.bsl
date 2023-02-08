
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = List;
	name = "MF3";
	p.Key = name;
	p.Template = name;
	Print.Print ( p );
	
EndProcedure
