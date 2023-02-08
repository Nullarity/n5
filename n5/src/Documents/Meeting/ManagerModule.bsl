#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Start" );
	Fields.Add ( "Room" );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	start = Data.Start;
	Presentation = Metadata.Documents.Meeting.Synonym
	+ ", " + Format ( start, "DLF=D" )
	+ " " + Format ( start, Output.TimeFormat () )
	+ ", " + Data.Room;
	
EndProcedure

#endif