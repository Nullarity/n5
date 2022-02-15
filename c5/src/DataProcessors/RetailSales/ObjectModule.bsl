#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Data;
var BillsQuery;
var EndDay;
var DocumentsMemo;
var SetDocumentMemo;
var Document;
var Changes;
var ErrorFilling;
var ErrorPosting;
var ErrorUnposting;
var ErrorSaving;

Procedure Exec () export
	
	init ();
	prepareWarehouses ();
	SetPrivilegedMode ( true );
	getData ();
	create ();
	transferChanges ();
	
EndProcedure

Procedure init ()
	
	EndDay = EndOfDay ( Parameters.Day );
	Changes = new Array ();
	DocumentsMemo = Parameters.Memo;
	SetDocumentMemo = not IsBlankString ( DocumentsMemo );
	initBillsQuery ();

EndProcedure

Procedure initBillsQuery ()
	
	s = "
	|select Sales.Ref as Ref
	|from Document.Sale as Sales
	|	//
	|	// Only having records
	|	//
	|	join AccumulationRegister.Items as Register
	|	on Register.Recorder = Sales.Ref
	|where Sales.Date between &DateStart and &DateEnd
	|and Sales.Warehouse = &Warehouse
	|and Sales.Location = &Location
	|and Sales.Method  = &Method
	|";
	BillsQuery = new Query ( s );
	BillsQuery.SetParameter ( "DateStart", Parameters.Day );
	BillsQuery.SetParameter ( "DateEnd", EndDay );
	
EndProcedure

Procedure getData ()
	
	filterCash = new Array ( 1 );
	filterSales = new Array ( 1 );
	filterItems = new Array ( 1 );
	if ( not Parameters.Location.IsEmpty () ) then
		filterCash.Add ( "CashReceipts.Location = &Location" );
		filterSales.Add ( "Sales.Location = &Location" );
		filterItems.Add ( "Items.Ref.Location = &Location" );
	endif;
	if ( not Parameters.Method.IsEmpty () ) then
		filterSales.Add ( "Sales.Method = &Method" );
		filterItems.Add ( "Items.Ref.Method = &Method" );
	endif;
	cashFilter = StrConcat ( filterCash, " and " );
	salesFilter = StrConcat ( filterSales, " and " );
	itemsFilter = StrConcat ( filterItems, " and " );
	s = "
	|// Issued Cash Receipts
	|select CashReceipts.Base as Ref
	|into CashReceipts
	|from Document.CashReceipt as CashReceipts
	|where CashReceipts.Posted
	|and valuetype ( CashReceipts.Base ) in (
	|	type ( Document.Payment ),
	|	type ( Document.Refund )
	|)
	|and CashReceipts.Date between &DateStart and &DateEnd
	|and CashReceipts.Company = &Company" + cashFilter + "
	|;
	|// Paid invoices by cash
	|select Payments.Document as Ref
	|into Invoices
	|from Document.Payment.Payments as Payments
	|where Payments.Ref in ( select Ref from CashReceipts )
	|and Payments.Document refs Document.Invoice
	|union
	|select Payments.Detail
	|from Document.Payment.Payments as Payments
	|where Payments.Ref in ( select Ref from CashReceipts )
	|and Payments.Detail refs Document.Invoice
	|union
	|select Payments.Document
	|from Document.Refund.Payments as Payments
	|where Payments.Ref in ( select Ref from CashReceipts )
	|and valuetype ( Payments.Document ) in (
	|	type ( Document.Invoice ),
	|	type ( Document.Return )
	|)
	|union
	|select Payments.Detail
	|from Document.Refund.Payments as Payments
	|where Payments.Ref in ( select Ref from CashReceipts )
	|and Payments.Detail refs Document.Return
	|index by Ref
	|;
	|// #Sales
	|select Sales.Warehouse.Owner as Company, Sales.Warehouse as Warehouse,
	|	Sales.Method as Method, Sales.VATUse as VATUse, Sales.Amount as Amount,
	|	Sales.Discount as Discount, Sales.GrossAmount as GrossAmount, Sales.VAT as VAT,
	|	Sales.Location as Location, Sales.Location.CashFlow as CashFlow,
	|	case Sales.Method
	|		when value ( Enum.PaymentMethods.Card ) then Sales.Location.TransitAccount
	|		else Sales.Location.Account
	|	end as Account, Documents.Ref as Document
	|from (
	|	select Sales.Warehouse as Warehouse, Sales.Location as Location,
	|		Sales.Method as Method, Sales.VATUse as VATUse, sum ( Sales.Amount ) as Amount,
	|		sum ( Sales.Discount ) as Discount, sum ( Sales.GrossAmount ) as GrossAmount, sum ( Sales.VAT ) as VAT
	|	from Document.Sale as Sales
	|	where Sales.Posted
	|	and Sales.Base not in ( select Ref from Invoices )
	|	and Sales.Date between &DateStart and &DateEnd
	|	and Sales.Warehouse in ( select Ref from Warehouses )
	|	and Sales.Company = &Company" + salesFilter + "
	|	group by Sales.Warehouse, Sales.Location, Sales.Method, Sales.VATUse
	|	) as Sales
	|	//
	|	// Documents
	|	//
	|	left join Document.RetailSales as Documents
	|	on not Documents.DeletionMark
	|	and Documents.Date between &DateStart and &DateEnd
	|	and Documents.Warehouse = Sales.Warehouse
	|	and Documents.Location = Sales.Location
	|	and Documents.Method = Sales.Method
	|;
	|// #Items
	|select Items.Ref.Base as Base, Items.Ref.Warehouse as Warehouse, Items.Ref.Location as Location,
	|	Items.Ref.Method as Method, Items.Ref.VATUse as VATUse, Items.Item as Item, Items.Feature as Feature,
	|	Items.Series as Series, Items.Package as Package, Items.Capacity as Capacity, Items.VATCode as VATCode,
	|	Items.VATRate as VATRate, Items.Price as Price, sum ( Items.Total ) as Total,
	|	sum ( Items.Amount ) as Amount, sum ( Items.VAT ) as VAT,
	|	sum ( Items.Quantity ) as Quantity, sum ( Items.QuantityPkg ) as QuantityPkg
	|from Document.Sale.Items as Items
	|where Items.Ref.Posted
	|and Items.Ref.Base not in ( select Ref from Invoices )
	|and Items.Ref.Date between &DateStart and &DateEnd
	|and Items.Ref.Warehouse in ( select Ref from Warehouses )
	|and Items.Ref.Company = &Company" + itemsFilter + "
	|group by Items.Ref.Base, Items.Ref.Warehouse, Items.Ref.Location, Items.Ref.Method, Items.Ref.VATUse,
	|	Items.Item, Items.Feature, Items.Series, Items.Package, Items.Price, Items.Capacity,
	|	Items.VATCode, Items.VATRate
	|";
	Data.Selection.Add ( s );
	q = Data.Q;
	day = Parameters.Day;
	q.SetParameter ( "DateStart", Parameters.Day );
	q.SetParameter ( "DateEnd", EndDay );
	q.SetParameter ( "Location", Parameters.Location );
	q.SetParameter ( "Method", Parameters.Method );
	SQL.Perform ( Data );

EndProcedure

Procedure prepareWarehouses ()

 	s = "
	|select allowed Warehouses.Ref as Ref
	|into Warehouses
	|from Catalog.Warehouses as Warehouses
	|where not Warehouses.DeletionMark
	|and Warehouses.Owner = &Company";
	if ( not Parameters.Warehouse.IsEmpty () ) then
		s = s + "
		|and Warehouses.Ref = &Warehouse";
	endif;
	Data = SQL.Create ( s );
	q = Data.Q;
	q.SetParameter ( "Company", Parameters.Company );
	q.SetParameter ( "Warehouse", Parameters.Warehouse );
	SQL.Perform ( Data );

EndProcedure

Procedure create ()
	
	for each row in Data.Sales do
		createDocument ( row );
		fillDocument ();
		postDocument ();
		postMessages ();
		pushChanges ();
	enddo;

EndProcedure

Procedure createDocument ( Row )
	
	ref = row.Document;
	if ( ref = null ) then
		Document = Documents.RetailSales.CreateDocument ();
	else
		Document = ref.GetObject ();
		Document.Items.Clear ();
	endif;
	if ( SetDocumentMemo ) then
		Document.Memo = DocumentsMemo;
	endif;
	Document.Creator = SessionParameters.User;
	Document.Company = Row.Company;
	Document.Warehouse = Row.Warehouse;
	Document.Location = Row.Location;
	Document.Method = Row.Method;
	if ( Document.CashFlow.IsEmpty () ) then
		Document.CashFlow = Row.CashFlow;
	endif;
	if ( Document.Account.IsEmpty () ) then
		Document.Account = Row.Account;
	endif;
	Document.Date = EndDay;
	Document.Department = Parameters.Department;
	Document.VATUse = Row.VATUse;
	Document.VAT = Row.VAT;
	Document.Amount = Row.Amount;
	Document.Discount = Row.Discount;
	Document.GrossAmount = Row.GrossAmount;

EndProcedure

Procedure fillDocument ()
	
	company = Document.Company;
	warehouse = Document.Warehouse;
	table = Document.Items;
	search = new Structure ( "Warehouse, Location, Method", Document.Warehouse, Document.Location, Document.Method );
	rows = Data.Items.FindRows ( search );
	for each row in rows do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row );
		accounts = AccountsMap.Item ( newRow.Item, company, warehouse, "Account, SalesCost, Income, VAT" );
		newRow.Account = accounts.Account;
		newRow.SalesCost = accounts.SalesCost;
		newRow.Income = accounts.Income;
		newRow.VATAccount = accounts.VAT;
	enddo;

EndProcedure

Procedure postDocument ()

	ErrorFilling = undefined;
	ErrorPosting = undefined;
	ErrorUnposting = undefined;
	ErrorSaving = undefined;
	isNew = Document.IsNew ();
	empty = Document.Items.Count () = 0;
	if ( isNew and empty ) then
		return;
	endif;
	if ( empty ) then
		unpostOrSave ();
	else
		if ( isNew ) then
			if ( not save () ) then
				return;
			endif;
		endif;
		if ( check ()
			and post () ) then
			return;
		else
			unpostOrSave ();
		endif;
	endif;

EndProcedure

Procedure unpostOrSave ()
	
	if ( Document.Posted ) then
		try
			Document.Write ( DocumentWriteMode.UndoPosting );
		except
			ErrorUnposting = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		endtry;
	else
		save ();
	endif;
	
EndProcedure

Function save ()
	
	try
		Document.Write ();
	except
		ErrorSaving = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		return false;
	endtry;
	return true;

EndFunction

Function check ()

	if ( Document.CheckFilling () ) then
		return true;
	endif;
	job = Jobs.GetBackground ( JobKey );
	if ( job <> undefined ) then
		ErrorFilling = job.GetUserMessages ( true );
	endif;
	return false;

EndFunction

Function post ()
	
	BeginTransaction ();
	result = true;
	try
		unpostBills ();
		Document.Write ( DocumentWriteMode.Posting );
	except
		ErrorPosting = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		result = false;
	endtry;
	if ( result ) then
		CommitTransaction ();
	else
		RollbackTransaction ();
	endif;
	return result;

EndFunction

Procedure unpostBills ()
	
	BillsQuery.SetParameter ( "Warehouse", Document.Warehouse );
	BillsQuery.SetParameter ( "Location", Document.Location );
	BillsQuery.SetParameter ( "Method", Document.Method );
	table = BillsQuery.Execute ().Unload ();
	r = AccumulationRegisters.Items.CreateRecordSet ();
	for each row in table do
		r.Filter.Recorder.Set ( row.Ref );
		r.Write ();
	enddo;
	
EndProcedure

Procedure postMessages ()
	
	ref = Document.Ref;
	msg = new Structure ( "Document, Error", ref );
	if ( ErrorSaving <> undefined ) then
		msg.Error = ErrorSaving;
		if ( Document.IsNew () ) then
			msg.Document = documentPresentation ();
		endif;
		Output.PutMessage ( Output.ErrorSavingRetailSales ( msg ), , , ref );
	else
		if ( ErrorFilling <> undefined ) then
			for each error in ErrorFilling do
				msg.Error = error.Text;
				error.Text = Output.ErrorCheckingRetailSales ( msg );
				error.Message ();
			enddo;
		else
			if ( ErrorPosting <> undefined ) then
				msg.Error = ErrorPosting;
				Output.PutMessage ( Output.ErrorPostingRetailSales ( msg ), , , ref );
			endif;
			if ( ErrorUnposting <> undefined ) then
				msg.Error = ErrorUnposting;
				Output.PutMessage ( Output.ErrorUnpostingRetailSales ( msg ), , , ref );
			endif;
		endif;
	endif;

EndProcedure

Function documentPresentation ()
	
	parts = new Array ();
	meta = Metadata.Documents.RetailSales;
	parts.Add ( meta.Presentation () );
	attributes = meta.Attributes;
	parts.Add ( attributes.Warehouse.Presentation () + ": " + Document.Warehouse );
	parts.Add ( attributes.Location.Presentation () + ": " + Document.Location );
	parts.Add ( attributes.Method.Presentation () + ": " + Document.Method );
	return StrConcat ( parts, ", " );

EndFunction

Procedure pushChanges ()
	
	if ( not Document.IsNew () ) then
		Changes.Add ( Document.Ref );
	endif;

EndProcedure

Procedure transferChanges ()
	
	if ( Changes.Count () = 0 ) then
		Output.RetailSalesNotFound ();
	else
		PutToTempStorage ( Changes, Parameters.Address );
	endif;

EndProcedure

#endif
