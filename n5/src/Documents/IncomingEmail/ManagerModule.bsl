#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	Fields.Add ( "Subject" );
	Fields.Add ( "Sender" );
	Fields.Add ( "SenderName" );
	StandardProcessing = false;
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = ? ( Data.SenderName = "", Data.Sender, Data.SenderName ) + ": " + Left ( Data.Subject, 50 );
	
EndProcedure

Procedure ChoiceDataGetProcessing ( ChoiceData, Parameters, StandardProcessing )
	
	StandardProcessing = false;
	ChoiceData = FullSearch.List ( Parameters.SearchString, Enums.Search.Incoming );
	
EndProcedure

Procedure MarkAsNew ( Email ) export
	
	record = InformationRegisters.NewMail.CreateRecordManager ();
	record.User = SessionParameters.User;
	record.IncomingEmail = Email;
	record.Write ();
	
EndProcedure 

Procedure MarkAsRead ( Email ) export
	
	record = InformationRegisters.NewMail.CreateRecordManager ();
	record.User = SessionParameters.User;
	record.IncomingEmail = Email;
	record.Delete ();
	
EndProcedure 

Function IsNew ( Email ) export
	
	record = InformationRegisters.NewMail.CreateRecordManager ();
	record.User = SessionParameters.User;
	record.IncomingEmail = Email;
	record.Read ();
	return record.Selected ();
	
EndFunction 


#endif