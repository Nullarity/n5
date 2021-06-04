&AtServer
var Env;
&AtClient
var ItemsRow export;
&AtClient
var ServicesRow export;
&AtServer
var Copy;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	updateBalanceDue ();
	OrderForm.LoadProcess ( ThisObject );
	initCurrency ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure initCurrency ()
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	InvoiceForm.SetContractCurrency ( ThisObject );
	InvoiceForm.SetCurrencyList ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateBalanceDue ()

	InvoiceForm.SetPaymentsApplied ( ThisObject );
	InvoiceForm.CalcBalanceDue ( ThisObject );
	Appearance.Apply ( ThisObject, "BalanceDue" );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setCurrentUser ();
	if ( isNew () ) then
		Copy = not Parameters.CopyingValue.IsEmpty ();
		initCurrency ();
		DocumentForm.Init ( Object );
		if ( Parameters.Basis = undefined ) then
			fillNew ();
			fillByCustomer ();
		else
			baseType = TypeOf ( Parameters.Basis );
			if ( baseType = Type ( "DocumentRef.IOSheet" ) ) then
				fillByIOSheet ();
			elsif ( baseType = Type ( "DocumentRef.Quote" ) ) then
				fillByQuote ();
			endif; 
		endif; 
		OrderForm.InitRoutePoint ( ThisObject );
		if ( Copy ) then
			OrderForm.ResetCopiedFields ( Object );
		endif; 
		updateBalanceDue ();
	endif; 
	setAccuracy ();
	setLinks ();
	ItemPictures.RestoreGallery ( ThisObject );
	Forms.ActivatePage ( ThisObject, "ItemsTable,Services" );
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
	|FormSendForApproval show RoutePoint = Enum.SalesOrderPoints.New and Object.Creator = CurrentUser;
	|FormRework FormReject show inlist ( RoutePoint, Enum.SalesOrderPoints.DepartmentHeadResolution );
	|FormWrite FormSaveAndNew show
	|MyTask
	|and not Editing
	|and inlist ( RoutePoint, Enum.SalesOrderPoints.Rework, Enum.SalesOrderPoints.DepartmentHeadResolution, Enum.SalesOrderPoints.New, Enum.SalesOrderPoints.Shipping, Enum.SalesOrderPoints.Invoicing );
	|FormReturnToProcess show RoutePoint = Enum.SalesOrderPoints.Rework;
	|FormCommitRejection show RoutePoint = Enum.SalesOrderPoints.Reject;
	|FormCompleteApproval show RoutePoint = Enum.SalesOrderPoints.DepartmentHeadResolution and not Editing;
	|FormModify show
	|CanChange
	|and not Editing
	|and ( ( RoutePoint = Enum.SalesOrderPoints.Finish and Object.Resolution = Enum.Resolutions.Approve )
	|	or ( MyTask and inlist ( RoutePoint, Enum.SalesOrderPoints.Shipping, Enum.SalesOrderPoints.Invoicing ) ) );
	|FormCompleteEdition show Editing;
	|FormCompleteShipping show RoutePoint = Enum.SalesOrderPoints.Shipping and not Editing;
	|FormCompleteInvoicing show RoutePoint = Enum.SalesOrderPoints.Invoicing and not Editing;
	|FormSendForApproval FormRework FormReject FormReturnToProcess FormCommitRejection FormCompleteApproval FormCompleteShipping FormCompleteInvoicing enable MyTask;
	|ItemsTable Services Payments Date Currency Company Memo Department DeliveryDate Prices Currency Rate Factor Warehouse Customer Contract PO VATUse Guarantee lock
	|not Editing
	|and ( not MyTask or inlist ( RoutePoint, Enum.SalesOrderPoints.Reject, Enum.SalesOrderPoints.Shipping, Enum.SalesOrderPoints.Invoicing ) );
	|ItemsSelectItems ServicesSelectItems PaymentsCalcPayments ItemsScan ItemsReserve enable
	|( Editing
	|	or ( not inlist ( RoutePoint, Enum.SalesOrderPoints.Reject, Enum.SalesOrderPoints.Shipping, Enum.SalesOrderPoints.Invoicing ) and MyTask ) );
	|ProcessCompleted show RoutePoint = Enum.SalesOrderPoints.Finish and Object.Resolution = Enum.Resolutions.Approve;
	|ProcessRejected show RoutePoint = Enum.SalesOrderPoints.Finish and Object.Resolution = Enum.Resolutions.Reject;
	|ShowPerformers enable RoutePoint <> Enum.SalesOrderPoints.Finish;
	|ChangesNotification show
	|Started
	|and RoutePoint <> Enum.SalesOrderPoints.Finish
	|and not MyTask;
	|Number lock Started;
	|PageChanges show inlist ( RoutePoint, Enum.SalesOrderPoints.Finish, Enum.SalesOrderPoints.Shipping, Enum.SalesOrderPoints.Invoicing ) and Object.Resolution = Enum.Resolutions.Approve;
	|MemoLabel show filled ( Object.Memo );
	|FormPurchaseOrder show inlist ( RoutePoint, Enum.SalesOrderPoints.Shipping, Enum.SalesOrderPoints.Invoicing ) and not Editing;
	|FormInvoice show RoutePoint = Enum.SalesOrderPoints.Invoicing and not Editing;
	|FormPayment show BalanceDue <> 0 and inlist ( RoutePoint, Enum.SalesOrderPoints.Finish, Enum.SalesOrderPoints.Shipping, Enum.SalesOrderPoints.Invoicing ) and not Editing;
	|PicturesPanel show PicturesEnabled;
	|ItemsShowPictures press PicturesEnabled;
	|FormPrintSalesOrder show not Editing;
	|VAT ItemsVATAccount ServicesVATAccount show Object.VATUse > 0;
	|ItemsVATCode ItemsVAT ItemsTotal ServicesVATCode ServicesVAT ServicesTotal show Object.VATUse > 0
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setCurrentUser ()
	
	CurrentUser = SessionParameters.User;
	
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
	
	data = DF.Values ( Object.Customer, "CustomerContract, VATUse" );
	Object.Contract = data.CustomerContract;
	Object.VATUse = data.VATUse;
	applyContract ();
	applyVATUse ();
	
EndProcedure

&AtServer
Procedure applyContract ()
	
	data = DF.Values ( Object.Contract,
		"CustomerPrices, Currency, CustomerRateType, CustomerRate, CustomerFactor, CustomerDelivery as Delivery" );
	ContractCurrency = data.Currency;
	if ( data.CustomerRateType = Enums.CurrencyRates.Fixed
		and data.CustomerRate <> 0 ) then
		currency = new Structure ( "Rate, Factor", data.CustomerRate, data.CustomerFactor );
	else
		currency = CurrenciesSrv.Get ( data.Currency, Object.Date );
	endif;
	Object.Rate = currency.Rate;
	Object.Factor = currency.Factor;
	Object.Currency = ContractCurrency;
	Object.Prices = data.CustomerPrices;
	InvoiceForm.SetCurrencyList ( ThisObject );
	InvoiceForm.SetDelivery ( ThisObject, data );
	PaymentsTable.Fill ( Object );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure

&AtServer
Procedure applyVATUse ()
	
	vatUse = Object.VATUse;
	for each row in Object.Items do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.Services do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
EndProcedure

#region Filling

&AtServer
Procedure fillByIOSheet ()
	
	SQL.Init ( Env );
	sqlIOSheet ();
	basis = Parameters.Basis;
	Env.Q.SetParameter ( "Base", basis );
	Env.Q.SetParameter ( "Me", SessionParameters.User );
	SQL.Perform ( Env );
	fields = Env.Fields;
	Object.Company = fields.Company;
	Object.Department = fields.Department;
	Object.Customer = fields.Customer;
	applyCustomer ();
	Object.Warehouse = fields.Warehouse;
	Object.DeliveryDate = fields.DeliveryDate;
	Object.Items.Load ( Env.Items );
	Object.IOSheet = basis;
	applyPrices ();
	
EndProcedure 

&AtServer
Procedure sqlIOSheet ()
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Customer as Customer, Documents.Warehouse as Warehouse,
	|	Documents.DeliveryDate as DeliveryDate, Settings.Department as Department
	|from Document.IOSheet as Documents
	|	//
	|	// Settings
	|	//
	|	left join Catalog.UserSettings as Settings
	|	on Settings.Owner = &Me
	|	and Settings.Department.Owner = Documents.Company
	|where Documents.Ref = &Base
	|;
	|// #Items
	|select Items.Capacity as Capacity, Items.Feature as Feature, Items.Item as Item, Items.Package as Package,
	|	Items.Quantity as Quantity, Items.QuantityPkg as QuantityPkg, value ( Enum.Reservation.None ) as Reservation,
	|	Items.Item.VAT as VATCode, Items.Item.VAT.Rate as VATRate
	|from Document.IOSheet.Items as Items
	|where Items.Ref = &Base
	|and Items.Quantity > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure fillByQuote ()
	
	SQL.Init ( Env );
	sqlQuote ();
	Env.Q.SetParameter ( "Base", Parameters.Basis );
	SQL.Perform ( Env );
	checkQuote ();
	fields = Env.Fields;
	FillPropertyValues ( Object, fields );
	Object.Items.Load ( Env.Items );
	Object.Services.Load ( Env.Services );
	Object.Payments.Load ( Env.Payments );
	settings = Logins.Settings ( "Department" );
	Object.Department = settings.Department;
	ContractCurrency = fields.ContractCurrency;
	InvoiceForm.SetCurrencyList ( ThisObject );

EndProcedure

&AtServer
Procedure sqlQuote ()
	
	s = "
	|// @Fields
	|select Document.Amount as Amount, Document.Company as Company, Document.Contract as Contract,
	|	Document.Creator as Creator, Document.Currency as Currency, Document.Contract.Currency as ContractCurrency,
	|	Document.Customer as Customer, Document.DeliveryDate as DeliveryDate, Document.Discount as Discount,
	|	Document.DueDate as DueDate, Document.Factor as Factor, Document.GrossAmount as GrossAmount,
	|	Document.Prices as Prices, Document.Rate as Rate, Document.VAT as VAT, Document.VATUse as VATUse, Document.Warehouse as Warehouse,
	|	presentation ( RejectedQuotes.Cause ) as RejectionCause, Document.Ref as Quote
	|from Document.Quote as Document
	|	//
	|	// RejectedQuotes
	|	//
	|	left join InformationRegister.RejectedQuotes as RejectedQuotes
	|	on RejectedQuotes.Quote = &Base
	|where Document.Ref = &Base
	|;
	|// #Items
	|select Items.Feature as Feature, Items.DeliveryDate as DeliveryDate, Items.DiscountRate as DiscountRate, Items.Item as Item,
	|	Items.Package as Package, Items.Price as Price, Items.Prices as Prices, Items.Quantity as Quantity, Items.QuantityPkg as QuantityPkg,
	|	Items.Discount as Discount, Items.Capacity as Capacity, Items.Total as Total, Items.VAT as VAT, 
	|	Items.VATRate as VATRate, Items.VATCode as VATCode,
	|	Items.Amount as Amount, value ( Enum.Reservation.None ) as Reservation
	|from Document.Quote.Items as Items
	|where Items.Ref = &Base
	|order by Items.LineNumber
	|;
	|// #Services
	|select Services.Feature as Feature, Services.DeliveryDate as DeliveryDate, Services.DiscountRate as DiscountRate,
	|	Services.Item as Item, Services.Discount as Discount, Services.Total as Total,
	|	Services.VAT as VAT, Services.VATRate as VATRate, Services.VATCode as VATCode,
	|	Services.Amount as Amount, Services.Price as Price, Services.Prices as Prices,
	|	Services.Quantity as Quantity, Services.Description as Description,
	|	value ( Enum.Performers.None ) as Performer
	|from Document.Quote.Services as Services
	|where Services.Ref = &Base
	|order by Services.LineNumber
	|;
	|// #Payments
	|select Payments.Amount as Amount, Payments.PaymentDate as PaymentDate, Payments.Option as Option, Payments.Percent as Percent
	|from Document.Quote.Payments as Payments
	|where Payments.Ref = &Base
	|order by Payments.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
&AtServer
Procedure checkQuote ()
	
	documentDate = BegOfDay ( CurrentSessionDate () );
	fields = Env.Fields;
	if ( fields.DueDate < documentDate ) then
		raise Output.QuoteDueDateLessCurrentDate ( new Structure ( "DueDate", Conversion.DateToString ( fields.DueDate ) ) );
	endif; 
	if ( fields.RejectionCause <> null ) then
		raise Output.QuoteRejected ( new Structure ( "Cause", fields.RejectionCause) );
	endif; 
	
EndProcedure 

&AtServer
Procedure applyPrices ()
	
	cache = new Map ();
	vatUse = Object.VATUse;
	date = Object.Date;
	prices = Object.Prices;
	customer = Object.Customer;
	contract = Object.Contract;
	warehouse = Object.Warehouse;
	currency = Object.Currency;
	for each row in Object.Items do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, customer, contract, , warehouse, currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	cache = new Map ();
	for each row in Object.Services do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, , row.Feature, customer, contract, , warehouse, currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	
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

#endregion

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ServicesQuantity" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantity, ItemsTotalQuantityPkg", false );
	
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
		q.SetParameter ( "Quote", Object.Quote );
		q.SetParameter ( "IOSheet", Object.IOSheet );
		q.SetParameter ( "Contract", Object.Contract );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	selection = Env.Selection;
	if ( not Object.Quote.IsEmpty () ) then
		s = "
		|// #Quotes
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.Quote as Documents
		|where Documents.Ref = &Quote
		|";
		selection.Add ( s );
	endif; 
	if ( not Object.IOSheet.IsEmpty () ) then
		s = "
		|// #IOSheets
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.IOSheet as Documents
		|where Documents.Ref = &IOSheet
		|";
		selection.Add ( s );
	endif; 
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #Shipments
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.Shipment as Documents
	|where Documents.SalesOrder = &Ref
	|and not Documents.DeletionMark
	|order by Date
	|;
	|// #Invoices
	|select Documents.Ref as Document, Documents.Number as Number, Documents.Date as Date
	|from Document.Invoice as Documents
	|where Documents.SalesOrder = &Ref
	|and not Documents.DeletionMark
	|union 
	|select Items.Ref, Items.Ref.Number, Items.Ref.Date
	|from Document.Invoice.Items as Items
	|where Items.SalesOrder = &Ref
	|and not Items.Ref.DeletionMark
	|union 
	|select Services.Ref, Services.Ref.Number, Services.Ref.Date
	|from Document.Invoice.Services as Services
	|where Services.SalesOrder = &Ref
	|and not Services.Ref.DeletionMark
	|order by Date
	|;
	|// #Payments
	|select Documents.Ref as Document, Documents.Date as Date,
	|	case when Documents.Reference = """" then Documents.Number else Documents.Reference end as Number
	|from Document.Payment as Documents
	|where Documents.Ref in (
	|	select Documents.Ref as Ref
	|	from Document.Payment as Documents
	|	where Documents.Contract = &Contract
	|	and Documents.Base = &Ref
	|	union
	|	select Documents.Ref as Ref
	|	from Document.Payment.Payments as Documents
	|	where Documents.Contract = &Contract
	|	and &Ref in ( Documents.Detail, Documents.Document )
	|)
	|and not Documents.DeletionMark
	|";
	selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not Object.Quote.IsEmpty () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Quotes, meta.Quote ) );
	endif; 
	if ( not Object.IOSheet.IsEmpty () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.IOSheets, meta.IOSheet ) );
	endif; 
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Shipments, meta.Shipment ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.Invoices, meta.Invoice ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.Payments, meta.Payment ) );
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
Procedure OnOpen ( Cancel )
	
	OrderForm.ActivateItem ( ThisObject );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( EventName = Enum.RefreshItemPictures () ) then
		ItemPictures.Refresh ( ThisObject );
	elsif ( EventName = Enum.MessagePaymentIsSaved ()
		and Parameter.Contract = Object.Contract ) then
		updateLinks ();
		NotifyChanged ( Object.Ref );
	endif; 
	
EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		item = Fields.Item;
		row.Item = item;
		row.Package = Fields.Package;
		row.Feature = Fields.Feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, row.Package, row.Feature, Object.Customer, Object.Contract, , Object.Warehouse, Object.Currency );
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		row.VATCode = data.VAT;
		row.VATRate = data.Rate;
		row.Reservation = PredefinedValue ( "Enum.Reservation.None" );
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	Computations.Amount ( row );
	updateTotals ( ThisObject, row );
	
EndProcedure 

&AtServer
Procedure updateLinks ()
	
	setLinks ();
	updateBalanceDue ();

EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
		addSelectedServices ( SelectedValue );
		updateTotals ( ThisObject );
	elsif ( operation = Enum.ChoiceOperationsReserveItems () ) then
		reserveItem ( SelectedValue );
	endif; 
	
EndProcedure

&AtClient
Procedure addSelectedItems ( Params )
	
	itemsTable = Object.Items;
	for each selectedRow in Params.Items do
		row = itemsTable.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
EndProcedure

&AtClient
Procedure addSelectedServices ( Params )
	
	services = Object.Services;
	for each selectedRow in Params.Services do
		row = services.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
EndProcedure

&AtClient
Procedure reserveItem ( Params )
	
	OrderForm.ReserveItem ( ThisObject, Params );
	updateTotals ( ThisObject );
	
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	setLinks ();
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Forms.DeleteLastRow ( Object.Items, "Item" );
	Forms.DeleteLastRow ( Object.Services, "Item" );
	updateTotals ( ThisObject );
	PaymentsTable.Fix ( Object );
	if ( Editing ) then
		Cancel = true;
		startCommand ( PredefinedValue ( "Enum.Actions.CompleteEdition" ) );
	endif; 
	
EndProcedure

&AtClient
Procedure startCommand ( Command )
	
	if ( Command = PredefinedValue ( "Enum.Actions.SendToApproval" )
		or Command = PredefinedValue ( "Enum.Actions.Return" ) ) then
		Output.SendForApprovalConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	elsif ( Command = PredefinedValue ( "Enum.Actions.Rework" ) ) then
		Output.SendToReworkConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	elsif ( Command = PredefinedValue ( "Enum.Actions.Approve" )
		or Command = PredefinedValue ( "Enum.Actions.CompleteApproval" ) ) then
		Output.ApproveConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	elsif ( Command = PredefinedValue ( "Enum.Actions.Reject" ) ) then
		Output.RejectConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	else
		Output.CompleteRoutePoint ( ThisObject, Command, , "CommandConfirmation" );
	endif; 
	
EndProcedure

&AtClient
Procedure CommandConfirmation ( Answer, Command ) export
	
	if ( Answer <> DialogReturnCode.Yes ) then
		return;
	endif; 
	if ( Command = PredefinedValue ( "Enum.Actions.Approve" )
		or Command = PredefinedValue ( "Enum.Actions.CompleteApproval" ) ) then
		Object.Resolution = PredefinedValue ( "Enum.Resolutions.Approve" );
		performCommand ( Command );
	elsif ( Command = PredefinedValue ( "Enum.Actions.Rework" ) ) then
		Object.Resolution = PredefinedValue ( "Enum.Resolutions.Rework" );
		performCommand ( Command );
	elsif ( Command = PredefinedValue ( "Enum.Actions.Reject" ) ) then
		Object.Resolution = PredefinedValue ( "Enum.Resolutions.Reject" );
		performCommand ( Command );
	elsif ( Command = PredefinedValue ( "Enum.Actions.CompleteEdition" ) ) then
		Editing = false;
		performCommand ( Command, false );
	else
		performCommand ( Command );
	endif;
	
EndProcedure

&AtClient
Procedure performCommand ( Command, CloseForm = true )
	
	Object.Action = Command;
	Object.Performer = CurrentUser;
	if ( Write () ) then
		if ( CloseForm ) then
			Close ();
		endif;
	endif; 
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not OrderForm.CheckAccessibility ( ThisObject ) ) then
		Cancel = true;
		return;
	endif; 
	if ( not OrderForm.SetRowKeys ( CurrentObject ) ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	updateBalanceDue ();	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageSalesOrderIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

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

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	InvoiceForm.SetRate ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure 

&AtClient
Procedure VATUseOnChange ( Item )
	
	applyVATUse ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	applyPrices ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure SendForApproval ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.SendToApproval" ) );
	
EndProcedure

&AtClient
Procedure Approve ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.Approve" ) );
	
EndProcedure

&AtClient
Procedure Rework ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.Rework" ) );
	
EndProcedure

&AtClient
Procedure Reject ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.Reject" ) );
	
EndProcedure

&AtClient
Procedure ReturnToProcess ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.Return" ) );
	
EndProcedure

&AtClient
Procedure CommitRejection ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.CommitRejection" ) );
	
EndProcedure

&AtClient
Procedure CompleteApproval ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.CompleteApproval" ) );
	
EndProcedure

&AtClient
Procedure Modify ( Command )
	
	OrderForm.Modify ( ThisObject );
	
EndProcedure

&AtClient
Procedure CompleteEdition ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.CompleteEdition" ) );
	
EndProcedure

&AtClient
Procedure CompleteShipping ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.CompleteShipment" ) );
	
EndProcedure

&AtClient
Procedure CompleteInvoicing ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.CompleteInvoicing" ) );
	
EndProcedure

&AtClient
Procedure ResolutionMemoChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	StandardProcessing = false;
	if ( SelectedValue = "0" ) then
		addMemo ();
	elsif ( SelectedValue = "1" ) then
		showMemos ();
	endif; 
	
EndProcedure

&AtClient
Procedure addMemo ()
	
	p = new Structure ( "FillingValues", new Structure () );
	p.FillingValues.Insert ( "Document", Object.Ref );
	OpenForm ( "InformationRegister.SalesOrderResolutions.Form.NewMemo", p, ThisObject, , , , new NotifyDescription ( "ResolutionMemosNewMemo", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure ResolutionMemoClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure ResolutionMemosNewMemo ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	ResolutionMemo = Result;
	
EndProcedure 

&AtClient
Procedure showMemos ()
	
	p = new Structure ( "Filter", new Structure () );
	p.Filter.Insert ( "Document", Object.Ref );
	OpenForm ( "InformationRegister.SalesOrderResolutions.Form.List", p );
	
EndProcedure 

&AtClient
Procedure ShowPerformers ( Command )
	
	OrderForm.OpenPerformers ( ThisObject );
	
EndProcedure

&AtClient
Procedure Chart ( Command )
	
	BPForm.ShowChart ( Object.Ref, Object.Process, ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure SelectItems ( Command )
	
	PickItems.Open ( ThisObject, pickParams () );
	
EndProcedure

&AtServer
Function pickParams ()
	
	return PickItems.GetParams ( ThisObject );
	
EndFunction 

&AtClient
Procedure Reserve ( Command )
	
	if ( ItemsRow = undefined ) then
		return;
	endif; 
	openReservation ();
	
EndProcedure

&AtClient
Procedure openReservation ()
	
	p = reservationParams ( Object.Items.IndexOf ( ItemsRow ) );
	OpenForm ( "DataProcessor.Items.Form.OrderItem", p, ThisObject );
	
EndProcedure 

&AtServer
Function reservationParams ( val RowIndex )
	
	return OrderForm.ReservationParams ( ThisObject, RowIndex );
	
EndFunction

&AtClient
Procedure Scan ( Command )
	
	OpenForm ( "CommonForm.Scan", , ThisObject );
	
EndProcedure

&AtClient
Procedure ShowHidePictures ( Command )
	
	togglePictures ();
	
EndProcedure

&AtServer
Procedure togglePictures ()
	
	ItemPictures.Toggle ( ThisObject );
	
EndProcedure 

&AtClient
Procedure ResizeOnChange ( Item )
	
	ItemPictures.Refresh ( ThisObject );
	
EndProcedure

&AtClient
Procedure PictureOnClick ( Item, EventData, StandardProcessing )
	
	StandardProcessing = false;
	ItemPictures.ClickProcessing ( EventData.Element.id, UUID );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	ShownProduct = ? ( ItemsRow = undefined, undefined, ItemsRow.Item );
	ItemPictures.Refresh ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	OrderRows.ResetReservation ( ItemsRow, PredefinedValue ( "Enum.Reservation.None" ) );
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Organization", Object.Customer );
	p.Insert ( "Contract", Object.Contract );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	ItemsRow.VATCode = data.VAT;
	ItemsRow.VATRate = data.Rate;
	Computations.Units ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package, , Params.Organization, Params.Contract, , Params.Warehouse, Params.Currency );
	data.Insert ( "Price", price );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure ItemsFeatureOnChange ( Item )
	
	priceItem ();
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	ItemsRow.Price = Goods.Price ( , Object.Date, prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature, Object.Customer, Object.Contract, , Object.Warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Organization", Object.Customer );
	p.Insert ( "Contract", Object.Contract );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Feature", ItemsRow.Feature );
	p.Insert ( "Package", ItemsRow.Package );
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	p.Insert ( "Prices", prices );
	data = getPackageData ( p );
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	Computations.Units ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , Params.Date, Params.Prices, Params.Item, package, Params.Feature, Params.Organization, Params.Contract, , Params.Warehouse, Params.Currency );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )

	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );

EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	Computations.Discount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsVATCodeOnChange ( Item )
	
	ItemsRow.VATRate = DF.Pick ( ItemsRow.VATCode, "Rate" );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsVATOnChange ( Item )
	
	updateTotals ( ThisObject, ItemsRow, false );
	
EndProcedure

&AtClient
Procedure ItemsPricesOnChange ( Item )
	
	priceItem ();
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsDiscountRateOnChange ( Item )
	
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsDiscountOnChange ( Item )
	
	Computations.DiscountRate ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsReservationOnChange ( Item )
	
	OrderRows.ResetStock ( ItemsRow );
	OrderRows.ResetOrder ( ItemsRow );
	
EndProcedure

// *****************************************
// *********** Table Services

&AtClient
Procedure ServicesOnActivateRow ( Item )
	
	ServicesRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ServicesOnEditEnd ( Item, NewRow, CancelEdit )
	
	updateTotals ( ThisObject );
	OrderRows.ResetPerformer ( ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesAfterDeleteRow ( Item )
	
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ServicesItemOnChange ( Item )
	
	applyService ();
	
EndProcedure

&AtClient
Procedure applyService ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Organization", Object.Customer );
	p.Insert ( "Contract", Object.Contract );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ServicesRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getServiceData ( p );
	ServicesRow.Price = data.Price;
	ServicesRow.Description = data.FullDescription;
	ServicesRow.VATCode = data.VAT;
	ServicesRow.VATRate = data.Rate;
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure 

&AtServerNoContext
Function getServiceData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "FullDescription, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , Params.Organization, Params.Contract, , Params.Warehouse, Params.Currency );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure ServicesFeatureOnChange ( Item )
	
	priceService ();
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure priceService ()
	
	prices = ? ( ServicesRow.Prices.IsEmpty (), Object.Prices, ServicesRow.Prices );
	ServicesRow.Price = Goods.Price ( , Object.Date, prices, ServicesRow.Item, , ServicesRow.Feature, Object.Customer, Object.Contract, , Object.Warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ServicesQuantityOnChange ( Item )
	
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange ( Item )

	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );

EndProcedure

&AtClient
Procedure ServicesAmountOnChange ( Item )
	
	Computations.Price ( ServicesRow );
	Computations.Discount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesPricesOnChange ( Item )
	
	priceService ();
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesVATCodeOnChange ( Item )
	
	ServicesRow.VATRate = DF.Pick ( ServicesRow.VATCode, "Rate" );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesVATOnChange ( Item )
	
	updateTotals ( ThisObject, ServicesRow, false );
	
EndProcedure

&AtClient
Procedure ServicesDiscountRateOnChange ( Item )
	
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesDiscountOnChange ( Item )
	
	Computations.DiscountRate ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesPerformerOnChange ( Item )
	
	OrderRows.ResetDepartment ( ServicesRow );
	
EndProcedure

// *****************************************
// *********** Table Payments

&AtClient
Procedure CalcPayments ( Command )
	
	PaymentsTable.Calc ( Object );
	
EndProcedure
