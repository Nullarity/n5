#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )
	
	if ( FormType = "ObjectForm" ) then
		if ( individualAllowed ( Parameters ) ) then
			StandardProcessing = false;
			openIndividual ( Parameters, SelectedForm );
		endif; 
	endif; 
	
EndProcedure

Function individualAllowed ( Params )
	
	if ( Params.Property ( "IsFolder" )
		and Params.IsFolder ) then
		return false;
	endif; 
	if ( not AccessRight ( "View", Metadata.Catalogs.Individuals ) ) then
		return false;
	endif; 
	return true;

EndFunction 

Procedure openIndividual ( Params, SelectedForm )
	
	employee = undefined;
	copy = undefined;
	if ( Params.Property ( "Key", employee ) ) then
		individual = DF.Pick ( employee, "Individual" );
		Params.Insert ( "Key", individual );
		Params.Insert ( "Employee", employee );
	endif; 
	if ( Params.Property ( "CopyingValue", copy ) ) then
		Params.Insert ( "Copy", copy );
	endif; 
	Params.Insert ( "Redirected", true );
	SelectedForm = Metadata.Catalogs.Individuals.Forms.Form;

EndProcedure 

Procedure Update ( Object, Individual ) export
	
	FillPropertyValues ( Object, Individual, "Email, FirstName, HomePhone, FirstName, LastName, MobilePhone, Patronymic, Gender, Web" );
	Object.Description = Individual.Description + ? ( Object.Notes = "", "", ", " + Object.Notes );
	
EndProcedure 

#endif