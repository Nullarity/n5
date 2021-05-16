
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	name = "SalesOrder";
	p.Key = name;
	p.Name = name;
	p.Languages = "en, ru, ro";
	Print.Print ( p );
	
EndProcedure
