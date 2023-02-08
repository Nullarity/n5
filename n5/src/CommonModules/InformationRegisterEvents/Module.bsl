
Procedure OpenGalleryFormGetProcessing ( Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing ) export
	
	if ( Parameters.Property ( "Filter" ) ) then
		StandardProcessing = false;
		SelectedForm = Metadata.CommonForms.Gallery;
	endif; 
	
EndProcedure
