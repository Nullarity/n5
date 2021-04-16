
Procedure SessionParametersSetting ( Params )
	
	if ( Params = undefined ) then
		return;
	endif; 
	for each parameter in Params do
		if ( parameter = "User" ) then
			setUser ();
		elsif ( parameter = "Login" ) then
			setLogin ();
		elsif ( parameter = "Employee" ) then
			setEmployee ();
		elsif ( parameter = "OrganizationAccess" ) then
			setOrganizationAccess ();
		elsif ( parameter = "CompanyAccess" ) then
			setCompanyAccess ();
		elsif ( parameter = "WarehouseAccess" ) then
			setWarehouseAccess ();
		elsif ( parameter = "UserClass" ) then
			setUserClass ();
		elsif ( parameter = "CanViewCustomers" ) then
			setCanViewCustomers ();
		elsif ( parameter = "CanViewVendors" ) then
			setCanViewVendors ();
		elsif ( parameter = "Session" ) then
			setSession ();
		elsif ( parameter = "License" ) then
			setLicense ();
		endif;
	enddo; 
	
EndProcedure

Procedure setUser ()
	
	name = UserName ();
	currentUser = Catalogs.Users.FindByDescription ( name );
	if ( currentUser.IsEmpty () ) then
		if ( Logins.Sysadmin () ) then
			currentUser = Constants.MainUser.Get ();
		else
			error = new Structure ( "User, Tenant", name, Cloud.GetTenantCode () );
			raise Output.AuthorizationError ( error );
		endif;
	endif;
	SessionParameters.User = currentUser;
	
EndProcedure 

Procedure setLogin ()
	
	SessionParameters.Login = DF.Pick ( SessionParameters.User, "Login" );
	
EndProcedure 

Procedure setEmployee ()
	
	SessionParameters.Employee = DF.Pick ( SessionParameters.User, "Employee" );
	
EndProcedure 

Procedure setOrganizationAccess ()
	
	SessionParameters.OrganizationAccess = DF.Pick ( SessionParameters.User, "OrganizationAccess" );
	
EndProcedure 

Procedure setCompanyAccess ()
	
	SessionParameters.CompanyAccess = DF.Pick ( SessionParameters.User, "CompanyAccess" );
	
EndProcedure 

Procedure setWarehouseAccess ()
	
	SessionParameters.WarehouseAccess = DF.Pick ( SessionParameters.User, "WarehouseAccess" );
	
EndProcedure 

Procedure setUserClass ()
	
	SessionParameters.UserClass = DF.Pick ( SessionParameters.User, "UserClass" );
	
EndProcedure 

Procedure setCanViewCustomers ()
	
	SessionParameters.CanViewCustomers = IsInRole ( "CustomersView" ) or IsInRole ( "CustomersEdit" );
	
EndProcedure 

Procedure setCanViewVendors ()
	
	SessionParameters.CanViewVendors = IsInRole ( "VendorsView" ) or IsInRole ( "VendorsEdit" );
	
EndProcedure 

Procedure setSession ()
	
	StartingSrv.NewSession ( ComputerName (), false, false, false, false, false );
	
EndProcedure 

Procedure setLicense ()
	
	//@skip-warning
	module ().SetLicense ( "ь-Я0905-\#4я<Xю!9!W2+45цюb4Юb-Э615Я1э0ю1604" );

EndProcedure

Function module ()
	
	return CoreExtension;
	
EndFunction