Procedure WriteStatus ( Message, Complete = false, Count = 0, Total = 0, ErrorCode = 0, OutgoingEmail = undefined ) export
	
	record = InformationRegisters.MailChecking.CreateRecordManager ();
	record.User = SessionParameters.User;
	record.Message = Message;
	record.Complete = Complete;
	record.Count = Count;
	record.ErrorCode = ErrorCode;
	record.Total = Total;
	record.OutgoingEmail = OutgoingEmail;
	record.Write ();
	
EndProcedure 

Function GetStatus () export
	
	return InformationRegisters.MailChecking.Get ( new Structure ( "User", SessionParameters.User ) );
	
EndFunction

Procedure DeleteStatus () export
	
	record = InformationRegisters.MailChecking.CreateRecordManager ();
	record.User = SessionParameters.User;
	record.Delete ();
	
EndProcedure 

Function GetPeriodicity () export
	
	s = "
	|select top 1 UserSettings.MailCheck as Periodicity
	|from Catalog.MailBoxes as Boxes
	|	//
	|	// Periodicity
	|	//
	|	join Catalog.UserSettings as UserSettings
	|	on UserSettings.Owner = &User
	|	and UserSettings.MailCheck <> 0
	|where not Boxes.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Periodicity );
	
EndFunction 

Function AlreadyStarted () export
	
	jobKey = keyOfReceiving ();
	job = Jobs.GetBackground ( jobKey );
	return job <> undefined;
	
EndFunction 

Function keyOfReceiving ()
	
	return "ReceiveEmail" + UserName ();
	
EndFunction 

Procedure Start () export
	
	if ( AlreadyStarted () ) then
		return;
	endif; 
	jobKey = keyOfReceiving ();
	Jobs.Run ( "MailboxesSrv.Receive", , jobKey );
	
EndProcedure 

Function GetResult () export
	
	status = MailChecking.GetStatus ();
	if ( status.Complete ) then
		DeleteStatus ();
	endif;
	return status;
	
EndFunction 

Function ProfileExists () export
	
	s = "
	|select top 1 1
	|from Catalog.Mailboxes as Boxes
	|where not Boxes.DeletionMark
	|and Boxes.Owner = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	return q.Execute ().Select ().Next ();
	
EndFunction
