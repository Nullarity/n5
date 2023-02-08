// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	deserializeColors ();
	
EndProcedure

&AtServer
Procedure deserializeColors ()
	
	storage = Type ( "ValueStorage" );
	try
		Color = XMLValue ( storage, Object.Color ).Get ();
	except
	endtry;
	try
		BackColor = XMLValue ( storage, Object.BackColor ).Get ();
	except
	endtry;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		deserializeColors ();
	endif; 
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	serializeColors ( CurrentObject );
	
EndProcedure

&AtServer
Procedure serializeColors ( CurrentObject )
	
	CurrentObject.Color = XMLString ( new ValueStorage ( Color ) );
	CurrentObject.BackColor = XMLString ( new ValueStorage ( BackColor ) );
	
EndProcedure 

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageCalendarAppearanceChanged () );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure BackColorClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure BackColorStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	Colors.ChooseColor ( Item, BackColor, true );
	
EndProcedure

&AtClient
Procedure BackColorChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	StandardProcessing = false;
	BackColor = SelectedValue.BackColor;
	Color = SelectedValue.TextColor;
	
EndProcedure

&AtClient
Procedure ColorStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	Colors.ChooseColor ( Item, Color );
	
EndProcedure

&AtClient
Procedure ColorClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure
