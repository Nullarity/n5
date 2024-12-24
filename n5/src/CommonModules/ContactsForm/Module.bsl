&AtClient
Procedure AdjustTwitter ( Object ) export
	
	Object.Twitter = TrimAll ( Object.Twitter );
	if ( Object.Twitter = "" ) then
		return;
	endif;
	if ( Left ( Object.Twitter, 1 ) <> "@" ) then
		Object.Twitter = "@" + Object.Twitter;
	endif;
	
EndProcedure

Function FullName ( Object ) export
	
	parts = new Array ();
	value = Object.LastName;
	if ( not IsBlankString ( value ) ) then
		parts.Add ( value );
	endif; 
	parts.Add ( Object.FirstName );
	value = Object.Patronymic;
	if ( not IsBlankString ( value ) ) then
		parts.Add ( value );
	endif; 
	return StrConcat ( parts, " " );
	
EndFunction 

Procedure SetAddress ( Object ) export
	
	parts = new Array ();
	country = Object.Country;
	if ( country <> Application.Country () ) then
		value = "" + country; 
		if ( not IsBlankString ( value ) ) then
			parts.Add ( value );
		endif; 
	endif;
	value = Object.Zip;
	if ( not IsBlankString ( value ) ) then
		parts.Add ( value );
	endif; 
	city = "" + Object.City;
	value = "" + Object.State;
	if ( not IsBlankString ( value )
		and Lower ( value ) <> Lower ( city ) ) then
		parts.Add ( value );
	endif;
	value = Title ( Object.Municipality );
	if ( not IsBlankString ( value ) ) then
		Object.Municipality = value;
		parts.Add ( Output.Municipality () + value );
	endif; 
	if ( not IsBlankString ( city ) ) then
		parts.Add ( city );
	endif; 
	value = Title ( Object.Street );
	if ( not IsBlankString ( value ) ) then
		Object.Street = value;
		parts.Add ( Output.Street () + " " + value );
		value = Object.Number;
		if ( not IsBlankString ( value ) ) then
			parts.Add ( value );
		endif; 
		value = Object.Building;
		if ( not IsBlankString ( value ) ) then
			parts.Add ( Output.Building () + value );
		endif; 
		value = Object.Entrance;
		if ( not IsBlankString ( value ) ) then
			parts.Add ( Output.Entrance () + value );
		endif; 
		value = Object.Floor;
		if ( not IsBlankString ( value ) ) then
			parts.Add ( Output.Floor () + value );
		endif; 
		value = Object.Apartment;
		if ( not IsBlankString ( value ) ) then
			parts.Add ( Output.Apartment () + value );
		endif; 
	endif;
	Object.Address = StrConcat ( parts, ", " );
	
EndProcedure

&AtClient
Procedure ZIPMask ( Form ) export
	
	zip = Form.Object.ZIPFormat;
	control = Form.Items.ZIP;
	if ( zip = PredefinedValue ( "Enum.ZIP.Canada" ) ) then
		control.Mask = "!!!-!!!";
	elsif ( zip = PredefinedValue ( "Enum.ZIP.US1" ) ) then
		control.Mask = "99999";
	elsif ( zip = PredefinedValue ( "Enum.ZIP.US2" ) ) then
		control.Mask = "99999-9999";
	elsif ( zip = PredefinedValue ( "Enum.ZIP.Moldova" ) ) then
		control.Mask = "MD-9999";
	else
		control.Mask = "";
	endif; 
	
EndProcedure 

Procedure SetZIPFormat ( Object ) export
	
	country = Object.Country;
	if ( not country.IsEmpty () ) then
		Object.ZIPFormat = DF.Pick ( country, "ZIPFormat" );
	endif;
	
EndProcedure

&AtServer
Procedure SetCountry ( Object ) export
	
	if ( Object.Country.IsEmpty () ) then
		Object.Country = Application.Country ();
	endif;
	
EndProcedure
