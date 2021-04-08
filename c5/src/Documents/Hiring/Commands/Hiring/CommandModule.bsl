
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = List;
	name = "Hiring";
	p.Key = name;
	p.Name = name;
	Print.Print ( p );
	
EndProcedure
