#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	hideParams ();
	titleReport ();
	Reporter.AdjustGroupping ( ThisObject, "Item" );
	
EndProcedure

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "Period" );
	
EndProcedure 

Procedure titleReport ()
	
	period = DC.FindParameter ( Params.Composer, "Period" );
	if ( period.Use ) then
		p = Params.Settings.OutputParameters.FindParameterValue ( new DataCompositionParameter ( "Title" ) );
		value = period.Value;
		p.Value = p.Value + ", " + Periods.Presentation ( value.StartDate, value.EndDate );
	endif; 

EndProcedure 

#endif