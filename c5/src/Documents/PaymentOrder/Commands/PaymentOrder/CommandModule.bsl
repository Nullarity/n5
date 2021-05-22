
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "PaymentOrder";
	p.Template = "PaymentOrder";
	Print.Print ( p );
	
EndProcedure