
&AtClient
Procedure CommandProcessing ( Invoices, ExecuteParameters )
	
	Output.MarkInvoiceAsReturned ( ThisObject, Invoices );

EndProcedure

&AtClient
Procedure MarkInvoiceAsReturned ( Answer, Invoices ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		result = mark ( Invoices );
		notifySystem ( result.Changes );
		notifySystem ( result.Sources );
	endif;

EndProcedure

&AtServer
Function mark ( val Invoices )
	
	changes = new Array ();
	sources = new Array ();
	BeginTransaction ();
	data = fetchData ( Invoices );
	for each row in data do
		status = row.Status;
		sourceRef = row.SourceRef;
		ref = row.Ref;
		if ( row.Online
			or status = Enums.FormStatuses.Returned ) then
			continue;
		elsif ( status = Enums.FormStatuses.Printed
			or status = Enums.FormStatuses.Submitted ) then
			obj = ref.GetObject ();
			obj.Status = Enums.FormStatuses.Returned;
			obj.Write ();
			changes.Add ( ref );
			if ( sourceRef <> ref ) then
				sources.Add ( sourceRef );
			endif;
		elsif ( status = null ) then
			Output.CantMarkTaxInvoice ( new Structure ( "Invoice", sourceRef ), , sourceRef );
		else
			Output.CantMarkTaxInvoice ( new Structure ( "Invoice", ref ), "Status", ref );
		endif;
	enddo;
	CommitTransaction ();
	return new Structure ( "Changes, Sources", changes, sources );

EndFunction

&AtServer
Function fetchData ( Invoices )
	
	type = TypeOf ( Invoices [ 0 ] );
	if ( type = Type ( "DocumentRef.InvoiceRecord" ) ) then
		s = "
		|select Documents.Base as SourceRef, Documents.Ref as Ref, Documents.Status as Status,
		|	isnull ( Documents.Range.Online, false ) as Online
		|from Document.InvoiceRecord as Documents
		|where Documents.Ref in ( &List )
		|";
	else
		name = Metadata.FindByType ( type ).Name;
		s = "select Source.Ref as SourceRef, Documents.Ref as Ref, Documents.Status as Status,
		|	isnull ( Documents.Range.Online, false ) as Online
		|from Document." + name + " as Source
		|	//
		|	// Invoice Records
		|	//
		|	left join Document.InvoiceRecord as Documents
		|	on Documents.Base = Source.Ref
		|	and not Documents.DeletionMark
		|where Source.Ref in ( &List )
		|";
	endif;
	q = new Query ( s );
	q.SetParameter ( "List", Invoices );
	return q.Execute ().Unload ();

EndFunction

&AtClient
Procedure notifySystem ( Invoices )
	
	changed = Invoices.Count ();
	if ( changed = 0 ) then
		return;
	elsif ( changed = 1 ) then
		NotifyChanged ( Invoices [ 0 ] );
	else
		NotifyChanged ( TypeOf ( Invoices [ 0 ] ) );
	endif;

EndProcedure
