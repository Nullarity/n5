Procedure Update () export
	
	if ( FullTextSearch.GetFullTextSearchMode () = FullTextMode.Disable
		or FullTextSearch.IndexTrue () ) then
		return;
	endif;
	FullTextSearch.UpdateIndex ( false, true );
	
EndProcedure 

Procedure Merge () export
	
	if ( FullTextSearch.GetFullTextSearchMode () = FullTextMode.Disable ) then
		return;
	endif; 
	FullTextSearch.UpdateIndex ( true );
	
EndProcedure
