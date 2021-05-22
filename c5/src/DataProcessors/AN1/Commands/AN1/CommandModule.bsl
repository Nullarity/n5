
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.AN1";
	p.Objects = List;
	name = "AN1";
	p.Key = name;
	p.Template = name;
	Print.Print ( p );
	
EndProcedure
