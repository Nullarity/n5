&AtClient
Procedure Open ( Form, AllowCreation ) export
	
	OpenForm ( "DataProcessor.Scan.Form", new Structure ( "AllowCreation", AllowCreation ), Form );
	
EndProcedure

&AtClient
Procedure Scan ( Form ) export
	
	OpenForm ( "DataProcessor.Scan.Form", new Structure ( "JustScan", true ), Form );
	
EndProcedure
