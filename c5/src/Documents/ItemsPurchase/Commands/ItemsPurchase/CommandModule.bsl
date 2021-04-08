
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "ItemsPurchase";
	p.Name = "ItemsPurchase";
	Print.Print ( p );
	
EndProcedure
