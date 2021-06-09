
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		if ( Parameters.CopyingValue.IsEmpty () ) then
			BalancesForm.CheckParameters ( ThisObject );
		else
			BalancesForm.FixDate ( ThisObject );
		endif;
		DocumentForm.SetCreator ( Object );
	endif;
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsIntangibleAsset () ) then
		loadRow ( SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsIntangibleAssetSaveAndNew () ) then
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
	OpenForm ( "Document.IntangibleAssetsBalances.Form.Row", p, ThisObject );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

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
