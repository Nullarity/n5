#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	Fields.Add ( "Assistant" );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = ""
	+ Data.Assistant
	+ " #"
	+ Data.Number
	+ " "
	+ Format ( Data.Date, "DLF=D" );
	
EndProcedure

Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	if ( newChat ( FormType, Parameters ) ) then
		Parameters.Insert ( "NewWindow", new UUID () );
		SelectedForm = Metadata.Documents.Chat.Forms.Form;
		StandardProcessing = false;
	endif;
	
EndProcedure

Function newChat ( Type, Parameters )
	
	return Type = "ObjectForm"
	and not Parameters.Property ( "Key" )
	and not Parameters.Property ( "CopyingValue" );
	
EndFunction

#endif
