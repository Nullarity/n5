Function Get ( Color ) export
	
	s = "" + Color;
	a = Find ( s, "(" );
	s = Mid ( s, a + 1 );
	a = Find ( s, ")" );
	s = Mid ( s, 1, a - 1 );
	return TrimAll ( s );
	
EndFunction 

&AtClient
Procedure ChooseColor ( Item, CurrentColor = undefined, TwoColors = false ) export
	
	OpenForm ( "DataProcessor.Colors.Form", new Structure ( "CurrentColor, TwoColors", CurrentColor, TwoColors ), Item );
	
EndProcedure 

&AtServer
Function Deserialize ( SerializedColor, ReturnColorName = false ) export
	
	color = undefined;
	try
		color = XMLValue ( Type ( "ValueStorage" ), SerializedColor ).Get ();
	except
	endtry;
	if ( color = undefined ) then
		return ? ( ReturnColorName, "Black", new Color () );
	else
		return ? ( ReturnColorName, Colors.Get ( color ), color );
	endif; 
		
EndFunction 
