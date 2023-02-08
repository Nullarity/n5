
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.InventoryAssets";
	p.Objects = List;
	name = "INV1";
	p.Key = name;
	p.Template = name;
	Print.Print ( p );
	
EndProcedure
