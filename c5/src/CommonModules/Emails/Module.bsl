Procedure OpenLink ( EventData, StandardProcessing, Mailbox, Email ) export
	
	command = getCommand ( EventData );
	if ( command = undefined ) then
		linkProcessing ( EventData, StandardProcessing, Mailbox );
	else
		doCommand ( command, Email );
	endif;
	
EndProcedure 

Function getCommand ( EventData )

	if ( EventData.Element.id = "" ) then
		return undefined;
	endif; 
	data = Conversion.StringToArray ( EventData.Element.id, "#" );
	command = new Structure ();
	command.Insert ( "Name", data [ 0 ] );
	command.Insert ( "Parameter", ? ( data.Count () = 1, undefined,  data [ 1 ] ) );
	return command;
	
EndFunction 

Procedure linkProcessing ( EventData, StandardProcessing, Mailbox )
	
	link = adjustHref ( EventData.Href );
	if ( link = undefined ) then
		return;
	endif;
	mailTo = Lower ( Left ( Link, 7 ) );
	if ( mailTo = "mailto:" ) then
		StandardProcessing = false;
		openNewEmail ( Mid ( link, 8 ), Mailbox );
	else
		details = EmailsSrv.LinkDetails ( link );
		if ( details.IsInternal ) then
			StandardProcessing = false;
			if ( details.Commands = undefined ) then
				GotoURL ( link );
			else
				cmd = details.Commands;
				if ( cmd.Property ( "c1" ) ) then
					renewTenantOrder ( cmd.c1 );
				endif;
			endif; 
		endif; 
	endif; 
	
EndProcedure 

Function adjustHref ( Href )
	
	if ( Href <> undefined
		and StrStartsWith ( Href, "about:" ) ) then
		return Mid ( Href, 7 ); // StrLen ( "about:" )
	endif;
	return Href;
	
EndFunction

Procedure openNewEmail ( Address, Mailbox )
	
	values = new Structure ();
	values.Insert ( "Receiver", Address );
	values.Insert ( "Mailbox", Mailbox );
	OpenForm ( "Document.OutgoingEmail.ObjectForm", new Structure ( "FillingValues", values ) );
	
EndProcedure 

Procedure renewTenantOrder ( OrderNumber )
	
	if ( CloudPayments.UserCanPay () ) then
		p = new Structure ( "FillingValues", new Structure () );
		p.FillingValues.Insert ( "RenewTenantOrder", OrderNumber );
		OpenForm ( "Document.TenantOrder.ObjectForm", p );
	else
		Output.TenantOrderAccessError ( ThisObject );
	endif; 
	
EndProcedure 

Procedure doCommand ( Command, Email )
	
	if ( Command.Name = Enum.EmailBodyDownload ()
		or Command.Name = Enum.EmailBodyOpen () ) then
		data = EmailsSrv.GetFileData ( Number ( Command.Parameter ), Email );
		p = Attachments.GetParams ();
		if ( Command.Name = Enum.EmailBodyDownload () ) then
			p.Command = Enum.AttachmentsCommandsDownload ();
		else
			p.Command = Enum.AttachmentsCommandsShow ();
		endif; 
		p.FolderID = data.MessageID;
		p.Mailbox = data.Mailbox;
		p.Ref = Email;
		p.Files = new Array ();
		p.Files.Add ( data.File );
		Attachments.Command ( p );
	endif; 
	
EndProcedure 

Procedure ProcessLink ( EventData, StandardProcessing ) export
	
	link = adjustHref ( EventData.Href );
	if ( link = undefined ) then
		return;
	endif;
	details = EmailsSrv.LinkDetails ( link );
	if ( details.IsInternal ) then
		StandardProcessing = false;
		GotoURL ( link );
	endif;
	
EndProcedure