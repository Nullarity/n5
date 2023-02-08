Function LinkDetails ( val Link ) export
	
	result = new Structure ( "IsInternal, Commands" );
	tenantCode = DF.Pick ( SessionParameters.Tenant, "Code" );
	tenantURL = Lower ( Cloud.GetTenantURL ( tenantCode ) );
	request = Lower ( Link );
	result.IsInternal = Find ( request, tenantURL ) = 1
	or StrStartsWith ( request, "e1cib/" );
	if ( result.IsInternal ) then
		i = Find ( request, "?c=" );
		if ( i > 0 ) then
			cmd = Mid ( request, i + 3 );
			result.Commands = Conversion.StringToStructure ( cmd );
		endif; 
	endif; 
	return result;
	
EndFunction 

Function GetFileData ( val FileNumber, val Email ) export
	
	data = getAttachmentData ( FileNumber, Email );
	result = new Structure ( "MessageID, Mailbox, File" );
	FillPropertyValues ( result, data );
	return result;
	
EndFunction 

Function getAttachmentData ( FileNumber, Email )
	
	s = "
	|select Attachments.Ref.MessageID as MessageID, Attachments.Ref.Mailbox as Mailbox, Attachments.File as File
	|from " + Email.Metadata ().FullName () + ".Attachments as Attachments
	|where Attachments.Ref = &Ref
	|and Attachments.LineNumber = &FileNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Email );
	q.SetParameter ( "FileNumber", FileNumber );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, q.Execute ().Unload () [ 0 ] );
	
EndFunction 

Function GetHTML ( Email, MessageID, Mailbox, Files = false, PlainTextToHTML = false, Highlighting = "" ) export
	
	document = readEmail ( Email, MessageID, Mailbox, PlainTextToHTML );
	if ( Highlighting <> "" ) then
		addHighlight ( Document, Highlighting );
	endif;
	setHeader ( Document );
	if ( Files ) then
		attachFiles ( Email, Document );
	endif; 
	html = Conversion.DocumentToHTML ( document );
	return html;
	
EndFunction

Function readEmail ( Email, MessageID, Mailbox, PlainTextToHTML )
	
	file = EmailsSrv.GetFolder ( MessageID, Mailbox ) + "\" + Email.UUID ();
	reader = new TextReader ( file, "utf-8" );
	body = "";
	while ( true ) do
		s = reader.Read ( 1024 );
		if ( s = undefined ) then
			break;
		endif; 
		body = body + s;
	enddo; 
	html = Conversion.XMLToStandard ( body );
	adjustPlainText ( html, PlainTextToHTML );
	removeWhitespaces ( html );
	if ( Find ( html, "<html" ) <> 0
		or Find ( html, "<HTML" ) <> 0 ) then
	else
		html = "<html><body>" + html + "</body></html>";
	endif; 
	return Conversion.HTMLToDocument ( html );
	
EndFunction

Procedure adjustPlainText ( HTML, PlainTextToHTML )
	
	pattern = "<([A-Z][A-Z0-9]*)[^>]*>([\s\S]*?)</\1>|<([A-Z][A-Z0-9]*)([\s\S]*?)/>";
	if ( Regexp.Test ( HTML, pattern ) ) then
		return;
	endif; 
	if ( PlainTextToHTML ) then
		fixParentheses ( HTML );
		fixLines ( HTML );
	else
		HTML = "<pre style=""white-space:pre-wrap, -moz-pre-wrap, -pre-wrap, -o-pre-wrap;word-wrap:break-word;"">" + HTML + "</pre>";
	endif; 
	insertLinks ( HTML );

EndProcedure 

Procedure insertLinks ( Text )
	
	pattern = "(\b(https?://|ftp://|file://|www|ftp)[\-A-Z0-9+&#/%?=~_|!:,.;]*[\-A-Z0-9+&#/%=~_|])";
	Text = Regexp.Replace ( Text, pattern, "<a href=""$&"">$&</a>" );
	pattern = "(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|""(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*"")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])";
	Text = Regexp.Replace ( Text, pattern, "<a href=""mailto:$&"">$&</a>" );

EndProcedure 

Procedure fixParentheses ( Text )
	
	Text = Regexp.Replace ( Text, "<", "&lt;" );
	Text = Regexp.Replace ( Text, ">", "&gt;" );
	
EndProcedure 

Procedure fixLines ( Text )
	
	Text = Regexp.Replace ( Text, "\r\n", "<br/>" );
	Text = Regexp.Replace ( Text, "\n", "<br/>" );
	Text = Regexp.Replace ( Text, "\t", "&nbsp;&nbsp;&nbsp;&nbsp;" );
	
EndProcedure 

Procedure removeWhitespaces ( HTML )
	
	HTML = StrReplace ( HTML, Char ( 8203 ), "" );
	HTML = StrReplace ( HTML, Char ( 8232 ), "" );

EndProcedure 

Procedure addHighlight ( Document, Highlighting )
	
	head = HTMLDoc.GetNode ( Document, Document.DocumentElement, "head" );
	styles = HTMLDoc.GetNode ( Document, head, "style" );
	styles.AppendChild ( Document.CreateTextNode ( getStyles () ) );
	scripts = HTMLDoc.GetNode ( Document, head, "script" );
	scripts.AppendChild ( Document.CreateTextNode ( EmailsSrv.GetFunctions () ) );
	event = Document.CreateAttribute ( "onload" );
	event.Value = "highlightWord('" + Highlighting + "')";
	body = HTMLDoc.GetNode ( Document, Document.DocumentElement, "body" );
	body.Attributes.SetNamedItem ( event );
	
EndProcedure 

Function getStyles ()
	
	s = "
	|.X414c7b91330d41e495ca2b5a7bd935e3{
	|	background-color:yellow;
	|	color:black;
	|}
	|";
	return s;
	
EndFunction 

Function GetFunctions () export
	
	s = "
	|function highlightWord(searchString) {
	|	var nodes = textNodesUnder(document.body);
	|	var words = searchString.split(' ');
	|	for (var i in nodes) {
	|		highlightWords(nodes[i], words);
	|	}
	|}
	|function textNodesUnder(node) {
	|	var all = [];
	|	for (node = node.firstChild; node; node = node.nextSibling) {
	|		if (node.nodeType == 3) all.push(node);
	|		else all = all.concat(textNodesUnder(node));
	|	}
	|	return all;
	|}
	|function highlightWords(n, words) {
	|	for (var i in words) {
	|		var word = words[i].toLowerCase ();
	|		for (var j; (j = n.nodeValue.toLowerCase().indexOf(word, j)) > -1; n = after) {
	|			var after = n.splitText(j + word.length);
	|			var highlighted = n.splitText(j);
	|			var span = document.createElement('span');
	|			span.className = 'X414c7b91330d41e495ca2b5a7bd935e3';
	|			span.appendChild(highlighted);
	|			after.parentNode.insertBefore(span, after);
	|		}
	|	}
	|}
	|";
	return s;
	
EndFunction 

Procedure setHeader ( Document )
	
	style = Cloud.EmailStyle ();
	head = HTMLDoc.GetNode ( Document, Document.DocumentElement, "head" );
	base = HTMLDoc.GetNode ( Document, head, "base" );
	base.setAttribute ( "target", "_blank" );
	if ( styleExists ( head, style ) ) then
		return;
	endif; 
	link = HTMLDoc.GetNode ( Document, head, "link" );
	link.setAttribute ( "href", style );
	link.setAttribute ( "type", "text/css" );
	link.setAttribute ( "rel", "Stylesheet" );

EndProcedure 

Function styleExists ( Head, Style )
	
	items = Head.ChildNodes;
	for each item in items do
		if ( Lower ( item.NodeName ) = "link"
			and Lower ( item.href ) = Style ) then
			return true;
		endif; 
	enddo; 
	return false;
	
EndFunction 

Procedure attachFiles ( Email, Document )
	
	table = getAttachments ( Email );
	if ( table.Count () = 0 ) then
		return;
	endif; 
	files = getAttachmentsHTML ( table );
	body = HTMLDoc.GetNode ( Document, Document.DocumentElement, "body" );
	table = Conversion.HTMLToDocument ( files );
	tableBody = HTMLDoc.GetNode ( table, table.DocumentElement, "table" );
	import = Document.ImportNode ( tableBody, true );
	body.InsertBefore ( import, body.FirstChild );

EndProcedure 

Function getAttachments ( Email )
	
	s = "
	|select Attachments.Extension as Extension, Attachments.File as File, Attachments.Size as Size, Attachments.LineNumber as LineNumber
	|from " + Email.Metadata ().FullName () + ".Attachments as Attachments
	|where Attachments.Ref = &Ref
	|order by Attachments.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Email );
	return q.Execute ().Unload ();
	
EndFunction 

Function getAttachmentsHTML ( Table )
	
	parts = new Array ();
	parts.Add ( "<table cellspacing=10px style=""border: 1px solid #C0C0C0;font-family: 'Courier New', Courier, monospace;vertical-align: middle;border-collapse: separate;border-spacing: 10px;"">" );
	tr = "<tr>
	|<td><div style=""width: 16px; height: 16px; background-position:%Picturepx -14px; background-image: url('" + Cloud.PicturesURL () + "')"">&nbsp;</div></td>
	|<td>%File</td>
	|<td style='text-align: right'>%Size</td>
	|<td>|</td>
	|<td style='color:blue;cursor:pointer;' id='%Download' name='%Download'>" + Output.Download () + "</td>
	|<td>|</td>
	|<td style='color:blue;cursor:pointer;' id='%Open' name='%Open'>" + Output.Open () + "</td>
	|</tr>";
	p = new Structure ( "Picture, File, Size, Download, Open" );
	for each row in Table do
		p.Picture = ? ( row.Extension = 0, "0", "-" + Format ( row.Extension * 16, "NG=" ) );
		p.File = row.File;
		p.Download = Enum.EmailBodyDownload () + "#" + Format ( row.LineNumber, "NG=;NZ=" );
		p.Open = Enum.EmailBodyOpen () + "#" + Format ( row.LineNumber, "NG=;NZ=" );
		p.Size = Conversion.BytesToSize ( row.Size );
		parts.Add ( Output.FormatStr ( tr, p ) );
	enddo; 
	parts.Add ( "</table><br/>" );
	return StrConcat ( parts );
	
EndFunction

Function GetFolder ( MessageID, MailBox ) export
	
	return Cloud.GetEmailsFolder ( MailBox ) + "\" + MessageID;
	
EndFunction 

Function GetFolderURL ( MessageID, Mailbox ) export
	
	return Cloud.GetEmailURL ( Mailbox ) + "/" + MessageID;
	
EndFunction 

Function GetAttachmentsFolder ( MessageID, MailBox ) export
	
	return Cloud.GetEmailsFolder ( MailBox ) + "\" + MessageID + "\" + Cloud.EmailAttachmentsFolder ();
	
EndFunction 

Function GetAttachmentsFolderURL ( MessageID, MailBox ) export
	
	return Cloud.GetEmailURL ( Mailbox ) + "/" + MessageID + "/" + Cloud.EmailAttachmentsFolder ();
	
EndFunction 

Procedure Clean ( val MessageID, val Mailbox ) export
	
	folder = EmailsSrv.GetFolder ( MessageID, Mailbox );
	DeleteFiles ( folder );
	
EndProcedure 