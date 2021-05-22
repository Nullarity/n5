
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.MF1";
	p.Objects = List;
	name = "MF1";
	p.Key = name;
	p.Template = name;
	Print.Print ( p );
	
EndProcedure
