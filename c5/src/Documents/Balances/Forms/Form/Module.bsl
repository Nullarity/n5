&AtClient
var TableRow export;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	testAccount ();
	InvoiceForm.SetLocalCurrency ( ThisObject );
	formatting ();
	enableWarning ();
	updateChangesPermission ();
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure testAccount ()
	
	if ( TestingOff ( "BalancesAccontChoiceParameters" ) ) then
		return;
	endif;
	_nonpostingClass = 1;
	_shouldbe = Metadata.Enums.Accounts.EnumValues.Count () - _nonpostingClass;
	_meta = Metadata.Documents.Balances;
	_actual = _meta.Attributes.Account.ChoiceParameters [ 1 ].Value.Count ();
	_info = _meta.FullName () + ".Attributes.Account.ChoiceParameters.CountOfAccountClasses should be equal:" + _shouldbe + ", but actual number is " + _actual;
	Assert ( _actual, _info ).Equal ( _shouldbe );
	
EndProcedure

&AtServer
Procedure formatting ()
	
	readAccount ();
	enableDetails ();
	Appearance.Apply ( ThisObject );
	
EndProcedure 

&AtServer
Procedure readAccount ()
	
	AccountData = GeneralAccounts.GetData ( Object.Account );
	DetailsExist = fetchDimension ();
	
EndProcedure 

&AtServer
Function fetchDimension ()
	
	s = "
	|select top 1 1
	|from ChartOfAccounts.General.ExtDimensionTypes as Accounts
	|where not Accounts.TurnoversOnly
	|and Accounts.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Account );
	return not q.Execute ().IsEmpty ();
	
EndFunction 

&AtServer
Procedure enableDetails ()
	
	fields = AccountData.Fields;
	foreign = fields.Currency;
	qty = fields.Quantitative;
	Items.DetailsQuantity.Visible = qty;
	Items.AccountQuantity.Visible = qty;
	Items.DetailsCurrency.Visible = foreign;
	Items.AccountCurrency.Visible = foreign;
	Items.DetailsCurrencyAmount.Visible = foreign;
	Items.AccountCurrencyAmount.Visible = foreign;
	Items.DetailsRate.Visible = foreign;
	Items.AccountRate.Visible = foreign;
	Items.DetailsFactor.Visible = foreign;
	Items.AccountFactor.Visible = foreign;
	level = fields.Level;
	dims = AccountData.Dims;
	for i = 1 to 3 do
		enable = ( level >= i );
		column = "DetailsDim" + i;
		Items [ column ].Visible = enable;
		if ( enable ) then
			Items [ column ].Title = dims [ i - 1 ].Presentation;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure enableWarning ()
	
	if ( AccountData = undefined
		or AccountData.Dims.Count () = 0 ) then
		value = WarningOnEditRepresentation.DontShow;
	else
		value = WarningOnEditRepresentation.Show;
	endif; 
	Items.Account.WarningOnEditRepresentation = value;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.SetCreator ( Object );
		if ( Parameters.CopyingValue.IsEmpty () ) then
			BalancesForm.CheckParameters ( ThisObject );
		else	
			BalancesForm.FixDate ( ThisObject );
			formatting ();
			enableWarning ();
		endif; 
		Constraints.ShowAccess ( ThisObject );
	endif;
	setAccuracy ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|DetailsPage show DetailsExist and filled ( Object.Account );
	|AccountPage show not DetailsExist and filled ( Object.Account );
	|InfoPage show empty ( Object.Account )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "DetailsQuantity" );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	initTableRow ();

EndProcedure

&AtClient
Procedure initTableRow ()
	
	if ( Object.Account.IsEmpty ()
		or DetailsExist ) then
		return;
	endif; 
	activateTableRow ( Object.Details [ 0 ] );
	
EndProcedure 

&AtClient
Procedure activateTableRow ( Row )
	
	TableRow = Row;
	if ( TableRow = undefined ) then
		return;
	endif; 
	EntryForm.DisableCurrency ( ThisObject );

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
Procedure AccountOnChange ( Item )
	
	applyAccount ();
	activateTableRow ( Object.Details [ 0 ] );
	
EndProcedure

&AtServer
Procedure applyAccount ()
	
	reset ();
	formatting ();
	enableWarning ();
	
EndProcedure 

&AtServer
Procedure reset ()
	
	details = Object.Details;
	details.Clear ();
	details.Add ();
	
EndProcedure 

// *****************************************
// *********** Group Details

&AtClient
Procedure DetailsOnActivateRow ( Item )
	
	activateTableRow ( Item.CurrentData );
	
EndProcedure

&AtClient
Procedure DetailsOnEditEnd ( Item, NewRow, CancelEdit )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure calcTotals ( Object )
	
	Object.Amount = Object.Details.Total ( "Amount" );
	
EndProcedure 

&AtClient
Procedure DetailsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure DetailsDim1StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.Dim1StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DetailsDim1OnChange ( Item )
	
	EntryForm.Dim1OnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DetailsDim2StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.Dim2StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DetailsDim2OnChange ( Item )
	
	EntryForm.Dim2OnChange ( ThisObject, Item );

EndProcedure

&AtClient
Procedure DetailsDim3StartChoice ( Item, ChoiceData, StandardProcessing )
	
	EntryForm.Dim3StartChoice ( ThisObject, Item, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure DetailsCurrencyOnChange ( Item )
	
	EntryForm.CurrencyOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DetailsRateOnChange ( Item )
	
	EntryForm.RateOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DetailsFactorOnChange ( Item )
	
	EntryForm.FactorOnChange ( ThisObject, Item );

EndProcedure

&AtClient
Procedure DetailsCurrencyAmountOnChange ( Item )
	
	EntryForm.CurrencyAmountOnChange ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure DetailsAmountOnChange ( Item )
	
	EntryForm.AmountOnChange ( ThisObject, Item );

EndProcedure

// *****************************************
// *********** Group Account

&AtClient
Procedure AccountAmountOnChange ( Item )
	
	EntryForm.AmountOnChange ( ThisObject, Item );
	
EndProcedure
