// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	loadParams ();
	initVariant ();

EndProcedure

&AtServer
Procedure loadParams ()
	
	PlannedFinish = Parameters.Finish;
	initFinishNow ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure initFinishNow ( Form )

	Form.FinishedNow = PeriodsSrv.GetCurrentSessionDate ();

EndProcedure

&AtServer
Procedure initVariant ()
	
	if ( PlannedFinish > FinishedNow ) then
		Variant = 1;
	endif;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )

	if ( not checkFinish () ) then
		Cancel = true;
	endif;
	
EndProcedure

&AtServer
Function checkFinish ()
	
	if ( Variant = 0 ) then
		field = "PlannedFinish";
		date = PlannedFinish;
	else
		field = "FinishedNow";
		date = FinishedNow;
	endif;
	if ( date < Parameters.Start ) then
		Output.WrongFinishingDate1 ( , field );
		return false;
	elsif ( date > PeriodsSrv.GetCurrentSessionDate () ) then
		Output.WrongFinishingDate2 ( , field );
		return false;
	endif;
	return true;
	
EndFunction

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( CheckFilling () ) then
		Close ( ? ( Variant = 1, FinishedNow, PlannedFinish ) );
	endif;
	
EndProcedure

&AtClient
Procedure VariantOnChange ( Item )
	
	applyVariant ();
	
EndProcedure

&AtClient
Procedure applyVariant ()
	
	if ( Variant = 1 ) then
		initFinishNow ( ThisObject );
	endif;
	
EndProcedure

&AtClient
Procedure FinishedNowStartChoice ( Item, ChoiceData, StandardProcessing )

	#if ( MobileClient ) then
		return;
	#endif
	StandardProcessing = false;
	DatePicker.SelectDate ( Item, FinishedNow, Parameters.Start );

EndProcedure

