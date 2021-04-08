
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "PaymentOrder";
	p.Name = "PaymentOrder";
	Print.Print ( p );
	
EndProcedure