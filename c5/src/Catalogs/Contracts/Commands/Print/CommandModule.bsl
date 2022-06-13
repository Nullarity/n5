
&AtClient
Procedure CommandProcessing ( Contract, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = Contract;
	p.Caption = String ( Contract );
	p.Key = "PrintContract";
	Print.Print ( p );
	
EndProcedure
