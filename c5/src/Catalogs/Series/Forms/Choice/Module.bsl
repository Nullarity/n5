// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	seriesEnabled ();

EndProcedure

&AtServer
Procedure seriesEnabled ()
	
	item = undefined;
	Parameters.Filter.Property ( "Owner", item );
	if ( ValueIsFilled ( item )
		and not DF.Pick ( item, "Series" ) ) then
		raise Output.NoSeries ();
	endif;

EndProcedure
