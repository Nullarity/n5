&AtServer
Procedure Prepare ( Form ) export

	chat = Form.Chat;
	templates = DataProcessors.Chat.GetTemplate ( "HTML" ).GetText ();
	chat.SenderTemplate = CoreLibrary.GetArea ( templates, "Sender" );
	chat.ReceiverTemplate = CoreLibrary.GetArea ( templates, "Receiver" );
	chat.FileTemplate = CoreLibrary.GetArea ( templates, "File" );
	chat.ErrorTemplate = CoreLibrary.GetArea ( templates, "Error" );
	chat.SenderMessageTemplate = CoreLibrary.GetArea ( templates, "SenderMessage" );
	chat.ReceiverMessageTemplate = CoreLibrary.GetArea ( templates, "ReceiverMessage" );
	chat.BodyTemplate = CoreLibrary.GetArea ( templates, "Body" );

EndProcedure

&AtServer
Procedure SetBody ( Chat, Object ) export
	
	body = getBody ( Chat, Object );
	Chat.Body = Output.FormatStr ( Chat.BodyTemplate,
		new Structure ( "Body, UniqueID", body, new UUID () ) );
	
EndProcedure

&AtServer
Function getBody ( Chat, Object )
	
	parts = new Array ();
	for each row in Object.Data do
		if ( row.System ) then
			continue;
		endif;
		parts.Add ( ChatForm.GetParagraph ( Chat, Object, row ) );
	enddo;
	return StrConcat ( parts );
	
EndFunction

Function GetParagraph ( Chat, Object, Row ) export
	
	id = ChatForm.ElementID ( Row.Element );
	content = Row.Content;
	if ( Row.Separator ) then
		if ( Row.Me ) then
			text = Object.Creator;
			template = Chat.SenderTemplate;
		else
			text = Object.Assistant;
			template = Chat.ReceiverTemplate;
		endif;
		return Output.FormatStr ( template, new Structure ( "ID, Name", id,
			Conversion.PlainTextToHTML ( text ) ) );
	elsif ( content = PredefinedValue ( "Enum.ContentType.File" ) ) then
		return Output.FormatStr ( Chat.FileTemplate, new Structure ( "ID, File", id,
			Conversion.PlainTextToHTML ( Row.Text ) ) );
	elsif ( Row.Error ) then
		return Output.FormatStr ( Chat.ErrorTemplate, new Structure ( "ID, Error", id,
			Conversion.PlainTextToHTML ( Row.Text ) ) );
	else
		if ( Row.Me ) then
			text = Conversion.PlainTextToHTML ( Row.Text );
			template = Chat.SenderMessageTemplate;
		else
			if ( content = PredefinedValue ( "Enum.ContentType.Image" ) ) then
				text = "<img src=""" + ChatFormSrv.ImageURL ( Row.Text ) + """>";
			else
				text = prepareText ( Object, Row );
			endif;
			template = Chat.ReceiverMessageTemplate;
		endif;
		return Output.FormatStr ( template, new Structure ( "ID, Text", id, text ) );
	endif;
	
EndFunction

Function prepareText ( Object, Row )
	
	text = Row.Text;
	if ( Object.Provider = PredefinedValue ( "Enum.AIProviders.Anthropic" ) ) then
		text = CoreLibrary.CleanAnthropicAnswer ( text );
	endif;
	return CoreLibrary.MarkdownToHTML ( fixImages ( Object, text ) )
	
EndFunction

Function fixImages ( Object, HTML )
	
	text = HTML;
	for each row in Object.Files do
		if ( not row.Picture ) then
			continue;
		endif;
		text = StrReplace ( text, row.Link, ChatFormSrv.ImageURL ( row.ID ) );
	enddo;
	return text;
	
EndFunction

Function ElementID ( Element ) export
	
	return Format ( "l" + Element, "NG=0;NZ=0" );
	
EndFunction

&AtClient
async Procedure OnClick ( Files, Server, Session, Item, EventData ) export
	
	link = EventData.Href;
	if ( link = undefined ) then
		return;
	endif;
	for each file in Files do
		if ( file.Presentation = link ) then
			data = fetchFile ( file.Value, Server, Session );
			await GetFileFromServerAsync ( data.Address, data.File, new GetFilesDialogParameters () );
			return;
		endif;
	enddo;
	GotoURL ( link );
	
EndProcedure

&AtClient
Function fetchFile ( val File, val Server, val Session )
	
	p = AIServer.DownloadParams ();
	p.Server = Server;
	p.Session = Session;
	p.File = File;
	return AIServer.Download ( p );
	
EndFunction