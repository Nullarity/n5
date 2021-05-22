
&AtClient
Procedure CommandProcessing ( Item, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = Item;
	p.Key = "Barcode";
	p.Template = "Barcode";
	Print.Print ( p );
	
EndProcedure
