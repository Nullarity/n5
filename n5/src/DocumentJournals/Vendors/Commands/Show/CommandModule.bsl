
&AtClient
Procedure CommandProcessing ( Vendor, ExecuteParameters )
	
	p = new Structure ( "Vendor", Vendor );
	OpenForm ( "DocumentJournal.Vendors.ListForm", new Structure ( "Filter", p ), ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );
	
EndProcedure
