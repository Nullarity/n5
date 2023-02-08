// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	updateChangesPermission ();

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.SetCreator ( Object );
		if ( Parameters.CopyingValue.IsEmpty () ) then
			BalancesForm.CheckParameters ( ThisObject );
		else
			BalancesForm.FixDate ( ThisObject );
		endif;
		updateChangesPermission ();
	endif;
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsFixedAsset () ) then
		loadRow ( SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsFixedAssetSaveAndNew () ) then
		loadRow ( SelectedValue );
		newRow ( false );
	endif;
	
EndProcedure

&AtClient
Procedure loadRow ( Params )
	
	value = Params.Value;
	data = Items.Items.CurrentData;
	if ( value = undefined ) then
		if ( Params.NewRow ) then
			Object.Items.Delete ( data );
		endif;
	else
		FillPropertyValues ( data, value );
	endif;
  	
EndProcedure

&AtClient
Procedure newRow ( Clone )
	
	Forms.NewRow ( ThisObject, Items.Items, Clone );
	editRow ( true );
	
EndProcedure

&AtClient
Procedure editRow ( NewRow = false ) 

	if ( ReadOnly
		or Items.Items.CurrentData = undefined ) then
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Company", Object.Company );
	p.Insert ( "NewRow", NewRow );
	OpenForm ( "Document.AssetsBalances.Form.Row", p, ThisObject );

EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Edit ( Command )
	
	editRow ();
	
EndProcedure

&AtClient
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ItemsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	editRow ();

EndProcedure

&AtClient
Procedure ItemsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	newRow ( Clone );
	
EndProcedure
