
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "ServicesPurchase";
	p.Name = "ServicesPurchase";
	Print.Print ( p );
	
EndProcedure
