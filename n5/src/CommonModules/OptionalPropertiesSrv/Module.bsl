
Function GetOwner ( val Ref, val Folder, val Scope ) export
	
	if ( Scope = Enums.PropertiesScope.Groups ) then
		usage = "GroupsUsage";
	else
		usage = "ItemsUsage";
	endif; 
	s = "
	|select Items.Ref as Ref, Items.Parent as Parent, Items." + usage + " as Usage
	|from Catalog." + Folder.Metadata ().Name + " as Items
	|where Items.Ref = &Folder
	|";
	q = new Query ( s );
	q.SetParameter ( "Folder", Folder );
	special = Enums.PropertiesUsage.Special;
	while ( true ) do
		table = q.Execute ().Unload ();
		if ( table.Count () = 0 ) then
			return undefined;
		endif;
		data = table [ 0 ];
		if ( data.Usage = special ) then
			return data.Ref;
		endif; 
		q.SetParameter ( "Folder", data.Parent );
	enddo; 
	
EndFunction 
