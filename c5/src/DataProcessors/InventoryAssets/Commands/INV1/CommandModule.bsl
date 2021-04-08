
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.InventoryAssets";
	p.Objects = List;
	name = "INV1";
	p.Key = name;
	p.Name = name;
	Print.Print ( p );
	
EndProcedure
