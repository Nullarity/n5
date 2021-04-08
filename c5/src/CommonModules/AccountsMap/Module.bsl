
Function Item ( Item, Company, Warehouse, Resources ) export

	return getByTale ( Item, Company, Warehouse, "ItemAccounts", "Item", true, Resources );

EndFunction

Function getByTale ( Value, Company, Warehouse = undefined, Table, Dimension, Hierarchical, Resources )
	
	p = new Structure ();
	p.Insert ( "Value", Value );
	p.Insert ( "Company", Company );
	p.Insert ( "Warehouse", Warehouse );
	p.Insert ( "WarehouseExists", ( Warehouse <> undefined ) );
	p.Insert ( "RegisterName", Table );
	p.Insert ( "Dimension", Dimension );
	p.Insert ( "Resources", Resources );
	p.Insert ( "ResourcesArray", new Array () );
	p.Insert ( "Result", new Structure () );
	p.Insert ( "Hierarchical", Hierarchical );
	prepareResult ( p );
	prepareTable ( p );
	completeResult ( p );
	return p.Result;

EndFunction

Procedure prepareResult ( Params )
	
	resourcesMeta = Metadata.InformationRegisters [ Params.RegisterName ].Resources;
	Params.ResourcesArray = Conversion.StringToArray ( Params.Resources );
	for each resource in Params.ResourcesArray do
		Params.Result.Insert ( resource, resourcesMeta [ resource ].Type.AdjustValue () );
	enddo; 
	
EndProcedure

Procedure prepareTable ( Params )
	
	s = "
	|select allowed Company" + ? ( Params.WarehouseExists, ", Warehouse", "" ) + ", " + Params.Dimension + ", " + Params.Resources + "
	|from InformationRegister." + Params.RegisterName + "
	|where " + Params.Dimension + " in ( &ValueArray )
	|and Company in ( &Company, value ( Catalog.Companies.EmptyRef ) )
	|";
	if ( Params.WarehouseExists ) then
		s = s + "and Warehouse in ( &Warehouse, value ( Catalog.Warehouses.EmptyRef ) )";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Company", Params.Company );
	q.SetParameter ( "Warehouse", Params.Warehouse );
	q.SetParameter ( "ValueArray", getValues ( Params ) );
	Params.Insert ( "Values", q.Execute ().Unload () );
	
EndProcedure

Function getValues ( Params )
	
	values = new Array;
	values.Add ( Params.Value );
	values.Add ( undefined );
	if ( Params.Value <> undefined ) then
		valueType = TypeOf ( Params.Value );
		if ( valueType = Type ( "CatalogRef.Items" ) ) then
			values.Add ( Catalogs.Items.EmptyRef () );
		elsif ( valueType = Type ( "CatalogRef.Organizations" ) ) then
			values.Add ( Catalogs.Organizations.EmptyRef () );
		elsif ( valueType = Type ( "CatalogRef.FixedAssets" ) ) then
			values.Add ( Catalogs.FixedAssets.EmptyRef () );
		elsif ( valueType = Type ( "CatalogRef.IntangibleAssets" ) ) then
			values.Add ( Catalogs.IntangibleAssets.EmptyRef () );
		endif; 
	endif; 
	if ( Params.Hierarchical ) then
		maxLevel = ? ( not ValueIsFilled ( Params.Value ), 1, Params.Value.Level () );
		parent = Params.Value.Parent;
		i = maxLevel;
		while ( i > 0 ) do
			values.Add ( parent );
			parent = DF.Pick ( parent, "Parent" );
			i = i - 1;
		enddo; 
	endif; 
	return values;
	
EndFunction 

Procedure completeResult ( Params )
	
	priorities = new Map ();
	for each resource in Params.ResourcesArray do
		priorities [ resource ] = new Structure ( "Value, Amount", undefined, -1 );
		for each row in Params.Values do
			if ( not ValueIsFilled ( row [ resource ] ) ) then
				continue;
			endif; 
			amount = 0;
			if ( ValueIsFilled ( row [ Params.Dimension ] ) ) then
				if ( Params.Hierarchical ) then
					amount = amount + ( row [ Params.Dimension ].Level () + 1 ) * 100;
				else
					amount = amount + 100;
				endif;
			endif; 
			if ( Params.WarehouseExists ) then
				if ( ValueIsFilled ( row.Warehouse ) ) then
					amount = amount + 10;
				endif; 
			endif; 
			if ( ValueIsFilled ( row.Company ) ) then
				amount = amount + 1;
			endif; 
			if ( priorities [ resource ].Amount < amount ) then
				priorities [ resource ].Value = row [ resource ];
				priorities [ resource ].Amount = amount;
				Params.Result [ resource ] = row [ resource ];
			endif; 
		enddo;
	enddo; 
	
EndProcedure

Function Organization ( Organization, Company, Resources ) export
	
	return getByTale ( Organization, Company, , "OrganizationAccounts", "Organization", true, Resources );

EndFunction

Function FixedAsset ( Asset, Company, Resources ) export
	
	return getByTale ( Asset, Company, , "FixedAssetAccounts", "Asset", true, Resources );

EndFunction

Function IntangibleAsset ( Asset, Company, Resources ) export
	
	return getByTale ( Asset, Company, , "IntangibleAssetAccounts", "Asset", true, Resources );

EndFunction
