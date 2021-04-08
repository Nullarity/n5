
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.Bill";
	p.Objects = List;
	name = "BillRo";
	p.Key = name;
	p.Name = name;
	Print.Print ( p );
	
EndProcedure
