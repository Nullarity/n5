&AtServer
var Copy;
&AtServer
var Env;
&AtServer
var Basis;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Basis = Parameters.Basis;
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.Init ( Object );
		if ( Basis = undefined ) then
			Copy = not Parameters.CopyingValue.IsEmpty ();
			fillNew ();
		else
			if ( TypeOf ( Basis ) = Type ( "DocumentRef.VendorInvoice" ) ) then
				fillByVendorInvoice ();
			endif; 
		endif;
		applyCurrency ();
		fillHeader ();
		Constraints.ShowAccess ( ThisObject );
	endif; 
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Currency Amount Prices VATUse show Object.ShowPrices;
	|Rate Factor enable filled ( Object.Currency ) and Object.Currency <> LocalCurrency;
	|VAT show ( Object.ShowPrices and Object.VATUse > 0 );
	|ItemsPrices ItemsPrice ItemsAmount show Object.ShowPrices;
	|ItemsVAT ItemsVATCode ItemsTotal show ( Object.ShowPrices and Object.VATUse > 0 )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Copy ) then
		return;
	endif; 
	if ( Object.Warehouse.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		Object.Company = settings.Company;
		Object.Warehouse = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
	endif;
	Object.Currency = Application.Currency ();
	setRate ();
	setPrices ( Object );
	
EndProcedure 

&AtServer
Procedure setRate ()
	
	currencyInfo = CurrenciesSrv.Get ( Object.Currency );
	Object.Rate = currencyInfo.Rate;
	Object.Factor = currencyInfo.Factor;
	
EndProcedure 

&AtServerNoContext
Procedure setPrices ( Object )
	
	data = DF.Values ( Object.Company, "CostPrices" );
	Object.Prices = data.CostPrices;
	
EndProcedure

#region Filling

&AtServer
Procedure fillByVendorInvoice ()
	
	setEnv ();
	sqlVendorInvoice ();
	SQL.Perform ( Env );
	FillPropertyValues ( Object, Env.Fields );
	Object.Items.Load ( Env.Items );
	vatUse = Object.VATUse;
	for each row in Object.Items do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo;
	applyVATUse ();
	
EndProcedure

Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Basis", Basis );
	
EndProcedure

&AtServer
Procedure sqlVendorInvoice ()
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Warehouse as Warehouse, Documents.Currency as Currency, Documents.VATUse as VATUse,
	|	Documents.Prices as Prices
	|from Document.VendorInvoice as Documents
	|where Documents.Ref = &Basis
	|;
	|// #Items
	|select Items.Capacity as Capacity, Items.Feature as Feature, Items.Item as Item, Items.Package as Package, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.QuantityPkg as QuantityPkg, Items.Account as Account, Items.Price as Price, Items.VATCode as VATCode,
	|	Items.VATRate as VATRate
	|from Document.VendorInvoice.Items as Items
	|where Items.Ref = &Basis
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer                                      
Procedure applyVATUse ()
	
	vatUse = Object.VATUse;
	for each row in Object.Items do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
EndProcedure

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	items = Object.Items;
	Object.VAT = items.Total ( "VAT" );
	Object.Amount = items.Total ( "Total" );
	
EndProcedure

#endregion

&AtServer
Procedure applyCurrency ()
	
	setRate ();
	calcTotals ( Object );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure 

&AtServer
Procedure fillHeader ()
	
	table = getSettings ();
	settings = ChartsOfCharacteristicTypes.Settings;
	limit = settings.LVILimit;
	amortizationAccount = settings.LVIAmortizationAccount;
	for each row in table do
		parameter = row.Parameter;
		value = row.Value;
		if ( parameter = limit ) then
			Object.CostLimit = value;
		elsif ( parameter = amortizationAccount ) then 
			Object.AmortizationAccount = value;
		else
			Object.ExploitationAccount = value;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function getSettings ()
	
	accounts = new Array ();
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.LVILimit )" );
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.LVIAmortizationAccount )" );
	accounts.Add ( "value ( ChartOfCharacteristicTypes.Settings.LVIExploitationAccount )" );
	s = "
	|select Settings.Parameter as Parameter, Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( , Parameter in ( " + StrConcat ( accounts, "," ) + ") ) as Settings
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsLVI () ) then
		loadRow ( SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsLVISaveAndNew () ) then
		loadRow ( SelectedValue );
		newRow ( false );
	endif;	
	
EndProcedure

&AtClient
Procedure loadRow ( Params )
	
	value = Params.Value;
	data = Items.Items.CurrentData;
	if ( value = undefined ) then
		if ( Params.NewRow ) then
			Object.Items.Delete ( data );
		endif;
	else
		FillPropertyValues ( data, value );
		calcTotals ( Object );
	endif;
	
EndProcedure 

&AtClient
Procedure newRow ( Clone )
	
	Forms.NewRow ( ThisObject, Items.Items, Clone );
	editRow ( true );
	
EndProcedure

&AtClient
Procedure editRow ( NewRow = false ) 

	if ( ReadOnly
		or Items.Items.CurrentData = undefined ) then
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Company", Object.Company );
	p.Insert ( "ShowPrices", Object.ShowPrices );
	p.Insert ( "NewRow", NewRow );
	OpenForm ( "Document.Startup.Form.LVI", p, ThisObject );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Forms.DeleteLastRow ( Object.Items, "Item" );
	calcTotals ( Object );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	applyPrices ();
	
EndProcedure

&AtServer
Procedure applyPrices ()
	
	cache = new Map ();
	date = Object.Date;
	prices = Object.Prices;
	warehouse = Object.Warehouse;
	currency = Object.Currency;
	vatUse = Object.VATUse;
	for each row in Object.Items do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, , , , warehouse, currency );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	
EndProcedure 

&AtClient
Procedure ShowPricesOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.ShowPrices" );
	
EndProcedure

&AtClient
Procedure VATUseOnChange ( Item )
	
	applyVATUse ();
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	editRow ();
	
EndProcedure

&AtClient
Procedure ItemsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	newRow ( Clone );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

// *****************************************
// *********** Group More

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

// *****************************************
// *********** Group Stakeholders

&AtClient
Procedure ApprovedOnChange ( Item )
	
	MembersForm.SetPosition ( Object.Approved, Object.ApprovedPosition, Object.Date );
	
EndProcedure

&AtClient
Procedure HeadOnChange ( Item )
	
	MembersForm.SetPosition ( Object.Head, Object.HeadPosition, Object.Date );
	
EndProcedure

&AtClient
Procedure MembersMemberOnChange ( Item )
	
	MembersForm.FillPosition ( Items.Members.CurrentData, Object.Date );
	
EndProcedure
