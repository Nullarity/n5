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
	Chat.Body = Output.FormatStr ( Chat.BodyTemplate, new Structure ( "Body", body ) );
	
EndProcedure

&AtServer
Function getBody ( Chat, Object )
	
	parts = new Array ();
	for each row in Object.Data do
		parts.Add ( ChatForm.GetParagraph ( Chat, Object, row ) );
	enddo;
	return StrConcat ( parts );
	
EndFunction

Function GetParagraph ( Chat, Object, Row ) export
	
	id = ChatForm.ElementID ( Row.Element );
	if ( Row.Separator ) then
		if ( Row.Me ) then
			text = Object.Creator;
			template = Chat.SenderTemplate;
		else
			text = Object.Assistant;
			template = Chat.ReceiverTemplate;
		endif;
		return Output.FormatStr ( template, new Structure ( "ID, Name", id, text ) );
	elsif ( Row.File ) then
		return Output.FormatStr ( Chat.FileTemplate, new Structure ( "ID, File", id, Row.Text ) );
	elsif ( Row.Error ) then
		return Output.FormatStr ( Chat.ErrorTemplate, new Structure ( "ID, Error", id, Row.Text ) );
	else
		text = CoreLibrary.MarkdownToHTML ( Row.Text );
		if ( Row.Me ) then
			template = Chat.SenderMessageTemplate;
		else
			template = Chat.ReceiverMessageTemplate;
		endif;
		return Output.FormatStr ( template, new Structure ( "ID, Text", id, text ) );
	endif;
	
EndFunction

&AtClient
Procedure DeleteElement ( Form, Element ) export
	
	node = Form.Items.HTML.Document.getElementById ( ChatForm.ElementID ( Element ) );
	if ( node <> undefined ) then
		node.parentNode.removeChild ( node );
	endif;
	
EndProcedure

Function ElementID ( Element ) export
	
	return Format ( "l" + Element, "NG=0;NZ=0" );
	
EndFunction

&AtClient
Procedure OnClick ( Item, EventData, StandardProcessing ) export
	
	link = EventData.Href;
	if ( link <> undefined ) then
		StandardProcessing = false;
		GotoURL ( link );
	endif;
	
EndProcedure
