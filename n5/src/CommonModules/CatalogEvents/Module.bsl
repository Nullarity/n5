
Procedure Prefix ( Source, StandardProcessing, Prefix ) export
	
	if ( exception ( Source ) ) then
		return;
	endif; 
	px = nodePrefix ();
	if ( px = "" ) then
		return;
	endif;
	Prefix = px;
	
EndProcedure

Function exception ( Source )
	
	type = TypeOf ( Source );
	return
		type = Type ( "CatalogObject.Units" )
		or type = Type ( "CatalogObject.TaxCodes" )
		or type = Type ( "CatalogObject.Users" )
		or type = Type ( "CatalogObject.Membership" )
		or type = Type ( "CatalogObject.Tenants" )
		or type = Type ( "CatalogObject.Currencies" )
		or type = Type ( "CatalogObject.RowKeys" )
		or type = Type ( "CatalogObject.Salutations" )
		or type = Type ( "CatalogObject.Banks" )
		or type = Type ( "CatalogObject.DeductionsClassifier" )
		or type = Type ( "ChartOfCharacteristicTypesObject.Settings" )
		or type = Type ( "CatalogObject.Divisions" )
		or type = Type ( "CatalogObject.Positions" )
		or type = Type ( "CatalogObject.PositionsClassifier" )
		or type = Type ( "CatalogObject.Numeration" )
		or type = Type ( "CatalogObject.States" )
		or type = Type ( "CatalogObject.Cities" )
		or type = Type ( "CatalogObject.Calendar" );
	
EndFunction 

Function nodePrefix ()
	
	return Application.Prefix ();
	
EndFunction

Function GetPrefix ( Object ) export
	
	if ( exception ( Object ) ) then
		return "";
	else
		return nodePrefix ();
	endif;
	
EndFunction