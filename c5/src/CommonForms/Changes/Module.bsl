// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParameters ();
	setUser ();
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|AgreementPage show not IAgree;
	|DetailsPage show IAgree;
	|Information mark Reason = Enum.ChangeReasons.Other
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParameters ()
	
	Items.Reason.ChoiceList.LoadValues ( Parameters.Reasons );
	
EndProcedure 

&AtServer
Procedure setUser ()
	
	Items.Agreement.Title = StrReplace ( Items.Agreement.Title, "%User", "" + SessionParameters.User );
	
EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	checkInformation ( CheckedAttributes );
	
EndProcedure

&AtServer
Procedure checkInformation ( CheckedAttributes )
	
	if ( Reason = Enums.ChangeReasons.Other ) then
		CheckedAttributes.Add ( "Information" );
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Agree ( Command )
	
	IAgree = true;
	Appearance.Apply ( ThisObject, "IAgree" );
	
EndProcedure

&AtClient
Procedure Cancel ( Command )
	
	Close ();
	
EndProcedure

&AtClient
Procedure ReasonOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Reason" );
	
EndProcedure

&AtClient
Procedure Save ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif; 
	Close ( getData () );
	
EndProcedure

&AtClient
Function getData ()
	
	data = new Structure ();
	data.Insert ( "Reason", Reason );
	data.Insert ( "Information", Information );
	return data;
	
EndFunction 
