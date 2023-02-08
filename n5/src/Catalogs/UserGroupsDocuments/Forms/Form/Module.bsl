// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	filterUsers ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure filterUsers ()
	
	recordset = FormAttributeToValue ( "Users" );
	recordset.Filter.UserGroup.Set ( Object.Ref );
	recordset.Read ();
	ValueToFormAttribute ( recordset, "Users" );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Write show empty ( Object.Ref );
	|Users enable filled ( Object.Ref )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	filterUsers ();
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	storeUsers ();
	
EndProcedure

&AtServer
Procedure storeUsers ()
	
	recordset = FormAttributeToValue ( "Users" );
	recordset.Filter.UserGroup.Set ( Object.Ref );
	i = recordset.Count () - 1;
	while ( i >= 0 ) do
		row = recordset [ i ];
		if ( row.User.IsEmpty () ) then
			recordset.Delete ( row );
		endif; 
		i = i - 1;
	enddo; 
	recordset.Write ();

EndProcedure 

// *****************************************
// *********** Table Users

&AtClient
Procedure UsersOnEditEnd ( Item, NewRow, CancelEdit )
	
	Item.CurrentData.UserGroup = Object.Ref;
	
EndProcedure
