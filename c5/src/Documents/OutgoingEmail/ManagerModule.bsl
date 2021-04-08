#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	Fields.Add ( "Subject" );
	Fields.Add ( "Receiver" );
	Fields.Add ( "ReceiverName" );
	StandardProcessing = false;
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = ? ( Data.ReceiverName = "", Data.Receiver, Data.ReceiverName ) + ": " + Left ( Data.Subject, 50 );
	
EndProcedure

Procedure ChoiceDataGetProcessing ( ChoiceData, Parameters, StandardProcessing )
	
	StandardProcessing = false;
	ChoiceData = FullSearch.List ( Parameters.SearchString, Enums.Search.Outgoing );
	
EndProcedure

#endif