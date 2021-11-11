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
	
	meta = Metadata.FindByType ( TypeOf ( Object.Ref ) );
	folder = Metadata.Catalogs.Contains ( meta )
	and meta.Hierarchical
	and meta.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems
	and Object.IsFolder;
	for each item in meta.Attributes do
		value = item.FillValue;			
		if ( ValueIsFilled ( value ) ) then
			use = item.Use;
			if ( folder ) then
				fits = use = Metadata.ObjectProperties.AttributeUse.ForFolderAndItem
					or use = Metadata.ObjectProperties.AttributeUse.ForFolder;
			else
				fits = use = Metadata.ObjectProperties.AttributeUse.ForFolderAndItem
					or use = Metadata.ObjectProperties.AttributeUse.ForItem;
			endif;
			if ( fits ) then
				Object [ item.Name ] = value;
			endif;
		endif;
	enddo;

EndProcedure

Function IsFolder ( Value ) export
	
	meta = Metadata.FindByType ( TypeOf ( value ) );
	folder = meta <> undefined
	and Metadata.Catalogs.Contains ( meta )
	and meta.Hierarchical
	and meta.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems
	and DF.Pick ( value, "IsFolder", false );
	return folder;

EndFunction
