
// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	initEditor ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure initEditor ()
	
	CKEditorSrv.Init ( Signature, Object.FolderID, , , false );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setFolderID ();
		initEditor ();
		setDefaults ();
		setPOP3Port ( Object );
		setIMAPPort ( Object );
		setSMTPPort ( Object );
		setUser ( Object );
		setDescription ( Object );
	endif; 
	setMailCheck ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|GroupPOP3 show Object.Protocol = Enum.Protocols.POP3;
	|GroupIMAP show Object.Protocol = Enum.Protocols.IMAP
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setFolderID ()
	
	Object.FolderID = new UUID ();
	
EndProcedure 

&AtServer
Procedure setDefaults ()
	
	Object.Owner = SessionParameters.User;
	data = DF.Values ( Object.Owner, "Email, Description" );
	Object.Email = data.Email;
	Object.Box = data.Description;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setPOP3Port ( Object )
	
	if ( Object.POP3UseSSL ) then
		Object.POP3Port = 995;
	else
		Object.POP3Port = 110;
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setIMAPPort ( Object )
	
	if ( Object.IMAPUseSSL ) then
		Object.IMAPPort = 993;
	else
		Object.IMAPPort = 143;
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setSMTPPort ( Object )
	
	if ( Object.SMTPUseSSL ) then
		Object.SMTPPort = 465;
	else
		Object.SMTPPort = 25;
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setUser ( Object )
	
	Object.POP3User = Left ( Object.Email, Find ( Object.Email, "@" ) - 1 );
	Object.IMAPUser = Object.POP3User;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setDescription ( Object )
	
	Object.Description = Object.Email;
	
EndProcedure 

&AtServer
Procedure setMailCheck ()
	
	if ( Object.Ref.IsEmpty () ) then
		setDefaultMailCheck ();
	else
		MailCheck = Logins.Settings ( "MailCheck", Object.Owner ).MailCheck;
	endif; 

EndProcedure 

&AtServer
Procedure setDefaultMailCheck ()
	
	if ( not Object.Ref.IsEmpty () ) then
		return;
	endif;
	if ( Object.Protocol = Enums.Protocols.IMAP ) then
		MailCheck = 60;
	else
		MailCheck = 300;
	endif; 

EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( EditorBegun ) then
		CKEditor.SaveHTML ( WriteParameters, Items.Signature );
	endif; 
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	writeMailCheck ();
	
EndProcedure

&AtServer
Procedure writeMailCheck ()
	
	settings = Logins.Settings ( "Ref", Object.Owner ).Ref.GetObject ();
	settings.MailCheck = MailCheck;
	settings.Write ();
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Object.Ref.IsEmpty () ) then
		createLabels ( CurrentObject.Ref );
	endif; 
	if ( EditorBegun ) then
		CKEditorSrv.Store ( Object.FolderID, WriteParameters.Signature );
	endif;
	Mailboxes.AddAddress ( Object.Email, Object.Box );

EndProcedure

&AtServer
Procedure createLabels ( Mailbox )
	
	obj = Catalogs.MailLabels.CreateItem ();
	obj.Owner = Mailbox;
	obj.LabelType = Enums.LabelTypes.Incoming;
	obj.Description = Output.MyMail ();
	obj.System = true;
	obj.User = SessionParameters.User;
	obj.Write ();
	obj = Catalogs.MailLabels.CreateItem ();
	obj.Owner = Mailbox;
	obj.LabelType = Enums.LabelTypes.Outgoing;
	obj.Description = Output.Outbox ();
	obj.System = true;
	obj.User = SessionParameters.User;
	obj.Write ();
	obj = Catalogs.MailLabels.CreateItem ();
	obj.Owner = Mailbox;
	obj.LabelType = Enums.LabelTypes.Trash;
	obj.Description = Output.Deleted ();
	obj.System = true;
	obj.User = SessionParameters.User;
	obj.Write ();
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	setByDefault ( CurrentObject.Ref );
	
EndProcedure

&AtServer
Procedure setByDefault ( Mailbox )
	
	if ( not defaultExists () ) then
		Mailboxes.SetByDefault ( Mailbox );
	endif; 
	
EndProcedure 

&AtServer
Function defaultExists ()
	
	s = "
	|select top 1 1
	|from Catalog.UserSettings as UserSettings
	|where UserSettings.Owner = &User
	|and UserSettings.Mailbox <> value ( Catalog.Mailboxes.EmptyRef )
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	return q.Execute ().Select ().Next ();
	
EndFunction 

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( EditorBegun ) then
		CKEditor.ResetDirty ( Items.Signature );
	endif; 
	AttachEmailCheck ();
	Notify ( Enum.MessageMailBoxChanged () );
	
EndProcedure

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( Exit ) then
		Cancel = true;
		return;
	endif; 
	if ( EditorBegun ) then
		CKEditor.CheckModified ( ThisObject, Items.Signature );
	endif; 

EndProcedure

&AtClient
Procedure OnClose ( Exit )
	
	if ( Exit ) then
		return;
	endif; 
	if ( Object.Ref.IsEmpty () ) then
		CKEditorSrv.Clean ( Object.FolderID );
	endif; 
	CKEditorSrv.RemoveScript ( Object.FolderID );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure EmailOnChange ( Item )
	
	setUser ( Object );
	setDescription ( Object );
	
EndProcedure

&AtClient
Procedure POP3UseSSLOnChange ( Item )
	
	setPOP3Port ( Object );
	
EndProcedure

&AtClient
Procedure SMTPUseSSLOnChange ( Item )
	
	setSMTPPort ( Object );
	
EndProcedure

&AtClient
Procedure ProtocolOnChange ( Item )
	
	applyProtocol ();
	
EndProcedure

&AtServer
Procedure applyProtocol ()
	
	setDefaultMailCheck ();
	Appearance.Apply ( ThisObject, "Object.Protocol" );
	
EndProcedure 

&AtClient
Procedure IMAPUseSSLOnChange ( Item )
	
	setIMAPPort ( Object );
	
EndProcedure

&AtClient
Procedure SignatureDocumentComplete ( Item )
	
	if ( EditorBegun ) then
		return;
	endif; 
	EditorBegun = true;
	
EndProcedure

&AtClient
Procedure SignatureOnClick ( Item, EventData, StandardProcessing )
	
	href = EventData.Href;
	if ( href = undefined ) then
		return;
	endif; 
	StandardProcessing = false;
	if ( CKEditor.Action ( href, Enum.EditorActionSave () ) )then
		saveItem ();
	elsif ( CKEditor.Action ( href, Enum.EditorActionSaveAndClose () ) )then
		saveAndCloseItem ();
	elsif ( CKEditor.Action ( href, Enum.EditorActionCancel () ) )then
		cancelEditing ();
	else
		StandardProcessing = true;
	endif; 
	
EndProcedure

&AtClient
Procedure saveItem ()
	
	Write ();
	
EndProcedure 

&AtClient
Procedure saveAndCloseItem ()
	
	if ( Write () ) then
		Close ();
	endif; 
	
EndProcedure 

&AtClient
Procedure cancelEditing ()
	
	Close ();
	
EndProcedure 
