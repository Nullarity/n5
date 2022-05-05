// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.InvoiceRecordsWrite () ) then
		base = Source.Base;
		if ( TypeOf ( base ) = Type ( "DocumentRef.Transfer" ) ) then
			NotifyChanged ( base );
		endif;
	elsif ( EventName = Enum.MessageInvoicesExchnage () ) then
		Items.List.Refresh ();
	endif; 
	
EndProcedure

// *****************************************
// *********** Group

&AtClient
Procedure SenderFilterOnChange ( Item )
	
	filterBySender ();
	
EndProcedure

&AtServer
Procedure filterBySender ()
	
	DC.ChangeFilter ( List, "Sender", SenderFilter, not SenderFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure ReceiverFilterOnChange ( Item )
	
	filterByReceiver ();
	
EndProcedure

&AtServer
Procedure filterByReceiver ()
	
	DC.ChangeFilter ( List, "Receiver", ReceiverFilter, not ReceiverFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
