&AtClient
var AdvancesRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		Constraints.ShowAccess ( ThisObject );
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
	|Advances Date Company AdvanceAccount AdvanceCurrencyAccount lock Object.Posted;
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
	CalculationsForm.SetDate ( Object );
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Fill ( Command )
	
	runFilling ();
	
EndProcedure

&AtClient
Procedure runFilling ()
	
	if ( Forms.Check ( ThisObject, "Company" ) ) then
		params = fillingParams ();
		Filler.Open ( params, ThisObject );
	endif; 
	
EndProcedure 

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "ClosingAdvancesGiven";
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
	accounts = AccountsMap.Organization ( Catalogs.Organizations.EmptyRef (), Object.Company,
		"VendorAccount, AdvanceGiven" );
	item = DC.CreateParameter ( "Account", accounts.VendorAccount );
	filters.Add ( item );
	item = DC.CreateParameter ( "AdvanceAccount", accounts.AdvanceGiven );
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

	data = Filler.Fetch ( Result );
	if ( data = undefined ) then
		return false;
	endif;
	advances = Object.Advances;
	if ( Result.ClearTable ) then
		advances.Clear ();
	endif; 
	for each rowData in data do
		row = advances.Add ();
		FillPropertyValues ( row, rowData );
	enddo;
	return true;

EndFunction

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
	flag = not DF.Pick ( AdvancesRow.VendorAccount, "Currency" );
	Items.AdvancesCurrency.ReadOnly = flag;
	Items.AdvancesCurrencyAmount.ReadOnly = flag;

EndProcedure

&AtClient
Procedure AdvancesOnActivateRow ( Item )
	
	AdvancesRow = Item.CurrentData;
	enableCurrency ();
	
EndProcedure

&AtClient
Procedure AdvancesVendorOnChange ( Item )
	
	applyVendor ();
	
EndProcedure

&AtClient
Procedure applyVendor () 

	data = getAdvancesData ( AdvancesRow.Vendor, AdvancesRow.VendorAccount, Object.Company );
	AdvancesRow.Contract = data.Contract;
	AdvancesRow.Currency = data.Currency;

EndProcedure

&AtServerNoContext
Function getAdvancesData ( val Vendor, val Account, val Company ) 

	data = new Structure ();
	data.Insert ( "Contract" );
	data.Insert ( "Currency" );
	vendorData = DF.Values ( Vendor, "VendorContract, VendorContract.Company as Company, VendorContract.Currency as Currency" );
	if ( vendorData.Company = Company ) then
		data.Contract = vendorData.VendorContract;
		if ( DF.Pick ( Account, "Currency" ) ) then
			data.Currency = vendorData.Currency;
		endif;
	endif;
	return data;

EndFunction

&AtClient
Procedure AdvancesVendorAccountOnChange ( Item )
	
	enableCurrency ();
	clearCurrency ();
	
EndProcedure

&AtClient
Procedure clearCurrency () 

	if ( not DF.Pick ( AdvancesRow.VendorAccount, "Currency" ) ) then
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

	AdvancesRow.Currency = getCurrency ( AdvancesRow.Contract, AdvancesRow.VendorAccount );

EndProcedure

&AtServerNoContext
Function getCurrency ( val Contract, val Account ) 

	if ( DF.Pick ( Account, "Currency" ) ) then
		return DF.Pick ( Contract, "Currency" );
	else
		return undefined
	endif;

EndFunction
