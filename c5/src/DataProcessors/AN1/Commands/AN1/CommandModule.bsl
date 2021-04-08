
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.AN1";
	p.Objects = List;
	name = "AN1";
	p.Key = name;
	p.Name = name;
	Print.Print ( p );
	
EndProcedure
