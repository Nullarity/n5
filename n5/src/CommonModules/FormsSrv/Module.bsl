
Function ItemTitles ( val Form, val Items ) export
	
	titles = new Array ();
	meta = Metadata.FindByFullName ( Form );
	if ( Metadata.CommonForms.Contains ( meta ) ) then
		attributes = Metadata.Constants;
	else
		attributes = meta.Parent ().Attributes;
	endif;
	for each item in Items do
		titles.Add ( attributes [ item ].Presentation () );
	enddo; 
	return titles;
	
EndFunction

Function FindPage ( Item ) export
	
	type = TypeOf ( Item );
	if ( type = Type ( "FormGroup" )
		and Item.Type = FormGroupType.Page ) then
		return Item;
	elsif ( type = Type ( Enum.FrameworkManagedForm () ) ) then
		return undefined;
	else
		return findPage ( Item.Parent );
	endif; 
	
EndFunction 
