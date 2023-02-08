
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Objects = CommandParameter;
	name = "PickList";
	p.Key = name;
	p.Template = name;
	p.Languages = "en, ru, ro";
	Print.Print ( p );
	
EndProcedure