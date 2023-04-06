&AtClient
var AdvancesRow;
&AtServer
var Advances;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
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
		DocumentForm.Init ( Object );
		fillNew ();
		updateChangesPermission ();
	endif;
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Warning UndoPosting show Object.Posted;
	|Advances Date Company AdvanceAccount AdvanceCurrencyAccount VATAccount VATAdvance VATExport ReceivablesVATAccount lock Object.Posted;
	|AdvancesFill enable not Object.Posted
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	setAccountsSettings ();
	setVATAccount ();
	CalculationsForm.SetDate ( Object );
	
EndProcedure 

&AtServer
Procedure setAccountsSettings () 

	table = getAccounts ();
	settings = ChartsOfCharacteristicTypes.Settings;
	vatAdvance = settings.VATAdvance;
	vatExport = settings.VATExport;
	for each row in table do
		parameter = row.Parameter;
		value = row.Value;
		if ( parameter = vatAdvance ) then 
			Object.VATAdvance = value;		
		elsif ( parameter = vatExport ) then 
			Object.VATExport = value;	
		else
			Object.ReceivablesVATAccount = value;
		endif; 
	enddo;

EndProcedure

&AtServer
Function getAccounts ()
	
	accounts = new Array ();
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.ReceivablesVATAccount )" );
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.VATAdvance )" );
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.VATExport )" );
	s = "
	|select Settings.Parameter as Parameter, Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( , Parameter in ( " + StrConcat ( accounts, "," ) + ") ) as Settings
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure setVATAccount () 

	accounts = AccountsMap.Item ( Catalogs.Items.EmptyRef (), Object.Company, Catalogs.Warehouses.EmptyRef (), "VAT" );
	Object.VATAccount = accounts.VAT;

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

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure Fill ( Command )
	
	runFilling ();
	
EndProcedure

&AtClient
Procedure runFilling ()
	
	if ( Forms.Check ( ThisObject, "Company, ReceivablesVATAccount, VATAccount,
		|VATAdvance, VATExport" ) ) then
		params = fillingParams ();
		Filler.Open ( params, ThisObject );
	endif; 
	
EndProcedure 

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "ClosingAdvancesFilling";
	p.Filters = getFilters ();
	p.Background = true;
	return p;
	
EndFunction

&AtServer
Function getFilters ()
	
	filters = new Array ();
	item = DC.CreateParameter ( "Date", Object.Date );
	filters.Add ( item );
	item = DC.CreateParameter ( "Company", Object.Company );
	filters.Add ( item );
	item = DC.CreateParameter ( "VATAdvance", Object.VATAdvance );
	filters.Add ( item );
	item = DC.CreateParameter ( "VATExport", Object.VATExport );
	filters.Add ( item );
	accounts = AccountsMap.Organization ( Catalogs.Organizations.EmptyRef (), Object.Company,
		"CustomerAccount, AdvanceTaken" );
	item = DC.CreateParameter ( "Account", accounts.CustomerAccount );
	filters.Add ( item );
	item = DC.CreateParameter ( "AdvanceAccount", accounts.AdvanceTaken );
	filters.Add ( item );
	return filters;
	
EndFunction

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillAdvances ( Result ) ) then
		Output.FillingDataNotFound ();
	endif;

EndProcedure

&AtServer
Function fillAdvances ( val Result ) 

	advancesTemp = Filler.Fetch ( Result );
	if ( advancesTemp = undefined ) then
		return false;
	endif;
	table = Object.Advances;
	if ( Result.ClearTable ) then
		table.Clear ();
	endif;
	completeAdvances ( advancesTemp );
	for each rowAdvance in Advances do
		row = table.Add ();
		FillPropertyValues ( row, rowAdvance );
	enddo;
	return true;

EndFunction

&AtServer
Procedure completeAdvances ( AdvancesTemp ) 

	Advances = AdvancesTemp.CopyColumns ();
	for each row in AdvancesTemp do
		receiptAdvances ( row );
		closeAdvances ( row );
	enddo;
	groupColumns = "CustomerAccount, AdvanceAccount, Customer, Contract, Currency, VAT, CloseAdvance";
	totalColumns = "Amount, CurrencyAmount, VATAmount";
	Advances.GroupBy ( groupColumns, totalColumns );
	Advances.Sort ( groupColumns );

EndProcedure

&AtServer
Procedure receiptAdvances ( RowAdvance ) 

	if ( RowAdvance.Amount < 0 ) then
		addRow ( RowAdvance, -RowAdvance.Amount );
	endif; 
	if ( RowAdvance.CurrencyAmount < 0 ) then
		addRowCurrency ( RowAdvance, -RowAdvance.CurrencyAmount );
	endif;

EndProcedure

&AtServer
Procedure addRow ( RowAdvance, Amount ) 

	row	= Advances.Add ();
	fillRow ( row, RowAdvance );
	row.Amount = Amount;
	row.VATAmount = ? ( Row.CloseAdvance, -1, 1 ) * ( Amount - Amount * ( 100 / ( 100 + RowAdvance.Rate ) ) );

EndProcedure

&AtServer
Procedure fillRow ( Row, RowAdvance ) 

	Row.CustomerAccount	= RowAdvance.CustomerAccount;
	Row.AdvanceAccount = RowAdvance.AdvanceAccount;
	Row.Customer = RowAdvance.Customer;
	Row.Contract = RowAdvance.Contract;
	if ( RowAdvance.Export ) then
		Row.Currency = RowAdvance.Currency;
	endif;
	Row.CloseAdvance = RowAdvance.CloseAdvance;
	Row.VAT = RowAdvance.VAT;

EndProcedure

&AtServer
Procedure addRowCurrency ( RowAdvance, Amount ) 

	row	= Advances.Add ();
	fillRow ( row, RowAdvance );
	row.CurrencyAmount = Amount;

EndProcedure

&AtServer
Procedure closeAdvances ( RowAdvance )

	RowAdvance.CloseAdvance = true;
	if ( RowAdvance.Amount > 0 ) and ( RowAdvance.AdvanceAmount > 0 ) then
		amount = Min ( RowAdvance.Amount, RowAdvance.AdvanceAmount );
		addRow ( RowAdvance, amount );
	endif;
	if ( RowAdvance.CurrencyAmount > 0 ) and ( RowAdvance.AdvanceCurrencyAmount > 0 ) then
		amount = Min ( RowAdvance.CurrencyAmount, RowAdvance.AdvanceCurrencyAmount );
		addRowCurrency ( RowAdvance, amount );
	endif;

EndProcedure

&AtClient
Procedure DateChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	SelectedValue = EndOfDay ( SelectedValue );
	
EndProcedure

// *****************************************
// *********** Table Advances

&AtClient
Procedure AdvancesBeforeRowChange ( Item, Cancel )
	
	enableCurrency ();
	
EndProcedure

&AtClient
Procedure enableCurrency () 

	if ( AdvancesRow = undefined ) then
		return;
	endif;
	flag = not DF.Pick ( AdvancesRow.CustomerAccount, "Currency" );
	Items.AdvancesCurrency.ReadOnly = flag;
	Items.AdvancesCurrencyAmount.ReadOnly = flag;

EndProcedure

&AtClient
Procedure AdvancesOnActivateRow ( Item )
	
	AdvancesRow = Item.CurrentData;
	enableCurrency ();
	
EndProcedure

&AtClient
Procedure AdvancesCustomerOnChange ( Item )
	
	applyCustomer ();
	
EndProcedure

&AtClient
Procedure applyCustomer () 

	data = getAdvancesData ( AdvancesRow.Customer, AdvancesRow.CustomerAccount, Object.Company );
	AdvancesRow.Contract = data.Contract;
	AdvancesRow.Currency = data.Currency;

EndProcedure

&AtServerNoContext
Function getAdvancesData ( val Customer, val Account, val Company ) 

	data = new Structure ();
	data.Insert ( "Contract" );
	data.Insert ( "Currency" );
	customerData = DF.Values ( Customer, "CustomerContract, CustomerContract.Company as Company, CustomerContract.Currency as Currency" );
	if ( customerData.Company = Company ) then
		data.Contract = customerData.CustomerContract;
		if ( DF.Pick ( Account, "Currency" ) ) then
			data.Currency = customerData.Currency;
		endif;
	endif;
	return data;

EndFunction

&AtClient
Procedure AdvancesCustomerAccountOnChange ( Item )
	
	enableCurrency ();
	clearCurrency ();
	
EndProcedure

&AtClient
Procedure clearCurrency () 

	if ( not DF.Pick ( AdvancesRow.CustomerAccount, "Currency" ) ) then
		AdvancesRow.Currency = undefined;
		AdvancesRow.CurrencyAmount = undefined;
	endif;

EndProcedure

&AtClient
Procedure AdvancesContractOnChange ( Item )
	
	applyContract ();
	
EndProcedure

&AtClient
Procedure applyContract () 

	AdvancesRow.Currency = getCurrency ( AdvancesRow.Contract, AdvancesRow.CustomerAccount );

EndProcedure

&AtServerNoContext
Function getCurrency ( val Contract, val Account ) 

	if ( DF.Pick ( Account, "Currency" ) ) then
		return DF.Pick ( Contract, "Currency" );
	else
		return undefined
	endif;

EndFunction

&AtClient
Procedure AdvancesVATOnChange ( Item )
	
	calculateVAT ();
	
EndProcedure

&AtClient
Procedure calculateVAT () 

	amount = AdvancesRow.Amount;
	AdvancesRow.VATAmount = ? ( AdvancesRow.CloseAdvance, -1, 1 ) * ( amount - amount * ( 100 / ( 100 + DF.Pick ( AdvancesRow.VAT, "Rate" ) ) ) );

EndProcedure

&AtClient
Procedure AdvancesAmountOnChange ( Item )
	
	calculateVAT ();
	
EndProcedure
