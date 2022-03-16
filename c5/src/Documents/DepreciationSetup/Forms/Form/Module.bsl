// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	DepreciationSetupFrom.OnCreateAtServer ( ThisObject );
	
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

&AtClient
Procedure DepartmentOnChange ( Item )
	
	FillTable ();
	
EndProcedure

&AtServer
Procedure FillTable () export
	
	DepreciationSetupFrom.FillTable ( ThisObject );
	
EndProcedure 

&AtClient
Procedure EmployeeOnChange ( Item )
	
	FillTable ();
	
EndProcedure

&AtClient
Procedure MethodChangeOnChange ( Item )
	
	DepreciationSetupFrom.MethodChangeOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure UsefulLifeChangeOnChange ( Item )
	
	DepreciationSetupFrom.UsefulLifeChangeOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ExpensesChangeOnChange ( Item )
	
	DepreciationSetupFrom.ExpensesChangeOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure MethodOnChange ( Item )
	
	DepreciationSetupFrom.MethodOnChange ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Fill ( Command )
	
	DepreciationSetupFrom.Fill ( ThisObject );
	
EndProcedure

&AtServer
Function FillingParams () export
	
	p = Filler.GetParams ();
	p.Report = "AssetsFilling";
	p.Variant = "#FillFixedAssets";
	p.Filters = DepreciationSetupFrom.GetFilters ( Object );
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
