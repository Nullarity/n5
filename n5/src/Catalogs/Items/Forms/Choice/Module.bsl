// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setTitle ();
	
EndProcedure

&AtServer
Procedure setTitle ()
	
	filter = Parameters.Filter;
	if ( filter.Property ( "Service" )
		and filter.Service ) then
		AutoTitle = false;
		Title = Output.ServicesList ();
	endif;
	
EndProcedure
