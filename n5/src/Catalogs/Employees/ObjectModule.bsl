#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Check () export
	
	fields = mandatoryFields ();
	checkContractor ( fields );
	if ( not checkFields ( fields ) ) then
		return false;
	endif; 
	if ( not PhoneTemplates.Check ( ThisObject, "BusinessPhone, Fax" ) ) then
		return false;
	endif; 
	return true;
	
EndFunction 

Function mandatoryFields ()
	
	fields = new Array ();
	yes = FillChecking.ShowError;
	for each item in Metadata.Catalogs.Employees.Attributes do
		if ( item.FillChecking = yes ) then
			fields.Add ( item );
		endif;
	enddo; 
	return fields;
	
EndFunction 

Procedure checkContractor ( Fields )
	
	if ( EmployeeType = Enums.EmployeeTypes.Contractor ) then
		Fields.Add ( Metadata.Catalogs.Employees.Attributes.Contractor );
	endif; 
	
EndProcedure 

Function checkFields ( Fields )
	
	errors = findErrors ( Fields );
	if ( errors.Count () = 0 ) then
		return true;
	endif;
	for each error in errors do
		Output.FieldIsEmpty ( new Structure ( "Field", error.Presentation () ), error.Name, , "Employee" );
	enddo;
	return false;
	
EndFunction 

Function findErrors ( Fields )
	
	errors = new Array ();
	for each field in Fields do
		if ( not ValueIsFilled ( ThisObject [ field.Name ] ) ) then
			errors.Add ( field );
		endif; 
	enddo; 
	return errors;
	
EndFunction 

#endif