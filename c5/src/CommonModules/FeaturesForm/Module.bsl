Procedure SetFilter ( Form ) export
	
	item = Form.Parameters.Item; 
	if ( item.IsEmpty () ) then
		return;
	endif;
	Form.Items.List.Representation = TableRepresentation.List;
	features = DF.Pick ( item, "Features" );
	list = Form.List;
	DC.SetFilter ( list, "Parent", features );
	if ( features.IsEmpty () ) then
		DC.SetFilter ( list, "IsFolder", false );
	endif;
	
EndProcedure