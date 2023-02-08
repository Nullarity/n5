// *****************************************
// *********** Group Form

&AtClient
Procedure Download ( Command )
	
	OpenForm ( "DataProcessor.DownloadCurrencies.Form", , ThisObject, , , , new NotifyDescription ( "Downloaded", ThisObject ) );
	
EndProcedure

&AtClient
Procedure Downloaded ( Result, Params ) export
	
	Items.List.Refresh ();
	
EndProcedure