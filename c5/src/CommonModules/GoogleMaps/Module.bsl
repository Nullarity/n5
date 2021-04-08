Function ByLocation ( Latitude, Longitude, Zoom ) export
	
	return getHTML ( Latitude, Longitude, undefined, Zoom );
	
EndFunction 

Function getHTML ( Latitude, Longitude, Address, Zoom )
	
	p = getParams ( Latitude, Longitude, Address, Zoom );
	exactLocation = p.exactLocation;
	s = "<!DOCTYPE html>
	|<html>
	|<head>";
	#if ( not WebClient ) then
		s = s + "<meta http-equiv='x-ua-compatible' content='IE=edge'>";
	#endif
	s = s + "
	|	<style>
	|		html, body {
	|			height: 100%;
	|			margin: 0;
	|			padding: 0;
	|			overflow-x: hidden;
	|			overflow-y: hidden;
	|			font-family: sans-serif;
	|			font-size: small
	|		}
	|		#map {
	|			height: 100%;
	|		}
	|		a:visited, a:link {
	|			color: gray;
	|			text-decoration: none;
	|		}
	|	</style>
	|	<script type='text/javascript'>
	|		var gmap;
	|		var Marker;
	|";
	if ( exactLocation ) then
		s = s + "
		|		function showMap () {
		|			openMap ( %Latitude, %Longitude );
		|		}
		|
		|		function navigateMap ( Latitude, Longitude ) {
		|			var location = new google.maps.LatLng ( { lat: parseFloat ( Latitude ), lng: parseFloat ( Longitude ) } );
		|			locateMap ( location );
		|		}
		|";
	else
		s = s + "
		|		function showMap () {
		|			var request = { address : '%Address' };
		|			var g = new google.maps.Geocoder ();
		|			g.geocode ( request, function ( list, status ) {
		|				if ( status != google.maps.GeocoderStatus.OK ) return;
		|				var location = list[0].geometry.location;
		|				openMap ( location.lat (), location.lng () );
		|			} )
		|		}
		|
		|		function navigateMap ( Address ) {
		|			var request = { address : Address };
		|			var g = new google.maps.Geocoder ();
		|			g.geocode ( request, function ( list, status ) {
		|				if ( status != google.maps.GeocoderStatus.OK ) return;
		|				var location = list[0].geometry.location;
		|				var location = new google.maps.LatLng ( { lat: location.lat (), lng: location.lng () } );
		|				locateMap ( location );
		|			} )
		|		}
		|";
	endif; 
	s = s + "
	|
	|		function openMap ( lat, lng ) {
	|			var location = new google.maps.LatLng ( lat, lng );
	|			var canvas = document.getElementById ( 'map' );
	|			var options = { center: location, zoom: %Zoom };
	|			gmap = new google.maps.Map ( canvas, options );
	|			Marker = new google.maps.Marker ( { position: location } );
	|			Marker.setMap ( gmap );
	|		}
	|
	|		function locateMap ( location ) {
	|			gmap.setCenter ( location );
	|			Marker.setPosition ( location );
	|		}
	|		function setZoom ( Zoom ) {
	|			gmap.setZoom ( parseInt ( Zoom ) );
	|		}
	|	</script>
	|</head>
	|<body>
	|<a style='position: fixed;top: 10px;right:10px;background-color: white;z-index: 1;padding: 5px;border: solid thin gray'
	|";
	if ( exactLocation ) then
		s = s + "
		|   href='https://maps.google.com/?q=%Latitude,%Longitude'";
	else
		s = s + "
		|   href='https://maps.google.com/?q=%Address'";
	endif; 
	s = s + "
	|   target='_blank'>%Link</a>
	|<div id='map' style='width: 100%;height: 100%'></div>
	|<script src='https://maps.googleapis.com/maps/api/js?callback=showMap&key=AIzaSyCosa70SuvRXZlc9Bevy5HlNd2TxIOIVQ0'></script>
	|</body>
	|</html>
	|";
	return Output.FormatStr ( s, p );
	
EndFunction 

Function getParams ( Latitude, Longitude, Address, Zoom )
	
	p = new Structure ( "ExactLocation, Address, Latitude, Longitude, Zoom, Link" );
	if ( Address = undefined ) then
		p.ExactLocation = true;
		modifier = "NDS=.; NZ=; NG=";
		p.Latitude = Format ( Latitude, modifier );
		p.Longitude = Format ( Longitude, modifier );
	else
		p.ExactLocation = false;
		p.Address = StrReplace ( StrReplace ( Address, """", " " ), "'", " " );
	endif; 
	p.Link = Output.OpenGoogleMaps ();
	p.Zoom = Format ( Zoom, "NZ=;" );
	return p;
	
EndFunction 

Function ByAddress ( Address, Zoom = 15 ) export
	
	return getHTML ( undefined, undefined, Address, Zoom );
	
EndFunction 

Procedure SetLocation ( Form, Control, Latitude, Longitude, Zoom ) export
	
	if ( needsUpdate ( Form, Control ) ) then
		Form.UpdateMap ();
	else
		webWindow = getWindow ( Control );
		if ( webWindow = undefined ) then
			return;
		else
			webWindow.navigateMap ( Latitude, Longitude );
		endif; 
	endif; 
	
EndProcedure 

Function needsUpdate ( Form, Control )
	
	#if ( WebClient ) then
		return Form [ Control.Name ] = "";
	#else
		return true;
	#endif
	
EndFunction 

Function getWindow ( Control )
	
	try
		document = Control.Document;
	except
		return undefined;
	endtry;
	if ( document = undefined ) then
		return undefined;
	endif; 
	return document.defaultView;
	
EndFunction 

Procedure SetZoom ( Form, Control, Zoom ) export
	
	if ( needsUpdate ( Form, Control ) ) then
		Form.UpdateMap ();
	else
		webWindow = getWindow ( Control );
		if ( webWindow = undefined ) then
			return;
		else
			webWindow.setZoom ( Zoom );
		endif; 
	endif; 
	
EndProcedure 

Procedure SetAddress ( Form, Control, Address, Zoom = 15 ) export
	
	if ( needsUpdate ( Form, Control ) ) then
		Form.UpdateMap ();
	else
		webWindow = getWindow ( Control );
		if ( webWindow = undefined ) then
			return;
		else
			webWindow.navigateMap ( Address );
		endif; 
	endif; 
	
EndProcedure 
