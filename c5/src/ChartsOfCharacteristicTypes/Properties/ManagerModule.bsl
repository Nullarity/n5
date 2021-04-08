#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )

	StandardProcessing = false;
	Fields.Add ( "Description" );
	Fields.Add ( "Owner" );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	owner = Data.Owner;
	if ( owner = undefined ) then
		Presentation = Data.Description;
	else
		Presentation = Data.Description + " (" + owner + ")";
	endif;
	
EndProcedure

#endif

Procedure ChoiceDataGetProcessing ( ChoiceData, Parameters, StandardProcessing )

	filter = Parameters.Filter;
	if ( filterByOwner ( filter ) ) then
		replaceToReferences ( filter );
	endif;

EndProcedure

Function filterByOwner ( Filter )
	
	return Filter.Property ( "Owner" )
	and Filter.Property ( "Scope" );
	
EndFunction

Procedure replaceToReferences ( Filter )
	
	Filter.Insert ( "Ref", getProperties ( Filter ) );
	Filter.Delete ( "Scope" );
	Filter.Delete ( "Owner" );
	
EndProcedure

Function getProperties ( Filter )
	
	s = "
	|select Properties.Ref as Ref
	|from ChartOfCharacteristicTypes.Properties as Properties
	|where not Properties.DeletionMark
	|and not Properties.IsFolder
	|and Properties.Owner = &Owner
	|and Properties.Scope = &Scope
	|union all
	|select Properties.Property
	|from InformationRegister.CommonProperties as Properties
	|where Properties.Owner = &Owner
	|and Properties.Scope = &Scope
	|and not Properties.Property.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Owner", Filter.Owner );
	q.SetParameter ( "Scope", Filter.Scope );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction