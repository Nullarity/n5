&AtClient
Procedure Choose ( Form, Company ) export
	
	p = new Structure ();
	p.Insert ( "Company", Company );
	processorForm = GetForm ( "DataProcessor.Prices.Form", p, Form );
	processorForm.DoModal ();
	
EndProcedure
