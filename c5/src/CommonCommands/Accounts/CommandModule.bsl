
&AtClient
Procedure CommandProcessing ( Item, ExecuteParameters)
	
	p = new Structure ( "Item", Item );
	OpenForm ( formName ( Item ), p, ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );
	
EndProcedure

&AtClient
Function formName ( Item )
	
	type = TypeOf ( Item );
	if ( type = Type ( "CatalogRef.Items" ) ) then
		return "InformationRegister.ItemAccounts.ListForm";
	elsif ( type = Type ( "CatalogRef.Organizations" ) ) then
		return "InformationRegister.OrganizationAccounts.ListForm";
	elsif ( type = Type ( "CatalogRef.FixedAssets" ) ) then
		return "InformationRegister.FixedAssetAccounts.ListForm";
	elsif ( type = Type ( "CatalogRef.IntangibleAssets" ) ) then
		return "InformationRegister.IntangibleAssetAccounts.ListForm";
	endif; 
	
EndFunction 