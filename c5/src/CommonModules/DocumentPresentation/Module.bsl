
Procedure StandardFields ( Fields, StandardProcessing ) export
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

Procedure StandardPresentation ( Synonym, Data, Presentation, StandardProcessing ) export
	
	StandardProcessing = false;
	Presentation = Synonym
	+ " #"
	+ Data.Number
	+ " "
	+ Format ( Data.Date, "DLF=D" );
	
EndProcedure

Procedure IncomingFields ( Fields, StandardProcessing ) export
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	Fields.Add ( "Reference" );
	Fields.Add ( "ReferenceDate" );
	
EndProcedure

Procedure IncomingPresentation ( Synonym, Data, Presentation, StandardProcessing ) export
	
	StandardProcessing = false;
	Presentation = Synonym
	+ " #"
	+ ? ( Data.Reference = "", Data.Number, Data.Reference )
	+ " "
	+ Format ( ? ( Data.ReferenceDate = Date ( 1, 1, 1 ), Data.Date, Data.ReferenceDate ), "DLF=D" );
	
EndProcedure
