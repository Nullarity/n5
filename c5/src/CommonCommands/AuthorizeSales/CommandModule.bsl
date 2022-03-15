
&AtClient
Procedure CommandProcessing ( Command, ExecuteParameters )

	params = ExecuteParameters.Parameters;
	form = Forms.FindByID ( params.Form );
	if ( not DocumentForm.SaveNew ( form ) ) then
		return;
	endif;
	makeRequest ( form.Object.Ref, params.Reason );
	Notify ( Enum.MessageSalesPermissionIsSaved (), form.Object.Ref );

EndProcedure

&AtServer
Procedure makeRequest ( val Document, val Reason )

	fields = DF.Values ( Document, "Customer, Company" );
	customer = fields.Customer;
	ref = findPermission ( Document );
	if ( ref = undefined ) then
		doc = Documents.SalesPermission.CreateDocument ();
	else
		doc = ref.GetObject ();
		if ( customer = doc.Customer  ) then
			doc.DeletionMark = false;
			doc.Responsible = undefined;
			doc.Resolution = undefined;
			doc.Expired = undefined;
		else
			doc.SetDeletionMark ( true );
			doc = Documents.SalesPermission.CreateDocument ();
		endif;
	endif;
	doc.Date = CurrentSessionDate ();
	doc.Document = Document;
	doc.Customer = customer;
	doc.Company = fields.Company;
	doc.Creator = SessionParameters.User;
	table = doc.Restrictions;
	if ( table.Find ( Reason, "Reason" ) = undefined ) then
		row = table.Add ();
		row.Reason = Reason;
	endif;
	doc.Write ();
	send ( doc.Ref, Reason );

EndProcedure

&AtServer
Function findPermission ( Document )
	
	s = "
	|select top 1 Documents.Ref as Ref
	|from Document.SalesPermission as Documents
	|where Documents.Document = &Document
	|";
	q = new Query ( s );
	q.SetParameter ( "Document", Document );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );

EndFunction

&AtServer
Procedure send ( Document, Reason )
	
	params = new Array ();
	params.Add ( Document );
	params.Add ( Reason );
	Jobs.Run ( "SalesPermissionMailing.Send", params, , , TesterCache.Testing () );
	
EndProcedure
