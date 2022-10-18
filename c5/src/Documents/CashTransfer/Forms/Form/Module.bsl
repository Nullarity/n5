// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.Init ( Object );
		setRates ();
		updateChangesPermission ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Rate Factor enable Object.Currency <> LocalCurrency
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()

	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	if ( Object.Sender.IsEmpty () ) then
		settings = Logins.Settings ( "Company, PaymentLocation, PaymentLocation.Class as Class" );
		Object.Company = settings.Company;
		if ( isCash ( settings.Class ) ) then
			Object.Sender = settings.PaymentLocation;
		endif; 
	else
		Object.Company = DF.Pick ( Object.Sender, "Owner" );
	endif; 
	setAccount ( Object );
	loadReceiver ();
	Object.Currency = Application.Currency ();

EndProcedure

&AtServer
Function isCash ( Class )
	
	return not ValueIsFilled ( Class )
	or Class = Enums.Accounts.Cash;
	
EndFunction 

&AtClientAtServerNoContext
Procedure setAccount ( Object )

	Object.Account = DF.Pick ( Object.Sender, "Account" );
	
EndProcedure

&AtServer
Procedure loadReceiver ()
	
	if ( Object.Receiver.IsEmpty () ) then
		return;
	endif;
	data = DF.Values ( Object.Receiver, "Owner, Class" );
	if ( data.Owner = Object.Company
		and isCash ( data.Class ) ) then
		setAccountTo ( Object );
	else
		Object.Receiver = undefined;
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setAccountTo ( Object )
	
	Object.AccountTo = DF.Pick ( Object.Receiver, "Account" );
	
EndProcedure

&AtServer
Procedure setRates ()
	
	info = CurrenciesSrv.Get ( Object.Currency, Object.Date );
	Object.Rate = info.Rate;
	Object.Factor = info.Factor;
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure SenderOnChange ( Item )
	
	setAccount ( Object );
	
EndProcedure

&AtClient
Procedure ReceiverOnChange ( Item )
	
	setAccountTo ( Object );
	
EndProcedure

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency ()

	setRates ();
	Appearance.Apply ( ThisObject, "Object.Currency" );

EndProcedure
