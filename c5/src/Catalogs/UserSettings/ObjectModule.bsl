var User;
var DataPath;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	setUser ();
	if ( not checkCompany () ) then
		Cancel = true;
	endif; 
	if ( not checkWarehouse () ) then
		Cancel = true;
	endif; 

EndProcedure

Procedure setUser ()
	
	var userForm;
	 
	if ( AdditionalProperties.Property ( Enum.AdditionalPropertiesWritingUser (), userForm ) ) then
		DataPath = userSettings ( userForm );
		User = userForm.Object;
	else
		DataPath = "Object";
		User = getUser ();
	endif;
	
EndProcedure

Function userSettings ( Form )
	
	s = Form.Items.Company.DataPath;
	return Left ( s, StrFind ( s, "." ) - 1 );
	
EndFunction

Function getUser ()
	
	s = "
	|select Users.CompanyAccess as CompanyAccess, Users.WarehouseAccess as WarehouseAccess,
	|	Users.Companies as Companies, Users.Warehouses as Warehouses
	|from Catalog.Users as Users
	|where Users.Ref = &Ref";
	q = new Query ( s );
	q.SetParameter ( "Ref", Owner );
	data = q.Execute ().Unload ();
	result = new Structure ( "Ref, CompanyAccess, WarehouseAccess, Companies, Warehouses", Ref );
	FillPropertyValues ( result, data [ 0 ] );
	return result;
	
EndFunction

Function checkCompany ()
	
	if ( User.CompanyAccess = Enums.Access.Undefined ) then
		return true;
	elsif ( User.CompanyAccess = Enums.Access.Allow ) then
		if ( companyInList () ) then
			return true;
		else
			Output.DefaultCompanyError1 ( , "Company", User.Ref, DataPath );
			return false;
		endif;
	elsif ( User.CompanyAccess = Enums.Access.Forbid ) then
		if ( companyInList () ) then
			Output.DefaultCompanyError2 ( , "Company", User.Ref, DataPath );
			return false;
		else
			return true;
		endif;
	endif; 
	
EndFunction 

Function companyInList ()
	
	return User.Companies.FindRows ( new Structure ( "Company", Company ) ).Count () > 0;
	
EndFunction 

Function checkWarehouse ()
	
	if ( User.WarehouseAccess = Enums.Access.Undefined ) then
		return true;
	elsif ( User.WarehouseAccess = Enums.Access.Allow ) then
		if ( warehouseInList () ) then
			return true;
		else
			Output.DefaultWarehouseError1 ( , "Warehouse", User.Ref, DataPath );
			return false;
		endif;
	elsif ( User.WarehouseAccess = Enums.Access.Forbid ) then
		if ( warehouseInList () ) then
			Output.DefaultWarehouseError2 ( , "Warehouse", User.Ref, DataPath );
			return false;
		else
			return true;
		endif;
	elsif ( User.WarehouseAccess = Enums.Access.States ) then
		if ( warehouseStateInList () ) then
			return true;
		else
			Output.DefaultWarehouseError3 ( , "Warehouse", User.Ref, DataPath );
			return false;
		endif;
	elsif ( User.WarehouseAccess = Enums.Access.Directly ) then
		if ( Warehouse.IsEmpty ()
			or DF.Pick ( Warehouse, "Responsible" ) = User.Ref ) then
			return true;
		else
			Output.DefaultWarehouseError4 ( , "Warehouse", User.Ref, DataPath );
			return false;
		endif;
	endif; 
	
EndFunction 

Function warehouseInList ()
	
	return User.Warehouses.FindRows ( new Structure ( "Warehouse", Warehouse ) ).Count () > 0;
	
EndFunction 

Function warehouseStateInList ()
	
	state = DF.Pick ( Warehouse, "Address.State" );
	return User.WarehousesStates.FindRows ( new Structure ( "State", state ) ).Count () > 0;
	
EndFunction 
