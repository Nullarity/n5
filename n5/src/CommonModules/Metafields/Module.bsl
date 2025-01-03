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
	
	meta = Object.Metadata ();
	catalog = Metadata.Catalogs.Contains ( meta );
	folder = catalog
		and meta.Hierarchical
		and meta.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems
		and Object.IsFolder;	
	for each item in meta.Attributes do
		value = item.FillValue;			
		if ( value = undefined ) then
			continue;
		endif;
		if ( catalog ) then
			use = item.Use;
			if ( folder ) then
				if ( use = Metadata.ObjectProperties.AttributeUse.ForItem ) then
					continue;
				endif;
			else
				if ( use = Metadata.ObjectProperties.AttributeUse.ForFolder ) then
					continue;
				endif;
			endif;
		endif;
		Object [ item.Name ] = value;
	enddo;

EndProcedure

Function IsFolder ( Value ) export
	
	meta = Metadata.FindByType ( TypeOf ( value ) );
	if ( meta = undefined ) then
		return false;
	endif;
	if ( Metadata.Catalogs.Contains ( meta ) ) then
		folder = meta.Hierarchical
		and meta.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems
		and DF.Pick ( value, "IsFolder", false );
	elsif ( Metadata.ChartsOfAccounts.Contains ( meta ) ) then
		folder = DF.Pick ( value, "Folder", false );
	else
		folder = false;
	endif;
	return folder;

EndFunction

Function ToType ( Meta ) export
	
	if ( Metadata.Catalogs.Contains ( Meta ) ) then
		class = "CatalogRef";
	elsif (  Metadata.BusinessProcesses.Contains ( Meta ) ) then
		class = "BusinessProcessRef";
	elsif ( Metadata.ChartsOfAccounts.Contains ( Meta ) ) then
		class = "ChartOfAccountsRef";
	elsif ( Metadata.ChartsOfCalculationTypes.Contains ( Meta ) ) then
		class = "ChartOfCalculationTypesRef";
	elsif ( Metadata.ChartsOfCharacteristicTypes.Contains ( Meta ) ) then
		class = "ChartOfCharacteristicTypesRef";
	elsif ( Metadata.Documents.Contains ( Meta ) ) then
		class = "DocumentRef";
	elsif ( Metadata.Tasks.Contains ( Meta ) ) then
		class = "TaskRef";
	elsif ( Metadata.ExchangePlans.Contains ( Meta ) ) then
		class = "ExchangePlanRef";
	endif; 
	return Type ( class + "." + Meta.Name );

EndFunction
