&AtClient
Procedure Attach ( Ref, TagRow, OldTag ) export
	
	if ( OldTag = TagRow.Tag
		or Ref.IsEmpty () ) then
		return;
	endif; 
	if ( not TagRow.Tag.IsEmpty () ) then
		TagsSrv.Attach ( Ref, TagRow.Tag );
	endif;
	if ( not OldTag.IsEmpty ()
		and OldTag <> TagRow.Tag ) then
		TagsSrv.Delete ( OldTag, Ref );
	endif; 
	
EndProcedure 

&AtClient
Procedure Delete ( Ref, Control, Table ) export
	
	if ( Ref.IsEmpty () ) then
		return;
	endif; 
	for each row in Control.SelectedRows do
		data = Control.RowData ( row );
		if ( tagExists ( data.Tag, Table )
			or data.Tag.IsEmpty () ) then
			return;
		endif; 
		TagsSrv.Delete ( data.Tag, Ref );
	enddo; 
	
EndProcedure 

&AtClient
Function tagExists ( Tag, Table )
	
	count = 0;
	for each row in Table do
		if ( row.Tag = Tag ) then
			count = count + 1;
		endif; 
	enddo; 
	return count > 1;
	
EndFunction 

&AtServer
Procedure Read ( Ref, Table ) export
	
	refType = TypeOf ( Ref );
	if ( refType = Type ( "CatalogRef.Projects" ) ) then
		s = "
		|select Tags.Tag as Tag
		|from InformationRegister.ProjectTags as Tags
		|where Tags.Project = &Ref
		|order by Tags.Tag.Description
		|";
	else
		s = "
		|select Tags.Tag as Tag
		|from InformationRegister.Tags as Tags
		|where Tags.Document = &Ref
		|order by Tags.Tag.Description
		|";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	result = q.Execute ().Unload ();
	Table.Load ( result );
	
EndProcedure 

&AtServer
Procedure Save ( Ref, Table ) export
	
	for each row in Table do
		tag = row.Tag;
		if ( tag.IsEmpty () ) then
			continue;
		endif;
		TagsSrv.Attach ( Ref, tag );
	enddo; 
	
EndProcedure 
