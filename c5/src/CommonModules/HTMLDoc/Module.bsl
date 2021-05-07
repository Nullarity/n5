Function GetNode ( Document, Parent, Node ) export
	
	elements = Parent.ПолучитьЭлементыПоИмени ( Node );
	if ( elements.Count () = 0 ) then
		newElement = Document.CreateElement ( Node );
		if ( Parent.FirstChild = undefined ) then
			return Parent.AppendChild ( newElement );
		else
			return Parent.InsertBefore ( newElement, Parent.FirstChild );
		endif; 
	else
		return elements [ 0 ];
	endif; 
	
EndFunction 

Procedure ClearNode ( Node ) export
	
	i = Node.ChildNodes.Count ();
	while ( i > 0 ) do
		i = i - 1;
		child = Node.ChildNodes [ i ];
		Node.RemoveChild ( child );
	enddo; 
	
EndProcedure 

Function GetText ( HTML ) export
	
	result = Regexp.Select ( HTML, "<body\b[^>]*>([\u0000-\uFFFF]*?)</body>" );
	if ( result.Count () = 0 ) then
		return HTML;
	endif;
	body = Regexp.Replace ( result [ 0 ].Groups [ 0 ], "<.*?\b[^>]*>", "" );
	return body;
	
EndFunction