&AtServer
var Env;
&AtServer
var Base;
&AtServer
var Copy;
&AtClient
var ItemsRow;
&AtClient
var FixedAssetsRow;
&AtClient
var IntangibleAssetsRow;
&AtClient
var AccountsRow;
&AtServer
var InvoiceRecordExists;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	updateBalanceDue ();
	initCurrency ();
	updateChangesPermission ();
	InvoiceRecords.Read ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

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
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		DocumentForm.Init ( Object );
		initCurrency ();
		Base = Parameters.Basis;
		if ( Base = undefined ) then
			Copy = not Parameters.CopyingValue.IsEmpty ();
			fillNew ();
			fillByVendor ();
		else
			fillByBase ();	
		endif;
		updateBalanceDue ();
		updateChangesPermission ();
	endif;
	setButtons ();
	setLinks ();
	setAccuracy ();
	setSocial ();
	Forms.ActivatePage ( ThisObject, "ItemsTable,FixedAssets,IntangibleAssets,Accounts" );
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
	|ContractAmount show filled ( ContractCurrency ) and ContractCurrency <> Object.Currency;
	|ContractAmount title/Form.ContractCurrency ContractCurrency <> Object.Currency;
	|Rate Factor enable
	|filled ( LocalCurrency )
	|and filled ( ContractCurrency )
	|and ( Object.Currency <> LocalCurrency or ContractCurrency <> LocalCurrency );
	|Links show ShowLinks;
	|CreatePayment show BalanceDue <> 0;
	|VAT ItemsVATAccount FixedAssetsVATAccount IntangibleAssetsVATAccount AccountsVATAccount
	|	ItemsVATCode ItemsVAT FixedAssetsVATCode FixedAssetsVAT IntangibleAssetsVATCode IntangibleAssetsVAT
	|	AccountsVATCode AccountsVAT show Object.VATUse > 0;
	|ItemsTotal FixedAssetsTotal IntangibleAssetsTotal AccountsTotal show Object.VATUse = 2;
	|ItemsProducerPrice show UseSocial;
	|Warning show ChangesDisallowed;
	|FormInvoice show filled ( InvoiceRecord );
	|NewInvoiceRecord show FormStatus = Enum.FormStatuses.Canceled or empty ( FormStatus );
	|Header GroupItems GroupFixedAssets GroupIntangibleAssets GroupAccounts GroupAdditional Footer lock ChangesDisallowed;
	|ItemsAddGroup FixedAssetsAddGroup IntangibleAssetsAddGroup AccountsAddGroup hide ChangesDisallowed;
	|ItemsVendorInvoice FixedAssetsVendorInvoice IntangibleAssetsVendorInvoice AccountsVendorInvoice show InvoicesInTable;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
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
	
EndProcedure

&AtServer
Procedure fillByVendor ()
	
	apply = Parameters.FillingValues.Property ( "Vendor" )
	and not Copy 
	and not Object.Vendor.IsEmpty ();
	if ( apply ) then
		applyVendor ();
	endif;

EndProcedure

&AtServer
Procedure applyVendor ()
	
	data = AccountsMap.Organization ( Object.Vendor, Object.Company, "VendorAccount" );
	Object.VendorAccount = data.VendorAccount;
	data = DF.Values ( Object.Vendor, "VendorContract, VendorContract.Company as Company, VATUse" );
	if ( data.Company = Object.Company ) then
		Object.Contract = data.VendorContract;
	endif; 
	Object.VATUse = data.VATUse;
	applyContract ();
	
EndProcedure

&AtServer
Procedure applyContract ()
	
	data = DF.Values ( Object.Contract,
		"Currency, VendorAdvances, VendorRateType, VendorRate, VendorFactor" );
	ContractCurrency = data.Currency;
	if ( data.VendorRateType = Enums.CurrencyRates.Fixed
		and data.VendorRate <> 0 ) then
		currency = new Structure ( "Rate, Factor", data.VendorRate, data.VendorFactor );
	else
		currency = CurrenciesSrv.Get ( data.Currency, Object.Date );
	endif;
	Object.CloseAdvances = data.VendorAdvances;
	Object.Rate = currency.Rate;
	Object.Factor = currency.Factor;
	Object.Currency = ContractCurrency;
	InvoiceForm.SetCurrencyList ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Currency" );

EndProcedure

&AtClientAtServerNoContext
Procedure updateTotals ( Form, Row = undefined, CalcVAT = true )

	object = Form.Object;
	if ( Row <> undefined ) then
		Computations.Total ( Row, object.VATUse, CalcVAT );
	endif;
	InvoiceForm.CalcTotals ( Form );
	InvoiceForm.CalcBalanceDue ( Form );
	Appearance.Apply ( Form, "BalanceDue" );

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
	sqlFixedAssets ();
	sqlIntangibleAssets ();
	sqlAccounts ();
	getTables ();
	
EndProcedure

&AtServer
Procedure sqlFields ()
	
	s = "
	|// @Fields
	|select Document.Warehouse as Warehouse, Document.VendorAccount as VendorAccount, 
	|	Document.Contract.VendorAdvances as CloseAdvances, Document.Company as Company, Document.Vendor as Vendor, 
	|	Document.Contract as Contract, Document.Currency as Currency, Document.Contract.Currency as ContractCurrency,
	|	Document.Contract.VendorRateType as RateType, Document.Rate as Rate, Document.Factor as Factor,
	|	Document.VATUse as VATUse
	|from Document.VendorInvoice as Document
	|where Document.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlItems ()
	
	s = "
	|// #Items
	|select Items.Ref as VendorInvoice, Items.Account as Account, Items.Amount as Amount, Items.Capacity as Capacity,
	|	Items.Discount as Discount, Items.DiscountRate as DiscountRate, Items.DocumentOrder as DocumentOrder,
	|	Items.DocumentOrderRowKey as DocumentOrderRowKey, Items.Feature as Feature, Items.Item as Item,
	|	Items.Price as Price, Items.Package as Package, Items.Prices as Prices, Items.ProducerPrice as ProducerPrice,
	|	case when Items.PurchaseOrder = value ( Document.PurchaseOrder.EmptyRef ) then Items.Ref.PurchaseOrder else Items.PurchaseOrder end as PurchaseOrder,
	|	Items.Quantity - isnull ( Returned.Quantity, 0 ) as Quantity, Items.QuantityPkg as QuantityPkg,
	|	Items.RowKey as RowKey, Items.Series as Series, Items.Social as Social, Items.Total as Total,
	|	Items.VAT as VAT, Items.VATAccount as VATAccount, Items.VATCode as VATCode,
	|	Items.VATRate as VATRate, Items.Warehouse as Warehouse, Returned.Ref is not null as Partial
	|from Document.VendorInvoice.Items as Items
	|	//
	|	// Returned
	|	//
	|	left join Document.VendorReturn.Items as Returned
	|	on Returned.VendorInvoice = Items.Ref
	|	and Returned.Item = Items.Item
	|	and Returned.Feature = Items.Feature
	|	and Returned.Series = Items.Series
	|	and Returned.PurchaseOrder = Items.PurchaseOrder
	|	and Returned.RowKey = Items.RowKey
	|	and Returned.DocumentOrder = Items.DocumentOrder
	|	and Returned.DocumentOrderRowKey = Items.DocumentOrderRowKey
	|	and Returned.Ref.Posted
	|where Items.Ref = &Base
	|and Items.Quantity - isnull ( Returned.Quantity, 0 ) > 0
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );	
	
EndProcedure

&AtServer
Procedure sqlFixedAssets ()
	
	s = "
	|// #FixedAssets
	|select FixedAssets.Ref as VendorInvoice, FixedAssets.Amount as Amount, FixedAssets.Item as Item, 
	|	FixedAssets.Total as Total, FixedAssets.VAT as VAT, FixedAssets.VATAccount as VATAccount,
	|	FixedAssets.VATCode as VATCode, FixedAssets.VATRate as VATRate
	|from Document.VendorInvoice.FixedAssets as FixedAssets
	|	//
	|	// Returned
	|	//
	|	left join Document.VendorReturn.FixedAssets as Returned
	|	on Returned.VendorInvoice = FixedAssets.Ref
	|	and Returned.Item = FixedAssets.Item
	|	and Returned.Ref.Posted
	|where FixedAssets.Ref = &Base
	|and Returned.Item is null
	|order by FixedAssets.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlIntangibleAssets ()
	
	s = "
	|// #IntangibleAssets
	|select IntangibleAssets.Ref as VendorInvoice, IntangibleAssets.Amount as Amount, IntangibleAssets.Item as Item, 
	|	IntangibleAssets.Total as Total, IntangibleAssets.VAT as VAT, IntangibleAssets.VATAccount as VATAccount, 
	|	IntangibleAssets.VATCode as VATCode, IntangibleAssets.VATRate as VATRate
	|from Document.VendorInvoice.IntangibleAssets as IntangibleAssets
	|	//
	|	// Returned
	|	//
	|	left join Document.VendorReturn.IntangibleAssets as Returned
	|	on Returned.VendorInvoice = IntangibleAssets.Ref
	|	and Returned.Item = IntangibleAssets.Item
	|	and Returned.Ref.Posted
	|where IntangibleAssets.Ref = &Base
	|and Returned.Item is null
	|order by IntangibleAssets.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure sqlAccounts ()
	
	s = "
	|// #Accounts
	|select Accounts.Ref as VendorInvoice, Accounts.Account as Account, Accounts.Amount as Amount, 
	|	Accounts.Content as Content, Accounts.Currency as Currency, Accounts.CurrencyAmount as CurrencyAmount, Accounts.Dim1 as Dim1,
	|	Accounts.Dim2 as Dim2, Accounts.Dim3 as Dim3, Accounts.Factor as Factor, Accounts.Quantity - isnull ( Returned.Quantity, 0 ) as Quantity,
	|	Accounts.Rate as Rate, Accounts.Total as Total, Accounts.VAT as VAT, Accounts.VATAccount as VATAccount,
	|	Accounts.VATCode as VATCode, Accounts.VATRate as VATRate
	|from Document.VendorInvoice.Accounts as Accounts
	|	//
	|	// Returned
	|	//
	|	left join Document.VendorReturn.Accounts as Returned
	|	on Returned.VendorInvoice = Accounts.Ref
	|	and Returned.Account = Accounts.Account
	|	and Returned.Dim1 = Accounts.Dim1
	|	and Returned.Dim2 = Accounts.Dim2
	|	and Returned.Dim3 = Accounts.Dim3
	|	and Returned.Ref.Posted
	|where Accounts.Ref = &Base
	|and Accounts.Quantity - isnull ( Returned.Quantity, 0 ) > 0
	|order by Accounts.LineNumber
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
		if ( row.Partial ) then
			Computations.Packages ( newRow );
			Computations.Amount ( newRow );
			Computations.Total ( newRow, vatUse );
		endif;
	enddo;		
	table = Object.FixedAssets;
	for each row in Env.FixedAssets do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row );
	enddo;		
	table = Object.IntangibleAssets;
	for each row in Env.IntangibleAssets do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row );
	enddo;		
	table = Object.Accounts;
	for each row in Env.Accounts do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row );
	enddo;
	updateTotals ( ThisObject );
	
EndProcedure

&AtServer
Procedure setButtons ()
	
	setInvoices ();
	fillButtons ( Items.ItemsAddGroup, "Items" );
	fillButtons ( Items.FixedAssetsAddGroup, "FixedAssets" );
	fillButtons ( Items.IntangibleAssetsAddGroup, "IntangibleAssets" );
	fillButtons ( Items.AccountsAddGroup, "Accounts" );
	
EndProcedure

&AtServer
Procedure setInvoices ()
	
	table = Object.Items.Unload ( , "VendorInvoice" );
	CollectionsSrv.Join ( table, Object.FixedAssets );
	CollectionsSrv.Join ( table, Object.IntangibleAssets );
	CollectionsSrv.Join ( table, Object.Accounts );
	table.GroupBy ( "VendorInvoice" );
	Invoices.LoadValues ( table.UnloadColumn ( "VendorInvoice" ) );
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
		button.Title = Output.ChooseVendorInvoice ();
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
		SQL.Perform ( env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	selection = Env.Selection;
	if ( not InvoicesInTable ) then
		s = "
		|// #VendorInvoices
		|select Documents.Ref as Document,
		|	case when Documents.ReferenceDate = datetime ( 1, 1, 1 ) then Documents.Date else Documents.ReferenceDate end as Date,
		|	case when Documents.Reference = """" then Documents.Number else Documents.Reference end as Number
		|from Document.VendorInvoice as Documents
		|where Documents.Ref in ( &Invoices )
		|";
		selection.Add ( s );			
	endif;
	if ( isNew () ) then
		return;
	endif;
	InvoiceRecordExists = not InvoiceRecord.IsEmpty ();
	if ( InvoiceRecordExists ) then
		s = "
		|// #InvoiceRecords
		|select Documents.Ref as Document, Documents.DeliveryDate as Date, Documents.Number as Number
		|from Document.InvoiceRecord as Documents
		|where Documents.Base = &Ref
		|and not Documents.DeletionMark
		|";
		selection.Add ( s );
	endif;
	s = "
	|// #VendorRefunds
	|select Documents.Ref as Document,
	|	case when Documents.ReferenceDate = datetime ( 1, 1, 1 ) then Documents.Date else Documents.ReferenceDate end as Date,
	|	case when Documents.Reference = """" then Documents.Number else Documents.Reference end as Number
	|from Document.VendorRefund as Documents
	|where Documents.Ref in (
	|	select Documents.Ref as Ref
	|	from Document.VendorRefund as Documents
	|	where Documents.Base = &Ref
	|	union
	|	select Documents.Ref as Ref
	|	from Document.VendorRefund.Payments as Documents
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
		parts.Add ( URLPanel.DocumentsToURL ( Env.VendorInvoices, meta.VendorInvoice ) );	
	endif;
	if ( not isNew () ) then
		if ( InvoiceRecordExists ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.InvoiceRecords, meta.InvoiceRecord ) );
		endif;
		parts.Add ( URLPanel.DocumentsToURL ( Env.VendorRefunds, meta.VendorRefund ) );		
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, AccountsQuantity" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
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
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	type = TypeOf ( SelectedValue );
	if ( type = Type ( "DocumentRef.VendorInvoice" ) ) then
		data = DF.Values ( SelectedValue, "VATUse" );
		if ( data.VATUse = Object.VATUse ) then
			selectItems ( SelectedValue );	
		else
			Output.WrongVATUse ();
		endif; 
	elsif ( type = Type ( "Structure" ) ) then
		fillItems ( SelectedValue.Items );
		fillFixedAssets ( SelectedValue.FixedAssets );
		fillIntangibleAssets ( SelectedValue.IntangibleAssets );
		fillAccounts ( SelectedValue.Accounts );
		updateTotals ( ThisObject );
		applyInvoices ();
	endif;
	
EndProcedure

&AtClient
Procedure selectItems ( Document )
	
	p = new Structure ();
	p.Insert ( "VendorInvoice", Document );
	p.Insert ( "VendorReturn", Object.Ref );
	OpenForm ( "Document.VendorReturn.Form.Items", p, ThisObject ); 
	
EndProcedure

&AtClient
Procedure fillItems ( Table )
	
	tableItems = Object.Items;
	filter = new Structure ( "VendorInvoice, Item, Feature, Series" );
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

&AtClient
Procedure fillFixedAssets ( Table )
	
	tableFixedAssets = Object.FixedAssets;
	for each row in Table do
		newRow = tableFixedAssets.Add ();
		FillPropertyValues ( newRow, row );
	enddo;		
	
EndProcedure

&AtClient
Procedure fillIntangibleAssets ( Table )
	
	tableIntangibleAssets = Object.IntangibleAssets;
	for each row in Table do
		newRow = tableIntangibleAssets.Add ();
		FillPropertyValues ( newRow, row );
	enddo;		
	
EndProcedure

&AtClient
Procedure fillAccounts ( Table )
	
	tableAccounts = Object.Accounts;
	filter = new Structure ( "VendorInvoice, Account, Dim1, Dim2, Dim3" );
	for each row in Table do
		FillPropertyValues ( filter, row );
		foundedRows = tableAccounts.FindRows ( filter );
		if ( foundedRows.Count () > 0 ) then
			foundedRow = foundedRows [ 0 ];
			foundedRow.Quantity = foundedRow.Quantity + row.Quantity;
		else
			newRow = tableAccounts.Add ();
			FillPropertyValues ( newRow, row );	
		endif;
	enddo;		
	
EndProcedure

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	alreadyProcessed = TypeOf ( NewObject ) = Type ( "DocumentRef.VendorRefund" );
	if ( alreadyProcessed ) then
		return;
	else
		readNewInvoices ( NewObject );
		updateLinks ();
	endif;
	
EndProcedure

&AtServer
Procedure readNewInvoices ( NewObject ) 

	type = TypeOf ( NewObject );
	if ( type <> Type ( "DocumentRef.InvoiceRecord" ) ) then
		return;
	endif;
	InvoiceRecords.Read ( ThisObject );
	Appearance.Apply ( ThisObject, "InvoiceRecord, FormStatus, ChangesDisallowed" );

EndProcedure

&AtServer
Procedure updateLinks ()
	
	setLinks ();
	updateBalanceDue ();

EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.InvoiceRecordsWrite ()
		and Source.Ref = InvoiceRecord ) then
		readPrinted ();
	elsif ( EventName = Enum.MessageVendorRefundIsSaved ()
		and Parameter.Contract = Object.Contract ) then
		updateLinks ();
		NotifyChanged ( Object.Ref );
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure readPrinted ()
	
	InvoiceRecords.Read ( ThisObject );
	Appearance.Apply ( ThisObject, "FormStatus, ChangesDisallowed" );
	
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
	
	Notify ( Enum.MessageVendorReturnIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure VendorOnChange ( Item )
	
	applyVendor ();
	
EndProcedure

&AtClient
Procedure ContractOnChange ( Item )
	
	applyContract ();
	
EndProcedure

&AtClient
Procedure ReferenceOnChange ( Item )
	
	applyReference ();

EndProcedure

&AtClient
Procedure applyReference ()
	
	InvoiceForm.AdjustReference ( Object );
	InvoiceForm.ExtractSeries ( Object );

EndProcedure

&AtClient
Procedure VATUseOnChange ( Item )
	
	applyVATUse ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtServer
Procedure applyVATUse ()
	
	vatUse = Object.VATUse;
	for each row in Object.Items do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.FixedAssets do
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.IntangibleAssets do
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.Accounts do
		Computations.Total ( row, vatUse );
	enddo;
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
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
	filter = new Structure ( "Company, Vendor, Contract, Posted", Object.Company, Object.Vendor, Object.Contract, true );
	p = new Structure ( "FixedSettings, Filter", settings, filter );
	OpenForm ( "Document.VendorInvoice.ChoiceForm", p, ThisObject );
	
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
	
	if ( Item.CurrentItem.Name = "ItemsVendorInvoice" ) then
		ShowValue ( , ItemsRow.VendorInvoice );			
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

&AtServer
Procedure applyInvoices ()
	
	setButtons ();
	setLinks ();			
	Appearance.Apply ( ThisObject, "InvoicesInTable" );
	
EndProcedure

&AtClient
Procedure applySocial () 

	UseSocial = findSocial ( Object.Items );
	Appearance.Apply ( ThisObject, "UseSocial" );

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
// *********** Group FixedAssets

&AtClient
Procedure FixedAssetsOnActivateRow ( Item )
	
	FixedAssetsRow = Item.CurrentData; 		
	
EndProcedure

&AtClient
Procedure FixedAssetsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Item.CurrentItem.Name = "FixedAssetsVendorInvoice" ) then
		ShowValue ( , FixedAssetsRow.VendorInvoice );			
	endif;
	
EndProcedure

&AtClient
Procedure FixedAssetsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure FixedAssetsAfterDeleteRow ( Item )
	
	updateTotals ( ThisObject );
	applyInvoices ();
	
EndProcedure

// *****************************************
// *********** Group IntangibleAssets

&AtClient
Procedure IntangibleAssetsOnActivateRow ( Item )
	
	IntangibleAssetsRow = Item.CurrentData; 		
	
EndProcedure

&AtClient
Procedure IntangibleAssetsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Item.CurrentItem.Name = "IntangibleAssetsVendorInvoice" ) then
		ShowValue ( , IntangibleAssetsRow.VendorInvoice );			
	endif;
	
EndProcedure

&AtClient
Procedure IntangibleAssetsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure IntangibleAssetsAfterDeleteRow ( Item )
	
	updateTotals ( ThisObject );
	applyInvoices ();
	
EndProcedure

// *****************************************
// *********** Group Accounts

&AtClient
Procedure AccountsOnActivateRow ( Item )
	
	AccountsRow = Item.CurrentData; 		
	
EndProcedure

&AtClient
Procedure AccountsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Item.CurrentItem.Name = "AccountsVendorInvoice" ) then
		ShowValue ( , AccountsRow.VendorInvoice );			
	endif;
	
EndProcedure

&AtClient
Procedure AccountsOnEditEnd ( Item, NewRow, CancelEdit )
	
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient                     
Procedure AccountsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;	
	
EndProcedure

&AtClient
Procedure AccountsAfterDeleteRow ( Item )
	
	updateTotals ( ThisObject );
	applyInvoices ();
	
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
