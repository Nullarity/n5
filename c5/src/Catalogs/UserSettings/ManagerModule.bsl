#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Owner" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Catalogs.UserSettings.Synonym + ": " + Data.Owner;
	
EndProcedure

Procedure Init ( Object ) export
	
	Object.Company = Application.Company ();
	Object.TimesheetNotifications = true;
	Object.MeetingNotifications = true;
	
EndProcedure

#endif