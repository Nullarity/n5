// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		if ( Parameters.CopyingValue.IsEmpty () ) then
			applyBillable ( ThisObject );
		endif; 
	endif; 
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Item Feature HourlyRate Currency show Object.Billable;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClientAtServerNoContext
Procedure applyBillable ( Form )
	
	object = Form.Object;
	if ( object.Billable ) then
		if ( object.Currency.IsEmpty () ) then
			object.Currency = Application.Currency ();
		endif; 
	else
		object.HourlyRate = 0;
		object.Currency = undefined;
		object.Item = undefined;
		object.Feature = undefined;
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure BillableOnChange ( Item )
	
	applyBillable ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Billable" );
	
EndProcedure
