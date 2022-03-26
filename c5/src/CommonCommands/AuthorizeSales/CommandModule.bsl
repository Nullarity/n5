
&AtClient
async Procedure CommandProcessing ( Command, ExecuteParameters )

	answer = await Output.RestrictionsRequestWarning ();
	if ( answer <> DialogReturnCode.Yes ) then
		return;
	endif;
	params = ExecuteParameters.Parameters;
	form = Forms.FindByID ( params.Form );
	if ( DocumentForm.SaveNew ( form ) ) then
		openRequest ( form, params.Reason );
	endif;

EndProcedure

&AtClient
Procedure openRequest ( Form, Reason )

	ref = Form.Object.Ref;
	p = new Structure ( "Key, Document, Reason", findPermission ( ref ), ref, Reason );
	OpenForm ( "Document.SalesPermission.ObjectForm", p, Form );

EndProcedure

&AtServer
Function findPermission ( val Document )
	
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
