
&AtClient
Procedure CommandProcessing ( Book, CommandExecuteParameters )
	
	OpenForm ( "Catalog.Books.Form.URL", new Structure ( "Book", Book ) );
	
EndProcedure
