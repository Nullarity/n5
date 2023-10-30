// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Token enable SetToken
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	applyToken ( CurrentObject );
	
EndProcedure

&AtServer
Procedure applyToken ( CurrentObject )
	
	if ( not SetToken ) then
		return;
	endif;
	r = InformationRegisters.Tokens.CreateRecordManager ();
	r.Target = CurrentObject.Ref;
	if ( Token = "" ) then
		r.Delete ();
	else
		r.Token = Token;
		r.Write ();
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure SetTokenOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "SetToken" );
	
EndProcedure
