// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	LocalCurrency = Application.Currency ();
	Company = Logins.Settings ( "Company" ).Company;
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )

	if ( EventName = Enum.MessageBankingAppUnloaded () ) then
		Items.List.Refresh ();
	endif;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure BankAccountOnChange ( Item )
	
	filterByBankAccount ();
	
EndProcedure

&AtServer
Procedure filterByBankAccount ()

	DC.ChangeFilter ( List, "BankAccount", BankAccount, not BankAccount.IsEmpty () );

EndProcedure

&AtClient
Procedure RecipientOnChange ( Item )
	
	filterByRecipient ();
	
EndProcedure

&AtServer
Procedure filterByRecipient ()

	DC.ChangeFilter ( List, "Recipient", Recipient, not Recipient.IsEmpty () );

EndProcedure
