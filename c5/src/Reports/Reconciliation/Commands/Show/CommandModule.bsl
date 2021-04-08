
&AtClient
Procedure CommandProcessing ( Organization, ExecuteParameters )

	p = ReportsSystem.GetParams ( "Reconciliation" );
	p.Filters = new Array ();
	filterItem = DC.CreateParameter ( "Organization" );
	filterItem.Value = Organization;
	p.Filters.Add ( filterItem );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, ExecuteParameters.Source, true, ExecuteParameters.Window );

EndProcedure
