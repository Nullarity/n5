
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = List;
	p.Manager = "DataProcessors.Inventory";
	p.Key = "Statement";
	p.Template = "Statement";
	p.Languages = "en, ru, ro";
	Print.Print ( p );
	
EndProcedure
