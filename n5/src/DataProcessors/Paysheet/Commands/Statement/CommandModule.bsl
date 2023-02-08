
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.Paysheet";
	p.Objects = List;
	form = PredefinedValue ( "Enum.PrintForms.PaysheetStatement" );
	p.Caption = form;
	p.Key = form;
	p.Template = "Statement";
	p.Languages = "en, ru, ro";
	Print.Print ( p );

EndProcedure
