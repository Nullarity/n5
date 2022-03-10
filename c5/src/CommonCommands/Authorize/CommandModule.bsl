
&AtClient
Procedure CommandProcessing ( Command, ExecuteParameters )

	params = ExecuteParameters.Parameters;
	form = findForm ( params.Form );
	if ( not saveSource ( form ) ) then
		return;
	endif;
	makeRequest ( form.Object.Ref, params.Reason );
	Notify ( Enum.MessagePermissionIsSaved (), form.Object.Ref );

EndProcedure

&AtClient
Function findForm ( Source )

	windows = GetWindows ();
	clientForm = Type ( "ClientApplicationForm" );
	for each window in windows do
		for each form in window.Content do
			if ( TypeOf ( form ) = clientForm
				and form.UUID = Source ) then
				return form;
			endif;
		enddo;
	enddo; 

EndFunction

&AtClient
Function saveSource ( Form )
	
	if ( form.Object.Ref.IsEmpty () ) then
		return form.Write ( new Structure ( Enum.WriteParametersJustSave (), true ) );
	else
		return true;
	endif;

EndFunction

&AtServer
Procedure makeRequest ( val Document, val Reason )

	fields = DF.Values ( Document, "Customer, Company" );
	customer = fields.Customer;
	ref = findPermission ( Document );
	if ( ref = undefined ) then
		doc = Documents.Permission.CreateDocument ();
	else
		doc = ref.GetObject ();
		if ( customer = doc.Customer  ) then
			doc.DeletionMark = false;
			doc.Responsible = undefined;
			doc.Resolution = undefined;
			doc.Expired = undefined;
		else
			doc.SetDeletionMark ( true );
			doc = Documents.Permission.CreateDocument ();
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
	send ( Document, Reason );

EndProcedure

&AtServer
Function findPermission ( Document )
	
	s = "
	|select top 1 Documents.Ref as Ref
	|from Document.Permission as Documents
	|where Documents.Document = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Document );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );

EndFunction

&AtServer
Procedure send ( Document, Reason )
	
	params = new Array ();
	params.Add ( Document );
	params.Add ( Reason );
	Jobs.Run ( "PermissionsMailing.Send", params, , , TesterCache.Testing () );
	
EndProcedure
