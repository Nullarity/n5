
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = List;
	p.Manager = "DataProcessors.Inventory";
	name = "Inventory" + CurrentLanguage ();
	p.Key = name;
	p.Name = name;
	Print.Print ( p );
	
EndProcedure
