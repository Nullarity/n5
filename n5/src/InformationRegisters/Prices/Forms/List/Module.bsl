// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadFilter ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Item show empty ( FixedItem )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFilter ()
	
	Parameters.Filter.Property ( "Item", FixedItem );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure NewPrice ( Command )
	
	openSetupPrices ();
	
EndProcedure

&AtClient
Procedure openSetupPrices ()
	
	if ( FixedItem.IsEmpty () ) then
		OpenForm ( "Document.SetupPrices.ObjectForm" );
	else
		p = new Structure ();
		p.Insert ( "Item", FixedItem );
		OpenForm ( "Document.SetupPrices.Form.Simple", p );
	endif; 
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	ShowValue ( , Item.CurrentData.Recorder );
	
EndProcedure
