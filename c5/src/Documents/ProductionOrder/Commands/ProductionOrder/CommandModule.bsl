
&AtClient
Procedure CommandProcessing ( Orders, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = Orders;
	p.Key = "ProductionOrder";
	p.Template = "ProductionOrder";
	Print.Print ( p );
	
EndProcedure
