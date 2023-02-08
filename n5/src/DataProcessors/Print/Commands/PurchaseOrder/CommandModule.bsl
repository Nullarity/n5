
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.Print";
	p.Objects = List;
	form = PredefinedValue ( "Enum.PrintForms.PurchaseOrder" );
	p.Caption = form;
	p.Key = form;
	p.Template = "Template";
	p.Languages = "en, ru, ro";
	Print.Print ( p );
	
EndProcedure
