
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.PrintBarcodes";
	p.Objects = List;
	p.Key = "Barcodes";
	p.Template = "Template";
	Print.Print ( p );

EndProcedure
