
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.Bill";
	p.Objects = List;
	name = "Bill";
	p.Key = name;
	p.Name = name;
	p.Languages = "ru, ro";
	Print.Print ( p );
	
EndProcedure
