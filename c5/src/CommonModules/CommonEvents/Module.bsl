
Procedure CheckDoubles ( Source, Cancel, CheckedAttributes ) export
	
	type = TypeOf ( Source ); 
	if ( not isSystem ( type ) ) then
		if ( IsInRole ( Metadata.Roles.DoublesAllowed ) ) then
			return;
		endif; 
	endif;
	if ( exception ( type ) ) then
		return;
	endif;
	searchEverywhere ( type );
	original = DF.GetOriginal ( Source.Ref, "Description", Source.Description, getOwner ( Source ) );
	if ( original = undefined ) then
		return;
	endif; 
	Cancel = true;
	Output.ObjectNotOriginal ( new Structure ( "Value", Source.Description ), "Description" );
	
EndProcedure

Function isSystem ( Type )

	return Type = Type ( "CatalogObject.Membership" );
	
EndFunction

Procedure searchEverywhere ( Type )
	
	no = Type = Type ( "CatalogObject.Membership" );
	if ( no ) then
		return;
	endif;
	SetPrivilegedMode ( true );
	
EndProcedure

Function exception ( Type )
	
	return Type = Type ( "CatalogObject.Individuals" )
	or Type = Type ( "CatalogObject.AssetTypes" )
	or Type = Type ( "CatalogObject.Education" )
	or Type = Type ( "CatalogObject.ItemKeys" )
	or Type = Type ( "CatalogObject.Lots" )
	or Type = Type ( "CatalogObject.PaymentKeys" )
	or Type = Type ( "CatalogObject.PromoCodes" )
	or Type = Type ( "CatalogObject.RowKeys" )
	or Type = Type ( "CatalogObject.UserSettings" )
	or Type = Type ( "CatalogObject.ReportSettings" )
	or Type = Type ( "CatalogObject.Reports" )
	or Type = Type ( "CatalogObject.Metadata" )
	or Type = Type ( "CatalogObject.Holidays" )
	or Type = Type ( "CatalogObject.Departments" )
	or Type = Type ( "CatalogObject.Constants" )
	or Type = Type ( "CatalogObject.Books" )
	or Type = Type ( "CatalogObject.Leads" )
	or Type = Type ( "CatalogObject.Sessions" );

EndFunction 

Function getOwner ( Source )
	
	meta = Source.Metadata ();
	if ( Metadata.Catalogs.Contains ( meta )
		and meta.Owners.Count () > 0 ) then
		return Source.Owner;
	else
		return undefined;
	endif; 

EndFunction 
