
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	p.Key = "PaymentOrder2";
	p.Template = "PaymentOrder";
	Print.Print ( p );
	
EndProcedure