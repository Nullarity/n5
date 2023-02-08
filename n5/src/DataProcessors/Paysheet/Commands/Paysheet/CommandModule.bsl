
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.Paysheet";
	p.Objects = List;
	form = PredefinedValue ( "Enum.PrintForms.Paysheet" );
	p.Caption = form;
	p.Key = form;
	p.Template = "Paysheet";
	p.Languages = "en, ru, ro";
	Print.Print ( p );

EndProcedure
