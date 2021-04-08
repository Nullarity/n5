// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	OldName = Object.Description;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Object.IsFolder ) then
		return;
	endif;
	if ( OldName <> "" and OldName <> Object.Description ) then
		updateTags ();
	endif; 
	
EndProcedure

&AtServer
Procedure updateTags ()
	
	var labels;
	
	SetPrivilegedMode ( true );
	table = getObjects ();
	if ( table.Count () = 0 ) then
		SetPrivilegedMode ( false );
		return;
	endif; 
	ref = undefined;
	for each row in table do
		if ( row.Ref <> ref ) then
			if ( ref <> undefined ) then
				update ( ref, labels );
			endif; 
			labels = new Array ();
			ref = row.Ref;
		endif; 
		labels.Add ( row.Tag );
	enddo; 
	update ( ref, labels );
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Function getObjects ()
	
	s = "
	|select Tags.Document as Document
	|into Documents
	|from InformationRegister.Tags as Tags
	|where Tags.Tag = &Tag
	|index by Document
	|;
	|select Tags.Project as Project
	|into Projects
	|from InformationRegister.ProjectTags as Tags
	|where Tags.Tag = &Tag
	|index by Project
	|;
	|select Tags.Tag.Description as Tag, Tags.Document as Ref
	|from InformationRegister.Tags as Tags
	|where Tags.Document in ( select Document from Documents )
	|union all
	|select Tags.Tag.Description, Tags.Project
	|from InformationRegister.ProjectTags as Tags
	|where Tags.Project in ( select Project from Projects )
	|order by Ref, Tag
	|";
	q = new Query ( s );
	q.SetParameter ( "Tag", Object.Ref );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure update ( Ref, Labels )
	
	refType = TypeOf ( Ref );
	if ( refType = Type ( "CatalogRef.Projects" ) ) then
		r = InformationRegisters.ProjectSuperTags.CreateRecordManager ();
		r.Project = Ref;
	else
		r = InformationRegisters.SuperTags.CreateRecordManager ();
		r.Document = Ref;
	endif; 
	r.Tags = StrConcat ( Labels, ", " );
	r.Write ();
	
EndProcedure 
