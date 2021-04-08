
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.Bill";
	p.Objects = List;
	name = "BillRu";
	p.Key = name;
	p.Name = name;
	Print.Print ( p );
	
EndProcedure
