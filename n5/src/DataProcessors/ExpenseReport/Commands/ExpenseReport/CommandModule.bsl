
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.ExpenseReport";
	p.Objects = List;
	name = "ExpenseReport";
	p.Key = name;
	p.Template = name;
	Print.Print ( p );
	
EndProcedure
