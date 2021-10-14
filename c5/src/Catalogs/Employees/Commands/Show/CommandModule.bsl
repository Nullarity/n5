
&AtClient
Procedure CommandProcessing ( Employee, ExecuteParameters )

	params = new Structure ( "Key", Employee );
	if ( TypeOf ( Employee ) = Type ( "CatalogRef.Employees" ) ) then
		form = "Catalog.Employees.ObjectForm";
	else
		form = "Catalog.Individuals.ObjectForm";
	endif;
	OpenForm ( form, params,
		ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );
	
EndProcedure
