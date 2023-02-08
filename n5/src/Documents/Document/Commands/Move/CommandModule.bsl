
&AtClient
Procedure CommandProcessing ( Items, CommandExecuteParameters )
	
	openBooks ( Items );
	
EndProcedure

&AtClient
Procedure openBooks ( Items )
	
	p = new Structure ();
	p.Insert ( "CurrentRow", DF.Pick ( Items [ 0 ], "Book" ) );
	OpenForm ( "Document.Document.Form.Books", p, , , , , new NotifyDescription ( "Books", ThisObject, Items ) );
	
EndProcedure 

&AtClient
Procedure Books ( Result, Items ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	changeBook ( Result, Items );
	
EndProcedure 

&AtServer
Procedure changeBook ( val Book, val Items ) export
	
	for each document in Items do
		obj = document.GetObject ();
		obj.Book = Book;
		obj.Write ();
	enddo; 
	
EndProcedure 