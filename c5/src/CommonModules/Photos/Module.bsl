&AtServer
Procedure Load ( Form ) export
	
	ref = Form.Object.Ref;
	type = TypeOf ( ref );
	if ( type = Type ( "CatalogRef.Individuals" ) ) then
		data = InformationRegisters.Photos.Get ( new Structure ( "Individual", ref ) ).Photo.Get ();
	elsif ( type = Type ( "CatalogRef.Leads" ) ) then
		data = InformationRegisters.LeadPhotos.Get ( new Structure ( "Lead", ref ) ).Photo.Get ();
	elsif ( type = Type ( "CatalogRef.Companies" ) ) then
		data = InformationRegisters.CompanyLogos.Get ( new Structure ( "Company", ref ) ).Logo.Get ();
	else
		data = InformationRegisters.ContactPhotos.Get ( new Structure ( "Contact", ref ) ).Photo.Get ();
	endif;
	if ( data = undefined ) then
		Form.Photo = undefined;
	else
		Form.Photo = PutToTempStorage ( data );
	endif; 
	Form.NewPhoto = false;
	
EndProcedure 

&AtServer
Procedure Save ( Form, CurrentObject ) export
	
	if ( not Form.NewPhoto ) then
		return;
	endif;
	ref = CurrentObject.Ref;
	photo = Form.Photo;
	data = ? ( photo = "", undefined, new ValueStorage ( GetFromTempStorage ( photo ) ) );
	type = TypeOf ( ref );
	if ( type = Type ( "CatalogRef.Individuals" ) ) then
		r = InformationRegisters.Photos.CreateRecordManager ();
		r.Individual = ref;
		r.Photo = data;
	elsif ( type = Type ( "CatalogRef.Leads" ) ) then
		r = InformationRegisters.LeadPhotos.CreateRecordManager ();
		r.Lead = ref;
		r.Photo = data;
	elsif ( type = Type ( "CatalogRef.Companies" ) ) then
		r = InformationRegisters.CompanyLogos.CreateRecordManager ();
		r.Company = ref;
		r.Logo = data;
	else
		r = InformationRegisters.ContactPhotos.CreateRecordManager ();
		r.Contact = ref;
		r.Photo = data;
	endif;
	if ( photo = "" ) then
		r.Delete ();
	else
		r.Write ();
	endif; 
	Form.NewPhoto = false;
	
EndProcedure 

&AtClient
Procedure Upload ( Form ) export
	
	callback = new NotifyDescription ( "CompleteUpload", ThisObject, Form );
	Images.Load ( callback, Form.UUID );
	
EndProcedure 

&AtClient
Procedure CompleteUpload ( Result, Form ) export
	
	Form.Photo = Result.Picture;
	Form.Modified = true;
	Form.NewPhoto = true;
	Appearance.Apply ( Form, "Photo" );

EndProcedure 

&AtClient
Procedure Remove ( Form ) export
	
	Form.Photo = "";
	Form.Modified = true;
	Form.NewPhoto = true;
	Appearance.Apply ( Form, "Photo" );
	
EndProcedure 
