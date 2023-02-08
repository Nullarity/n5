&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	openReport ( CommandParameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( CommandParameter, CommandExecuteParameters )
	
	organization = CommandParameter [ 0 ];
	p = ReportsSystem.GetParams ( "Sales" );
	p.Filters = new Array ();
	filterItem = DC.CreateFilter ( "Customer" );
	if ( CommandParameter.Count () > 1 ) then
		filterItem.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
		filterItem.RightValue = new ValueList ();
		filterItem.RightValue.LoadValues ( CommandParameter );
	else
		isFolder = DF.Pick ( organization, "IsFolder" );
		if ( isFolder ) then
			filterItem.ComparisonType = DataCompositionComparisonType.InHierarchy;
		else
			filterItem.ComparisonType = DataCompositionComparisonType.Equal;
		endif; 
		filterItem.RightValue = organization;
	endif; 
	p.Filters.Add ( filterItem );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure 
