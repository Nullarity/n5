
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.Quote";
	p.Objects = List;
	name = "Quote";
	p.Key = name;
	p.Template = name;
	p.Languages = "en, ru, ro";
	Print.Print ( p );
	
EndProcedure
