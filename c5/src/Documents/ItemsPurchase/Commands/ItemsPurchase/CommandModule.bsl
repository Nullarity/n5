
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "ItemsPurchase";
	p.Template = "ItemsPurchase";
	Print.Print ( p );
	
EndProcedure
