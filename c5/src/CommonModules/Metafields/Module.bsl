Function Exists ( Ref, Field ) export

	fieldAndTable = getTableAndFieldName ( Field );
	meta = Ref.Metadata ();
	if ( fieldAndTable.Table <> undefined ) then
		meta = meta.TabularSections [ fieldAndTable.Table ];
	endif; 
	return meta.Attributes.Find ( fieldAndTable.Field ) <> undefined;

EndFunction

Function getTableAndFieldName ( Field )
	
	parts = Conversion.StringToArray ( Field, "." );
	result = new Structure ( "Table, Field" );
	if ( parts.Count () = 1 ) then
		result.Insert ( "Field", parts [ 0 ] );
	else
		result.Insert ( "Table", parts [ 0 ] );
		result.Insert ( "Field", parts [ 1 ] );
	endif; 
	return result;
	
EndFunction 

Procedure Constructor ( Object ) export
	
	for each item in Object.Ref.Metadata ().Attributes do
		value = item.FillValue;			
		if ( value <> undefined ) then
			Object [ item.Name ] = value;
		endif;
	enddo;

EndProcedure
