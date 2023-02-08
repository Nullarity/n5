&AtClient
var ChargesRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ChargesOnActivateRow ( Item )
	
	ChargesRow = Item.CurrentData;
	setPercent ();
	
EndProcedure

&AtClient
Procedure setPercent () 

	if ( ChargesRow = undefined ) then
		return;
	endif;
	flag = DF.Pick ( ChargesRow.Charge, "Type" ) = PredefinedValue ( "Enum.CustomsCharges.VAT" );
	Items.Charges.ChildItems.ChargesPercent.ReadOnly = flag;

EndProcedure

&AtClient
Procedure ChargesChargeOnChange ( Item )
	
	applyCharge ();
	setPercent ();
	
EndProcedure

&AtClient
Procedure applyCharge () 

	ChargesRow.Percent = DF.Pick ( ChargesRow.Charge, "Percent" );

EndProcedure