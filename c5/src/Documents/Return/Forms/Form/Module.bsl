&AtServer
var Env;
&AtServer
var Base;
&AtServer
var Copy;
&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	updateBalanceDue ();
	initCurrency ();
	setSocial ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateBalanceDue ()

	InvoiceForm.SetPaymentsApplied ( ThisObject );
	InvoiceForm.CalcBalanceDue ( ThisObject );
	Appearance.Apply ( ThisObject, "BalanceDue" );

EndProcedure

&AtServer
Procedure initCurrency ()
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	InvoiceForm.SetContractCurrency ( ThisObject );
	InvoiceForm.SetCurrencyList ( ThisObject );
	
EndProcedure

&AtServer
Procedure setSocial () 

	UseSocial = findSocial ( Object.Items );

EndProcedure

&AtClientAtServerNoContext
Function findSocial ( Items ) 

	for each row in Items do
		if ( row.Social ) then
			return true;
		endif;
	enddo;
	return false;

EndFunction

&AtClient
Procedure applySocial () 

	UseSocial = findSocial ( Object.Items );
	Appearance.Apply ( ThisObject, "UseSocial" );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		DocumentForm.Init ( Object );
		initCurrency ();
		Base = Parameters.Basis;
		if ( Base = undefined ) then
			Copy = not Parameters.CopyingValue.IsEmpty ();
			fillNew ();
			fillByCustomer ();
		else
			fillByBase (); 
		endif;
		updateBalanceDue ();
	endif; 
	setAccuracy ();
	setButtons ();
	setLinks ();
	setSocial ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|ContractAmount show filled ( ContractCurrency ) and ContractCurrency <> Object.Currency;
	|ContractAmount title/Form.ContractCurrency ContractCurrency <> Object.Currency;
	|Rate Factor enable
	|filled ( LocalCurrency )
	|and filled ( ContractCurrency )
	|and ( Object.Currency <> LocalCurrency or ContractCurrency <> LocalCurrency );
	|CreatePayment show BalanceDue <> 0;
	|VAT ItemsVATAccount show Object.VATUse > 0;
	|ItemsVATCode ItemsVAT ItemsTotal show Object.VATUse > 0;
	|ItemsProducerPrice ItemsExtraCharge show UseSocial;
	|ItemsInvoice show InvoicesInTable;
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
	Object.Department = Logins.Settings ( "Department" ).Department;
	Object.Currency = Application.Currency ();
	
EndProcedure 

&AtServer
Procedure fillByCustomer ()
	
	apply = Parameters.FillingValues.Property ( "Customer" )
	and not Copy 
	and not Object.Customer.IsEmpty ();
	if ( apply ) then
		applyCustomer ();
	endif;

EndProcedure 

&AtServer
Procedure applyCustomer ()
	
	customer = Object.Customer;
	company = Object.Company;
	data = AccountsMap.Organization ( customer, company, "CustomerAccount" );
	Object.CustomerAccount = data.CustomerAccount;
	data = DF.Values ( customer, "CustomerContract, CustomerContract.Company as Company, VATUse" );
	if ( data.Company = company ) then
		Object.Contract = data.CustomerContract;
	endif; 
	Object.VATUse = data.VATUse;
	applyContract ();
	applyVATUse ();
	
EndProcedure

&AtServer
Procedure applyContract ()
	
	data = DF.Values ( Object.Contract,
		"Currency, CustomerAdvances, CustomerRateType, CustomerRate, CustomerFactor" );
	ContractCurrency = data.Currency;
	if ( data.CustomerRateType = Enums.CurrencyRates.Fixed
		and data.CustomerRate <> 0 ) then
		currency = new Structure ( "Rate, Factor", data.CustomerRate, data.CustomerFactor );
	else
		currency = CurrenciesSrv.Get ( data.Currency, Object.Date );
	endif;
	Object.CloseAdvances = data.CustomerAdvances;
	Object.Rate = currency.Rate;
	Object.Factor = currency.Factor;
	Object.Currency = ContractCurrency;
	InvoiceForm.SetCurrencyList ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Currency" );

EndProcedure

&AtServer
Procedure applyVATUse ()
	
	vatUse = Object.VATUse;
	for each row in Object.Items do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
		Computations.ExtraCharge ( row );
	enddo; 
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
EndProcedure

&AtServer
Procedure fillByBase ()
	
	setEnv ();
	getData ();
	fillHeader ();
	fillTables ();
	
EndProcedure

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	
EndProcedure

&AtServer
Procedure getData ()
	
	sqlFields ();
	sqlItems ();
	getTables ();
	
EndProcedure

&AtServer
Procedure sqlFields ()
	
	s = "
	|// @Fields
	|select Document.Company as Company, Document.Contract as Contract, Document.Currency as Currency, Document.Customer as Customer, 
	|	Document.CustomerAccount as CustomerAccount, Document.Department as Department, Document.Ref as Invoice,
	|	Document.VATUse as VATUse, Document.Contract.Currency as ContractCurrency, Document.Contract.CustomerRateType as RateType,
	|	Document.Rate as Rate, Document.Factor as Factor, Document.Warehouse as Warehouse,
	|	Document.Contract.CustomerAdvances as CloseAdvances
	|from Document.Invoice as Document
	|where Document.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlItems ()
	
	s = "
	|// #Items
	|select Items.Ref as Invoice, Items.Account as Account, Items.Amount as Amount, Items.Capacity as Capacity,
	|	Items.Discount as Discount, Items.DiscountRate as DiscountRate, Items.ExtraCharge as ExtraCharge,
	|	Items.Feature as Feature, Items.Income as Income, Items.Item as Item, Items.Package as Package,
	|	Items.Price as Price, Items.Prices as Prices, Items.ProducerPrice as ProducerPrice, Items.Quantity - isnull ( Returned.Quantity, 0 ) as Quantity, 
	|	Items.QuantityPkg as QuantityPkg, Items.RowKey as RowKey, Items.SalesCost as SalesCost,
	|	case when Items.SalesOrder = value ( Document.SalesOrder.EmptyRef ) then Items.Ref.SalesOrder else Items.SalesOrder end as SalesOrder,
	|	Items.Series as Series, Items.Social as Social, Items.Total as Total, Items.VAT as VAT, Items.VATAccount as VATAccount, Items.VATCode as VATCode,
	|	Items.VATRate as VATRate, Items.Warehouse as Warehouse
	|from Document.Invoice.Items as Items
	|	//
	|	// Returned
	|	//
	|	left join Document.Return.Items as Returned
	|	on Returned.Invoice = Items.Ref
	|	and Returned.Item = Items.Item
	|	and Returned.Feature = Items.Feature
	|	and Returned.Package = Items.Package
	|	and Returned.Series = Items.Series
	|	and Returned.Account = Items.Account
	|	and Returned.SalesOrder = Items.SalesOrder
	|	and Returned.RowKey = Items.RowKey
	|	and Returned.Ref.Posted
	|where Items.Ref = &Base
	|and Items.Quantity - isnull ( Returned.Quantity, 0 ) > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure getTables ()
	
	Env.Q.SetParameter ( "Base", Base );
	SQL.Perform ( Env );
	
EndProcedure

&AtServer
Procedure fillHeader ()
	
	fields = Env.Fields;
	FillPropertyValues ( Object, fields );
	ContractCurrency = fields.ContractCurrency;
	if ( fields.RateType = Enums.CurrencyRates.Current ) then
		currency = CurrenciesSrv.Get ( Object.Currency, Object.Date );
		Object.Rate = currency.Rate;
		Object.Factor = currency.Factor;
	endif;
	InvoiceForm.SetCurrencyList ( ThisObject );

EndProcedure

&AtServer
Procedure fillTables ()
	
	table = Object.Items;
	vatUse = Object.VATUse;
	for each row in Env.Items do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row );
		Computations.Packages ( newRow );
		Computations.Amount ( newRow );
		Computations.Total ( newRow, vatUse );
	enddo;		
	updateTotals ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure updateTotals ( Form, Row = undefined, CalcVAT = true )
	
	object = Form.Object;
	if ( Row <> undefined ) then
		Computations.Total ( Row, object.VATUse, CalcVAT );
	endif;
	items = Object.Items;
	vat = items.Total ( "VAT" );
	amount = items.Total ( "Total" );
	object.VAT = vat;
	object.Amount = amount;
	object.Discount = items.Total ( "Discount" );
	object.GrossAmount = amount - ? ( object.VATUse = 2, vat, 0 ) + object.Discount;
	InvoiceForm.CalcBalanceDue ( Form );
	Appearance.Apply ( Form, "BalanceDue" );
	
EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
EndProcedure 

&AtServer
Procedure setButtons ()
	
	setInvoices ();
	fillButtons ( Items.ItemsAddGroup, "Items" );
	
EndProcedure

&AtServer
Procedure setInvoices ()
	
	table = Object.Items.Unload ( , "Invoice" );
	table.GroupBy ( "Invoice" );
	Invoices.LoadValues ( table.UnloadColumn ( "Invoice" ) );
	InvoicesInTable = Invoices.Count () > 1;
	
EndProcedure

&AtServer
Procedure fillButtons ( Parent, Prefix )
	
	deleteButtons ( Parent );
	createButtons ( Parent, Prefix );
	
EndProcedure

&AtServer
Procedure deleteButtons ( Parent )
	
	buttons = Parent.ChildItems;
	i = buttons.Count () - 1;
	while ( i >= 0 ) do
		Items.Delete ( buttons [ i ] );
		i = i - 1;	
	enddo;
	
EndProcedure

&AtServer
Procedure createButtons ( Parent, Prefix )
	
	commandName = "AddFromInvoice";
	actionName = "AddFromInvoice";
	buttonName = Prefix + commandName;
	for i = 0 to Invoices.Count () - 1 do
		createCommand ( commandName + i, actionName );
		createButton ( buttonName + i, Parent, commandName + i, Invoices [ i ] );  
	enddo;
	commandName = "ChoiceInvoice";
	actionName = "ChoiceInvoice";
	buttonName = Prefix + commandName;
	createCommand ( commandName, actionName );
	createButton ( buttonName, Parent, commandName );
	
EndProcedure

&AtServer
Procedure createCommand ( Name, Action )
	
	if ( Commands.Find ( Name ) = undefined ) then
		command = Commands.Add ( Name );
		command.Action = Action;
		command.ModifiesStoredData = true;
	endif;		
	
EndProcedure

&AtServer
Procedure createButton ( Name, Parent, CommandName, Title = "" )
	
	button = Items.Add ( Name, Type ( "FormButton" ), Parent );
	button.CommandName = CommandName;
	if ( CommandName = "ChoiceInvoice" ) then
		button.Title = Output.ChoiceInvoice ();
		button.Picture = PictureLib.ChooseValue;
	else	
		button.Title = Title;	
	endif; 
	
EndProcedure

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", Object.Ref );
		q.SetParameter ( "Invoices", Invoices.UnloadValues () );			
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	selection = Env.Selection;
	if ( not InvoicesInTable ) then
		s = "
		|// #Invoices
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.Invoice as Documents
		|where Documents.Ref in ( &Invoices )
		|";
		selection.Add ( s );			
	endif;
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #InvoiceRecords
	|select Documents.Ref as Document, Documents.DeliveryDate as Date, Documents.Number as Number
	|from Document.InvoiceRecord as Documents
	|where Documents.Base in ( &Invoices )  
	|and not Documents.DeletionMark
	|;
	|// #Refunds
	|select Documents.Ref as Document,
	|	case when Documents.ReferenceDate = datetime ( 1, 1, 1 ) then Documents.Date else Documents.ReferenceDate end as Date,
	|	case when Documents.Reference = """" then Documents.Number else Documents.Reference end as Number
	|from Document.Refund as Documents
	|where Documents.Ref in (
	|	select Documents.Ref as Ref
	|	from Document.Refund as Documents
	|	where Documents.Base = &Ref
	|	union
	|	select Documents.Ref as Ref
	|	from Document.Refund.Payments as Documents
	|	where &Ref in ( Documents.Detail, Documents.Document )
	|)
	|and not Documents.DeletionMark
	|";
	selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not InvoicesInTable ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Invoices, meta.Invoice ) );	
	endif;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.InvoiceRecords, meta.InvoiceRecord ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.Refunds, meta.Refund ) );		
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageRefundIsSaved ()
		and Parameter.Contract = Object.Contract ) then
		updateLinks ();
		NotifyChanged ( Object.Ref );
	endif; 
	
EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	type = TypeOf ( SelectedValue ); 
	if ( type = Type ( "DocumentRef.Invoice" ) ) then 
		data = DF.Values ( SelectedValue, "VATUse" );
		if ( data.VATUse = Object.VATUse ) then
			selectItems ( SelectedValue );	
		else
			Output.WrongVATUse ();
		endif; 
	elsif ( type = Type ( "Structure" ) ) then
		fillItems ( SelectedValue.Items );
		applyInvoices ();
		updateTotals ( ThisObject );
	endif;
	
EndProcedure

&AtClient
Procedure selectItems ( Document )
	
	p = new Structure ();
	p.Insert ( "Invoice", Document );
	p.Insert ( "Return", Object.Ref );
	OpenForm ( "Document.Return.Form.Items", p, ThisObject );		
	
EndProcedure

&AtClient
Procedure fillItems ( Table )
	
	tableItems = Object.Items;
	filter = new Structure ( "Invoice, Item, Feature, Series" );
	for each row in Table do
		FillPropertyValues ( filter, row );
		foundedRows = tableItems.FindRows ( filter );
		if ( foundedRows.Count () > 0 ) then
			foundedRow = foundedRows [ 0 ];
			foundedRow.Quantity = foundedRow.Quantity + row.Quantity;
			Computations.Packages ( foundedRow );
			Computations.Amount ( foundedRow );
			Computations.Total ( foundedRow, Object.VATUse );
		else
			newRow = tableItems.Add ();
			FillPropertyValues ( newRow, row );	
		endif; 
	enddo;		
	
EndProcedure

&AtServer
Procedure applyInvoices ()
	
	setButtons ();
	setLinks ();			
	Appearance.Apply ( ThisObject, "InvoicesInTable" );
	
EndProcedure

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	type = TypeOf ( NewObject );
	alreadyProcessed = type = Type ( "DocumentRef.VendorPayment" );
	if ( alreadyProcessed ) then
		return;
	endif;
	updateLinks ();
	
EndProcedure

&AtServer
Procedure updateLinks ()
	
	setLinks ();
	updateBalanceDue ();

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	updateTotals ( ThisObject );
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	updateBalanceDue ();	
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageReturnIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CustomerOnChange ( Item )
	
	applyCustomer ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ContractOnChange ( Item )
	
	applyContract ();
	updateTotals ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Items

//@skip-warning
&AtClient
Procedure AddFromInvoice ( Command )
	
	i = Number ( StrReplace ( Command.Name, "AddFromInvoice", "" ) );
	value = Invoices [ i ].Value;
	selectItems ( value );
	
EndProcedure

//@skip-warning
&AtClient
Procedure ChoiceInvoice ( Command )
	
	date = Periods.GetDocumentDate ( Object );
	settings = new DataCompositionSettings ();
	DC.SetFilter ( settings, "Date", date, DataCompositionComparisonType.LessOrEqual );
	filter = new Structure ( "Company, Department, Customer, Contract, Posted", Object.Company, Object.Department, Object.Customer, Object.Contract, true );
	p = new Structure ( "FixedSettings, Filter", settings, filter );
	OpenForm ( "Document.Invoice.ChoiceForm", p, ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;		
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Item.CurrentItem.Name = "ItemsInvoice" ) then
		ShowValue ( , ItemsRow.Invoice );			
	endif;	
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	updateTotals ( ThisObject );
	applyInvoices ();
	applySocial ();
	
EndProcedure

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

// *****************************************
// *********** Group More

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	InvoiceForm.SetRate ( ThisObject );
	updateTotals ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure 

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure
