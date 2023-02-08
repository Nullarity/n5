
&AtClient
Procedure CommandProcessing ( Account, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "Transactions" );
	p.Filters = getFilters ( Account );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );

EndProcedure

&AtClient
Function getFilters ( Account )
	
	filters = new Array ();
	filterItem = DC.CreateParameter ( "Account" );
	filterItem.Value = Account;
	filters.Add ( filterItem );
	return filters;
	
EndFunction
