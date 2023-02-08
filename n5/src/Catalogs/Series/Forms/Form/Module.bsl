// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	seriesEnabled ();
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure seriesEnabled ()
	
	if ( not DF.Pick ( Object.Owner, "Series" ) ) then
		raise Output.NoSeries ();
	endif;

EndProcedure

// *****************************************
// *********** Form

&AtClient
Procedure LotOnChange ( Item )
	
	Object.Description = Object.Lot;

EndProcedure

&AtClient
Procedure ProducedOnChange ( Item )
	
	SeriesForm.SetExpirationDate ( Object );
	
EndProcedure

&AtClient
Procedure ExpirationPeriodOnChange ( Item )
	
	SeriesForm.SetExpirationDate ( Object );
	
EndProcedure

&AtClient
Procedure ExpirationDateOnChange ( Item )
	
	SeriesForm.SetExpirationPeriod ( Object );
	
EndProcedure
