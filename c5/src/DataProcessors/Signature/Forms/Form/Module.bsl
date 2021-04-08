// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadField ();
	
EndProcedure

&AtServer
Procedure loadField ()
	
	data = DataProcessors.Signature.GetTemplate ( "Signature" );
	reader = new TextReader ( data.OpenStreamForRead () );
	HTML = reader.Read ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure HTMLOnClick ( Item, EventData, StandardProcessing )
	
	location = EventData.Href;
	if ( not ValueIsFilled ( location ) ) then
		return;
	endif;
	StandardProcessing = false;
	Close ( getBinary ( location ) );
	
EndProcedure

&AtServer
Function getBinary ( Location )
	
	prefix = "?data=";
	started = StrFind ( Location, prefix );
	if ( started = 0 ) then
		return undefined;
	endif;
	s = Mid ( Location, started + StrLen ( prefix ) );
	data = Base64Value ( DecodeString ( s, StringEncodingMethod.URLEncoding ) );
	return data;
		
EndFunction 
