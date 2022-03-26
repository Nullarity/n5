
&AtClient
Procedure CommandProcessing ( Reference, ExecuteParameters )

	p = ReportsSystem.GetParams ( "Reconciliation" );
	p.GenerateOnOpen = true;
	filters = new Array ();
	type = TypeOf ( Reference );
	organization = DC.CreateParameter ( "Organization" );
	if ( type = Type ( "CatalogRef.Organizations" ) ) then
		organization.Value = Reference;
	else
		if ( type = Type ( "DocumentRef.Payment" )
			or type = Type ( "DocumentRef.Refund" ) ) then
			name = "Customer";
		else
			name = "Vendor";
		endif;
		organization.Value = DF.Pick ( Reference, name );
		dateEnd = DF.Pick ( Reference, "Date" );
		period = DC.CreateParameter ( "Period", new StandardPeriod ( BegOfYear ( dateEnd ), dateEnd ) );
		filters.Add ( period );
	endif;
	filters.Add ( organization );
	p.Filters = filters;
	OpenForm ( "Report.Common.Form", p, ExecuteParameters.Source, true, ExecuteParameters.Window );

EndProcedure
