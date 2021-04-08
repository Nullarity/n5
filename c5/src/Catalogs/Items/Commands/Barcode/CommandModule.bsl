
&AtClient
Procedure CommandProcessing ( Item, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = Item;
	p.Key = "Barcode";
	p.Name = "Barcode";
	Print.Print ( p );
	
EndProcedure
