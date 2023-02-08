
Function NewTenantGet ( Request )
	
	params = DataProcessors.CreateTenant.GetParams ();
	FillPropertyValues ( params, Conversion.MapToStruct ( Request.QueryOptions ) );
	result = DataProcessors.CreateTenant.Enroll ( params );
	response = new HTTPServiceResponse ( 200 );
	response.SetBodyFromString ( Conversion.ToJSON ( result ) );
	return response;
	
EndFunction
