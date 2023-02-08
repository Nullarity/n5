Procedure Download ( Data ) export

	processor ().DownloadCurrencies ( Data );

EndProcedure

Function processor () 

	return DataProcessors.DownloadCurrencies.Create ();

EndFunction

Procedure DownloadShedule () export

	processor ().DownloadCurrenciesShedule ();
	
EndProcedure
