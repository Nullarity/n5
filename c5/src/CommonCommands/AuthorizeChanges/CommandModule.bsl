
&AtClient
async Procedure CommandProcessing ( Command, ExecuteParameters )

	params = ExecuteParameters.Parameters;
	form = Forms.FindByID ( params.Form );
	object = form.Object;
	ref = object.Ref;
	variant = await askPeriod ( form );
	if ( variant = undefined ) then
		return;
	elsif ( variant = 0 ) then
		if ( not DocumentForm.SaveNew ( form ) ) then
			return;
		endif;
		document = ref;
		scope = document;
	else
		document = undefined;
		scope = object.Date;
	endif;
	makeRequest ( document, object.Date, TypeOf ( ref ) );
	Notify ( Enum.MessageChangesPermissionIsSaved (), scope );

EndProcedure

&Atclient
async Function askPeriod ( Form )
	
	menu = new ValueList ();
	menu.Add ( 0, "This Document" );
	menu.Add ( 1, "For the day" );
	item = await menu.ChooseItemAsync ( "how", Form.CurrentItem );
	return ? ( item = undefined, undefined, item.Value );
	
EndFunction

&AtServer
Procedure makeRequest ( val Document, val Day, val Class )

	if ( Document = undefined ) then
		company = Logins.Settings ( "Company" ).Company;
		organization = undefined;
	else
		list = new Array ();
		list.Add ( "Company" );
		meta = Metadata.FindByType ( TypeOf ( Document ) ).Attributes;
		if ( meta.Find ( "Customer" ) <> undefined ) then
			list.Add ( "Customer as Organization" );
		elsif ( meta.Find ( "Vendor" ) ) then
			list.Add ( "Vendor as Organization" );
		endif;
		fields = DF.Values ( Document, StrConcat ( list, "," ) );
		company = fields.Company;
		organization = fields.Organization;
	endif;
	ref = findPermission ( Document, Day, company );
	if ( ref = undefined ) then
		doc = Documents.ChangesPermission.CreateDocument ();
	else
		doc = ref.GetObject ();
		if ( Day = doc.Day ) then
			doc.DeletionMark = false;
			doc.Responsible = undefined;
			doc.Resolution = undefined;
			doc.Expired = undefined;
			doc.Class = undefined;
		else
			doc.SetDeletionMark ( true );
			doc = Documents.ChangesPermission.CreateDocument ();
		endif;
	endif;
	doc.Date = CurrentSessionDate ();
	doc.Document = Document;
	doc.Class = MetadataRef.Get ( Metadata.FindByType ( Class ).FullName () );
	doc.Day = Day;
	doc.Organization = organization;
	doc.Company = company;
	doc.Creator = SessionParameters.User;
	doc.Write ();
	send ( doc.Ref );

EndProcedure

&AtServer
Function findPermission ( Document, Day, Company )
	
	s = "
	|select top 1 Documents.Ref as Ref
	|from Document.ChangesPermission as Documents
	|where Documents.Document = &Document
	|and Documents.Day = &Day
	|and Documents.Company = &Company
	|";
	q = new Query ( s );
	q.SetParameter ( "Document", Document );
	q.SetParameter ( "Day", Day );
	q.SetParameter ( "Company", Company );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );

EndFunction

&AtServer
Procedure send ( Document )
	
	params = new Array ();
	params.Add ( Document );
	Jobs.Run ( "ChangesPermissionMailing.Send", params, , , TesterCache.Testing () );
	
EndProcedure
