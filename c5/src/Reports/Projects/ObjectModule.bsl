#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	resetCurrency ();
	setCompletionDateVisibility ();
	disableUnsupportedRecorderResources ();
	
EndProcedure

Procedure resetCurrency ()
	
	projectFilter = DC.FindFilter ( Params.Settings, "Project" );
	currencyParameter = DC.GetParameter ( Params.Settings, "Currency" );
	if ( projectFilter.Use )
		and ( projectFilter.ComparisonType = DataCompositionComparisonType.Equal
		or projectFilter.ComparisonType = DataCompositionComparisonType.InHierarchy
		or projectFilter.ComparisonType = DataCompositionComparisonType.InListByHierarchy ) then
		currencyParameter.Use = false;
	else
		currencyParameter.Use = true;
		if ( not ValueIsFilled ( currencyParameter.Value ) ) then
			currencyParameter.Value = Application.Currency ();
		endif; 
	endif; 
	
EndProcedure

Procedure setCompletionDateVisibility ()
	
	projectGroup = DCsrv.GetGroup ( Params.Settings, "Project" );
	if ( projectGroup = undefined ) then
		return;
	endif; 
	completedFilter = DC.FindFilter ( Params.Settings, "Project.Completed" );
	completionDateField = DCsrv.GetField ( projectGroup.Selection, "Project.CompletionDate" );
	completionDateField.Use = not completedFilter.Use;
	
EndProcedure 

Procedure disableUnsupportedRecorderResources ()
	
	recorderGroup = DCsrv.GetGroup ( Params.Settings, "Recorder", true );
	if ( recorderGroup = undefined ) then
		return;
	endif; 
	disableField ( "ProjectDuration" );
	disableField ( "DaysRemain" );
	disableField ( "DaysOver" );
	disableField ( "Profit" );
	disableField ( "MinutesRemain" );
	disableField ( "MinutesOver" );
	disableField ( "CompletionPercent" );
	disableField ( "CostOver" );
	disableField ( "CostRemain" );
	
EndProcedure 

Procedure disableField ( FieldName )
	
	field = DCsrv.GetField ( Params.Settings.Selection, FieldName );
	if ( field <> undefined ) then
		field.Use = false;
	endif; 
	
EndProcedure 

#endif