
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = List;
	name = "ExpenseReport";
	p.Key = name;
	p.Name = name;
	p.Languages = "en, ru, ro";
	Print.Print ( p );
	
EndProcedure
