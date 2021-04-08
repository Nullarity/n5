Function GetParams ( val Type, val Composer ) export
	
	if ( Composer = undefined ) then
		values = undefined;
	else
		values = new Structure ();
		fillValues ( values, Composer.GetSettings ().Filter.Items );
	endif; 
	form = Metadata.FindByType ( Type ).FullName () + ".ObjectForm";
	return new Structure ( "Form, FillingValues", form, values );

EndFunction

Procedure fillValues ( Values, Items )

	filterType = Type ( "DataCompositionFilterItem" );
	groupType = Type ( "DataCompositionFilterItemGroup" );
	for each item in Items do
		type = TypeOf ( item );
		if ( type = filterType
			and item.Use 
			and item.ComparisonType = DataCompositionComparisonType.Equal ) then
			Values.Insert ( String ( item.LeftValue ), item.RightValue );
		elsif ( type = groupType
			 and item.User ) then
		    fillValues ( Values, item );
		endif;
	enddo;

EndProcedure
