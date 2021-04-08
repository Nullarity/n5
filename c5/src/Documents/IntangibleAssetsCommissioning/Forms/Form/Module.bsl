&AtServer
var Env export;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	CommissioningForm.OnCreateAtServer ( ThisObject );
	
EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsIntangibleAsset () ) then
		CommissioningForm.LoadRow( ThisObject, SelectedValue );
	elsif ( operation = Enum.ChoiceOperationsIntangibleAssetSaveAndNew() ) then
		CommissioningForm.LoadRow( ThisObject, SelectedValue );
		CommissioningForm.NewRow ( ThisObject, false );
	endif;
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Edit ( Command )
	
	CommissioningForm.EditRow ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ItemsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	CommissioningForm.EditRow ( ThisObject );

EndProcedure

&AtClient
Procedure ItemsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	CommissioningForm.NewRow ( ThisObject, Clone );
	
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
