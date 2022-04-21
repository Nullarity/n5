
&AtClient
async Procedure CommandProcessing ( Command, ExecuteParameters )

	params = ExecuteParameters.Parameters;
	form = Forms.FindByID ( params.Form );
	variant = await askPeriod ( form );
	if ( variant = undefined ) then
		return;
	else
		forDocument = variant = 0;
		if ( forDocument
			and not DocumentForm.SaveModified ( form ) ) then
			return;
		endif;
	endif;
	openRequest ( Form, forDocument );

EndProcedure

&AtClient
async Function askPeriod ( Form )
	
	menu = new ValueList ();
	menu.Add ( 0, Output.ForThisDocument () );
	menu.Add ( 1, Output.ForTheDay () );
	item = await menu.ChooseItemAsync ( Output.OpenPeriodRequest (), Form.CurrentItem );
	return ? ( item = undefined, undefined, item.Value );
	
EndFunction

&AtClient
Procedure openRequest ( Form, ForDocument )

	object = Form.Object;
	date = object.Date;
	ref = object.Ref;
	base = ? ( ForDocument, ref, date );
	p = new Structure ( "Key, Base, Document", findPermission ( ref, date ), base, ref );
	OpenForm ( "Document.ChangesPermission.ObjectForm", p, Form );

EndProcedure

&AtServer
Function findPermission ( val Document, val Day )
	
	q = new Query ();
	s = "
	|select top 1 Documents.Ref as Ref
	|from Document.ChangesPermission as Documents
	|where ";
	if ( Document.IsEmpty () ) then
		s = s + "
		|Documents.Document = undefined
		|and Documents.Class = &Class
		|and Documents.Day = &Day
		|and Documents.Creator = &Creator";
		q.SetParameter ( "Class", MetadataRef.Get ( Document.Metadata ().FullName () ) );
		q.SetParameter ( "Day", BegOfDay ( Day ) );
		q.SetParameter ( "Creator", SessionParameters.User );
	else
		s = s + "
		|Documents.Document = &Document";
		q.SetParameter ( "Document", Document );
	endif;
	q.Text = s;
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );

EndFunction
