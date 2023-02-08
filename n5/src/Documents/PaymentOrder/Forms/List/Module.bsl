// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()
	
	rules = new Array ();
	rules.Add ( "
	|BankAccount show empty ( BankAccountFilter );
	|Recipient show empty ( RecipientFilter );
	|" );
	Appearance.Read ( ThisObject, rules );
	
EndProcedure

&AtServer
Procedure init ()
	
	BankAccountFilter = Logins.Settings ( "Company.BankAccount" ).CompanyBankAccount;
	filterByBankAccount ();

EndProcedure

&AtServer
Procedure filterByBankAccount ()

	DC.ChangeFilter ( List, "BankAccount", BankAccountFilter, not BankAccountFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "BankAccountFilter" );

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
Procedure BankAccountFilterOnChange ( Item )
	
	filterByBankAccount ();
	
EndProcedure

&AtClient
Procedure RecipientFilterOnChange ( Item )
	
	filterByRecipient ();
	
EndProcedure

&AtServer
Procedure filterByRecipient ()

	DC.ChangeFilter ( List, "Recipient", RecipientFilter, not RecipientFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "RecipientFilter" );

EndProcedure

&AtClient
Procedure UnloadPayments ( Command )
	
	OpenForm ( "DataProcessor.UnloadPayments.Form" );

EndProcedure

&AtClient
Procedure TaxesOnlyOnChange ( Item )
	
	filterByTaxes ();

EndProcedure

&AtClient
Procedure filterByTaxes ()
	
	DC.ChangeFilter ( List, "Taxes", TaxesOnly, TaxesOnly );

EndProcedure