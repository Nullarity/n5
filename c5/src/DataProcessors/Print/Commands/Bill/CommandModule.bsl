
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.Print";
	p.Caption = PredefinedValue ( "Enum.PrintForms.Bill" );
	p.Objects = List;
	p.Key = PredefinedValue ( "Enum.PrintForms.Bill" );
	p.Template = "Template";
	p.Languages = "en, ru, ro";
	Print.Print ( p );
	
EndProcedure
