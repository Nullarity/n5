
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = List;
	name = "WriteOff";
	p.Key = name;
	p.Template = name;
	p.Languages = "en, ru";
	Print.Print ( p );
	
EndProcedure
