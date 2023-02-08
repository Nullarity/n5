
&AtClient
Procedure CommandProcessing ( Book, CommandExecuteParameters )
	
	p = new Structure ( "Book", Book );
	OpenForm ( "Catalog.Books.Form.ChangeCreator", p );
	
EndProcedure
