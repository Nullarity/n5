Procedure Make ()

	area = getArea ();
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure