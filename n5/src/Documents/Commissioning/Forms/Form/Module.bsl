&AtServer
var Env export;

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
	
	CommissioningForm.OnCreateAtServer ( ThisObject );
	
EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsFixedAsset () ) then
		CommissioningForm.LoadRow ( ThisObject, false, SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsFixedAssetSaveAndNew () ) then
		CommissioningForm.LoadRow ( ThisObject, false, SelectedValue );
		CommissioningForm.NewRow ( ThisObject, false, false );
	elsif ( operation = Enum.ChoiceOperationsFixedAssetInProgress () ) then
		CommissioningForm.LoadRow ( ThisObject, true, SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsFixedAssetInProgressSaveAndNew () ) then
		CommissioningForm.LoadRow ( ThisObject, true, SelectedValue );
		CommissioningForm.NewRow ( ThisObject, true, false );
	endif;
	
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

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure EditItems ( Command )
	
	CommissioningForm.EditRow ( ThisObject, false );
	
EndProcedure

&AtClient
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ItemsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	CommissioningForm.EditRow ( ThisObject, false );

EndProcedure

&AtClient
Procedure ItemsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	CommissioningForm.NewRow ( ThisObject, false, Clone );
	
EndProcedure

// *****************************************
// *********** Table InProgress

&AtClient
Procedure EditInProgress ( Command )

	CommissioningForm.EditRow ( ThisObject, true );

EndProcedure

&AtClient
Procedure InProgressSelection ( Item, SelectedRow, Field, StandardProcessing )

	StandardProcessing = false;
	CommissioningForm.EditRow ( ThisObject, true );

EndProcedure

&AtClient
Procedure InProgressBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )

	Cancel = true;
	CommissioningForm.NewRow ( ThisObject, true, Clone );

EndProcedure

&AtClient
Procedure InProgressBeforeRowChange ( Item, Cancel )

	Cancel = true;

EndProcedure

// *****************************************
// *********** Group Stakeholders

&AtClient
Procedure ApprovedOnChange ( Item )
	
	MembersForm.SetPosition ( Object.Approved, Object.ApprovedPosition, Object.Date );
	
EndProcedure

&AtClient
Procedure HeadOnChange ( Item )
	
	MembersForm.SetPosition ( Object.Head, Object.HeadPosition, Object.Date );
	
EndProcedure

&AtClient
Procedure MembersMemberOnChange ( Item )
	
	MembersForm.FillPosition ( Items.Members.CurrentData, Object.Date );
	
EndProcedure
