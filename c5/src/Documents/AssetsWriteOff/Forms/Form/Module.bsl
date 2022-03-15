&AtServer
var Env export;
&AtServer
var Base export;
&AtServer
var InventoryExists export;
&AtClient
var ItemsRow export;
&AtServer
var AccountData export;
&AtClient
var AccountData export;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	AssetsWriteOffForm.OnReadAtServer ( ThisObject, CurrentObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	AssetsWriteOffForm.OnCreateAtServer ( ThisObject );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	AssetsWriteOffForm.BeforeWrite ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	AssetsWriteOffForm.ApplyCurrency ( ThisObject );
	
EndProcedure 

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure ExpenseAccountOnChange ( Item )
	
	applyExpenseAccount ();
	
EndProcedure

&AtServer
Procedure applyExpenseAccount ()
	
	AssetsWriteOffForm.ApplyExpenseAccount ( ThisObject );
	
EndProcedure 

&AtClient
Procedure ShowPricesOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.ShowPrices" );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure ShowDetails ( Command )
	
	AssetsWriteOffForm.ShowDetails ( ThisObject );
	
EndProcedure

&AtClient
Procedure Fill ( Command )
	
	DepreciationSetupFrom.Fill ( ThisObject );
	
EndProcedure

&AtClient
Function FillingParams () export
	
	p = Filler.GetParams ();
	p.Report = "AssetsFilling";
	p.Variant = "#FillFixedAssets";
	p.Filters = AssetsWriteOffForm.GetFilters ( Object );
	return p;
	
EndFunction

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not applyFilling ( Result ) ) then
		Output.FillingDataNotFound ();
	endif;
	
EndProcedure

&AtServer
Function applyFilling ( Result ) 

	return DepreciationSetupFrom.Filling ( ThisObject, Result );

EndFunction

&AtClient
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	AssetsWriteOffForm.ItemsBeforeRowChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	AssetsWriteOffForm.ItemsOnEditEnd ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	AssetsWriteOffForm.CalcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	AssetsWriteOffForm.ItemsItemOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsExpenseAccountOnChange ( Item )
	
	AssetsWriteOffForm.ItemsExpenseAccountOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsDim1StartChoice ( Item, ChoiceData, StandardProcessing )
	
	AssetsWriteOffForm.ChooseDim ( ThisObject, Item, 1, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ItemsDim2StartChoice ( Item, ChoiceData, StandardProcessing )
	
	AssetsWriteOffForm.ChooseDim ( ThisObject, Item, 2, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ItemsDim3StartChoice ( Item, ChoiceData, StandardProcessing )
	
	AssetsWriteOffForm.ChooseDim ( ThisObject, Item, 3, StandardProcessing );
	
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

&AtClient
Procedure VATUseOnChange ( Item )
	
	AssetsWriteOffForm.ApplyVATUse ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsVATCodeOnChange ( Item )
	
	ItemsRow.VATRate = DF.Pick ( ItemsRow.VATCode, "Rate" );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsVATOnChange ( Item )
	
	Computations.Total ( ItemsRow, Object.VATUse, false );
	
EndProcedure
