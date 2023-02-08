&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	init ();
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure init ()
	
	DataLoaded = false;
	Object.Company = Logins.Settings ( "Company" ).Company;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|InvoicesWaiting show Object.IncludeWaiting;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	loadInvoices ();
	DataLoaded = true;
	
EndProcedure

&AtServer
Procedure loadInvoices ()
	
	company = Object.Company;
	if ( company.IsEmpty () ) then
		Object.Invoices.Clear ();
		return;
	endif;
	s = "
	|select allowed Invoices.Ref as Invoice, Invoices.Amount as Amount,
	|	Invoices.Customer.Description as Customer,
	|	Invoices.LoadingPoint.Description as LoadingPoint,
	|	Invoices.Status = value ( Enum.FormStatuses.Saved ) as Unload,
	|	Invoices.Status = value ( Enum.FormStatuses.Waiting ) as Waiting
	|from Document.InvoiceRecord as Invoices
	|where not Invoices.DeletionMark
	|and Invoices.Date between &DateStart and &DateEnd
	|and Invoices.Company = &Company
	|and Invoices.Range.Online
	|and Invoices.Status in ( &Statuses )
	|and ( Invoices.Base = undefined
	|	or not Invoices.Base refs Document.Invoice
	|	or cast ( Invoices.Base as Document.Invoice ).Posted )";
	warehouse = Object.Warehouse;
	if ( not warehouse.IsEmpty () ) then
		s = s + "
		|and Invoices.LoadingPoint = &Warehouse
		|";
	endif;
	s = s + "
	|order by Invoices.Date
	|";
	q = new Query ( s );
	q.SetParameter ( "Company", company );
	q.SetParameter ( "Warehouse", warehouse );
	start = BegOfDay ( CurrentSessionDate () );
	q.SetParameter ( "DateStart", start );
	q.SetParameter ( "DateEnd", EndOfDay ( start ) );
	statuses = new Array ();
	statuses.Add ( Enums.FormStatuses.Saved );
	if ( Object.IncludeWaiting ) then
		statuses.Add ( Enums.FormStatuses.Waiting );
	endif;
	q.SetParameter ( "Statuses", statuses );
	Object.Invoices.Load ( q.Execute ().Unload () );
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( not DataLoaded ) then
		loadInvoices ();
	endif;
	LocalFiles.Prepare ();
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	loadInvoices ();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange ( Item )
	
	loadInvoices ();
	
EndProcedure

&AtClient
Procedure IncludeWaitingOnChange ( Item )
	
	applyIncludeWaiting ();
	
EndProcedure

&AtServer
Procedure applyIncludeWaiting ()
	
	loadInvoices ();
	Appearance.Apply ( ThisObject, "Object.IncludeWaiting" );
	
EndProcedure

&AtClient
Procedure PathStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	dialog = new FileDialog ( FileDialogMode.Save );
	dialog.Multiselect = false;
	dialog.Filter = "XML (*.xml)|*.xml";
	dialog.FullFileName	= "efactura.xml";
	dialog.Show ( new NotifyDescription ( "SelectFile", ThisObject ) );
	
EndProcedure

&AtClient
Procedure SelectFile ( Files, Params ) export
	
	if ( Files = undefined ) then
		return;
	endif; 
	Object.Path = Files [ 0 ];
	
EndProcedure 

&AtClient
Procedure Unload ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	if ( run () ) then
		Progress.Open ( UUID, ThisObject, new NotifyDescription ( "Unloading", ThisObject ), true );
	endif;
	
EndProcedure

&AtServer
Function run () 

	list = getSelection ();
	if ( list = undefined ) then
		return false;
	endif;
	if ( not checkData ( list ) ) then
		raise Output.DataInputErrorsFound ();
	endif;
	p = DataProcessors.UnloadInvoices.GetParams ();
	p.Invoices = list;
	Address = PutToTempStorage ( undefined, UUID );
	p.Address = Address;
	args = new Array ();
	args.Add ( "UnloadInvoices" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, UUID, , TesterCache.Testing () );
	return true;

EndFunction

&AtServer
Function getSelection () 

	rows = Object.Invoices.Unload ( new Structure ( "Unload", true ) );
	if ( rows.Count () = 0 ) then
		Output.EmptyUploadList ( , "Invoices" );
		return undefined;
	else
		return rows.UnloadColumn ( "Invoice" );
	endif;
	
EndFunction

&AtServer
Function checkData ( Invoices )
	
	ok = true;
	code = DF.Pick ( Object.Company, "CodeFiscal" );
	if ( code = "" ) then
		Output.UndefinedCodeFiscal1 ( , "Company" );
		ok = false;
	endif;
	errors = wrongInvoices ( Invoices );
	if ( errors.Count () > 0 ) then
		ok = false;
		table = Object.Invoices;
		for each invoice in Invoices do
			error = errors.Find ( invoice, "Invoice" );
			if ( error = undefined ) then
				continue;
			endif;
			row = table.FindRows ( new Structure ( "Invoice", invoice ) ) [ 0 ];
			msg = new Structure ( "Row", Format ( row.LineNumber, "NG=" ) );
			if ( error.CustomerCodeFiscal ) then
				Output.UndefinedCodeFiscal2 ( msg, "Customer", invoice );
			endif;
			if ( error.CustomerBankAccount ) then
				Output.UndefinedAccountNumber ( msg, "CustomerAccount", invoice );
			endif;
			if ( error.CompanyBankAccount ) then
				Output.UndefinedAccountNumber ( msg, "Account", invoice );
			endif;
		enddo;
	endif;
	return ok;
	
EndFunction

&AtServer
Function wrongInvoices ( Invoices )

	s = "
	|select Documents.Ref as Invoice,
	|	isnull ( Documents.Account.AccountNumber, """" ) = """" as CompanyBankAccount,
	|	isnull ( Documents.CustomerAccount.AccountNumber, """" ) = """" as CustomerBankAccount,
	|	Documents.Customer.CodeFiscal = """" as CustomerCodeFiscal
	|from Document.InvoiceRecord as Documents
	|where Documents.Ref in ( &Invoices )
	|and ( isnull ( Documents.Account.AccountNumber, """" ) = """"
	|	or isnull ( Documents.CustomerAccount.AccountNumber, """" ) = """"
	|	or Documents.Customer.CodeFiscal = """" )
	|";
	q = new Query ( s );
	q.SetParameter ( "Invoices", Invoices );
	return q.Execute ().Unload ();

EndFunction

&AtClient
Procedure Unloading ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif;
	Notify ( Enum.MessageInvoicesExchnage () );
	links = new Array ();
	links.Add ( new TransferableFileDescription ( Object.Path, Address ) );
	BeginGettingFiles ( new NotifyDescription ( "FileWritten", ThisObject ), links, , false );

EndProcedure

&AtClient
Procedure FileWritten ( Files, Params ) export 

	if ( Files = undefined ) then
		return;
	endif; 
	callback = new NotifyDescription ( "SuccessClosed", ThisObject );
	OpenForm ( "DataProcessor.UnloadInvoices.Form.Success", , ThisObject, , , , callback );

EndProcedure

&AtClient
Procedure SuccessClosed ( Result, Params ) export
	
	if ( Result = undefined
		or Result = true ) then
		BeginDeletingFiles ( , Object.Path );
	endif;
	
EndProcedure

// *****************************************
// *********** Table Invoices

&AtClient
Procedure Update ( Command )
	
	loadInvoices ();
	
EndProcedure

&AtClient
Procedure MarkAll ( Command )
	
	mark ( true );
	
EndProcedure

&AtClient
Procedure mark ( Flag ) 

	for each row in Object.Invoices do
		row.Unload = Flag;
	enddo;

EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	mark ( false );
		
EndProcedure

&AtClient
Procedure InvoicesOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure InvoicesSelection ( Item, RowSelected, Field, StandardProcessing )

	StandardProcessing = false;
	ShowValue ( , TableRow.Invoice );

EndProcedure
