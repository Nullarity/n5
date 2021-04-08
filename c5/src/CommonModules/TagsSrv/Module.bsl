Procedure Attach ( val Ref, val Tag ) export
	
	typeRef = TypeOf ( Ref );
	if ( typeRef = Type ( "CatalogRef.Projects" ) ) then
		r = InformationRegisters.ProjectTags.CreateRecordManager ();
		r.Project = Ref;
	else
		r = InformationRegisters.Tags.CreateRecordManager ();
		r.Document = Ref;
	endif; 
	r.Tag = Tag;
	r.Write ();
	Update ( Ref );
	
EndProcedure 

Procedure Update ( Ref ) export
	
	typeRef = TypeOf ( Ref );
	if ( typeRef = Type ( "CatalogRef.Projects" ) ) then
		s = "
		|select Tags.Tag.Description as Tag
		|from InformationRegister.ProjectTags as Tags
		|where Tags.Project = &Ref
		|order by Tags.Tag.Description
		|";
		r = InformationRegisters.ProjectSuperTags.CreateRecordManager ();
		r.Project = Ref;
	else
		s = "
		|select Tags.Tag.Description as Tag
		|from InformationRegister.Tags as Tags
		|where Tags.Document = &Ref
		|order by Tags.Tag.Description
		|";
		r = InformationRegisters.SuperTags.CreateRecordManager ();
		r.Document = Ref;
	endif;
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	result = q.Execute ().Unload ().UnloadColumn ( "Tag" );
	if ( result.Count () = 0 ) then
		r.Delete ();
	else
		r.Tags = StrConcat ( result, ", " );
		r.Write ();
	endif; 
	
EndProcedure 

Procedure Delete ( val Tag, val Ref ) export
	
	typeRef = TypeOf ( Ref );
	if ( typeRef = Type ( "CatalogRef.Projects" ) ) then
		r = InformationRegisters.ProjectTags.CreateRecordManager ();
		r.Project = Ref;
	else
		r = InformationRegisters.Tags.CreateRecordManager ();
		r.Document = Ref;
	endif;
	r.Tag = Tag;
	r.Delete ();
	Update ( Ref );
	
EndProcedure 
