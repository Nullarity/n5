Function GetTenantCode () export
	
	return DF.Pick ( SessionParameters.Tenant, "Code" );
	
EndFunction 

Function GetTenantURL ( TenantCode ) export
	
	return Cloud.ApplicationURL () + "/" + TenantCode;
	
EndFunction 

Function ApplicationURL () export
	
	return Constants.ApplicationURL.Get ();
	
EndFunction 

Function ThinClientURL () export
	
	return Constants.ThinClientURL.Get ();
	
EndFunction 

Function EditorURL () export
	
	return Cloud.EditorRootURL () + "/ckeditor.js";
	
EndFunction 

Function EmailStyle () export
	
	return Constants.EmailStyle.Get ();
	
EndFunction 

Function EditorStyleURL () export
	
	return EditorRootURL () + "/contents.css";
	
EndFunction 

Function EditorRootURL () export
	
	if ( Environment.WebClient () ) then
		return Constants.CKEditorURL.Get ();
	else
		return Constants.CKEditorURLie.Get ();
	endif; 
	
EndFunction 

Function PaymentsURL () export
	
	return Constants.PaymentsURL.Get ();
	
EndFunction 

Function PicturesURL () export
	
	return Constants.PicturesURL.Get ();
	
EndFunction 

Function GetEmailsFolder ( MailBox ) export
	
	folder = Constants.EmailAttachments.Get ();
	tenant = Cloud.GetTenantCode ();
	return folder + "\" + tenant + "\" + Mailbox.UUID ();
	
EndFunction 

Function GetEmailURL ( Mailbox ) export
	
	url = Constants.EmailAttachmentsURL.Get ();
	tenant = Cloud.GetTenantCode ();
	return lower ( url + "/" + tenant + "/" + Mailbox.UUID () );
	
EndFunction 

Function GetFolders () export
	
	folder = Constants.Folders.Get ();
	return folder;
	
EndFunction 

Function GetFoldersURL () export
	
	return Constants.FoldersURL.Get ();
	
EndFunction 

Function EmailAttachmentsFolder () export
	
	return "413d62ee-a50f-4ade-abe4-16ee507365a5";
	
EndFunction 

Function Domain () export
	
	return Constants.Domain.Get ();
	
EndFunction 

Function Website () export
	
	return Constants.Website.Get ();
	
EndFunction 

Function Manual () export
	
	return Constants.Manual.Get ();
	
EndFunction 

Function Support () export
	
	return Constants.SupportEmail.Get ();
	
EndFunction 

Function Info () export
	
	return Constants.InfoEmail.Get ();
	
EndFunction 

Function Noreply () export
	
	return Constants.Noreply.Get ();
	
EndFunction 

Function Forum () export
	
	return Constants.ForumURL.Get ();
	
EndFunction 

Function SMTPUser () export
	
	return Constants.SMTPUser.Get ();
	
EndFunction 

Function SMTPPassword () export
	
	return Constants.SMTPPassword.Get ();
	
EndFunction 

Function SMTPServer () export
	
	return Constants.SMTPServer.Get ();
	
EndFunction 

Function SMTPSSL () export
	
	return Constants.SMTPSSL.Get ();
	
EndFunction 

Function SMTPPort () export
	
	return Constants.SMTPPort.Get ();
	
EndFunction 

Function UploadsWebsite () export
	
	return Constants.UploadsWebsite.Get ();
	
EndFunction 

Function UploadsFolder () export
	
	return Constants.UploadsFolder.Get ();
	
EndFunction 

Function ConvertDocExe () export
	
	return Constants.ConvertDocExe.Get ();
	
EndFunction 

Function ConvertXLSExe () export
	
	return Constants.ConvertXLSExe.Get ();
	
EndFunction 

Function HTMLExe () export
	
	return Constants.HTMLExe.Get ();
	
EndFunction 

Function User () export
	
	return Constants.CloudUser.Get ();
	
EndFunction 

Function ExchangeUser () export
	
	return Constants.ExchangeUser.Get ();
	
EndFunction 

Function MailService () export
	
	return Constants.MailService.Get () + "/" + Cloud.GetTenantCode ();
	
EndFunction

Function Cloud () export
	
	return Constants.Cloud.Get ();
	
EndFunction

Function SaaS () export
	
	return Constants.SaaS.Get ();
	
EndFunction

Function RemoteActionsService () export
	
	return Constants.RemoteActionsService.Get () + "/" + GetTenantCode ();
	
EndFunction 
