// *****************************************
// *********** Form events

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.InvoiceRecordsWrite () ) then
		base = Source.Base;
		if ( TypeOf ( base ) = Type ( "DocumentRef.LVITransfer" ) ) then
			NotifyChanged ( base );
		endif;
	endif; 
	
EndProcedure
