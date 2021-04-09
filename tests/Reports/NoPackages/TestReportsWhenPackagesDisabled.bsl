// Some reports depend on Package feature.
// This test disables Packages and test reports

Call ( "Common.Init" );
CloseAll ();

togglePackages ( false );
generateReports ();
togglePackages ( true );
generateReports ();
Disconnect();

Procedure togglePackages ( Flag )
	
	Commando("e1cib/data/CommonForm.Settings");
	With();
	needed = ?(Flag, "Yes", "No");
	if (Fetch("#Packages") <> needed) then
		Click("#Packages");
		Click("#FormWriteAndClose");
	endif;
	CloseAll();
	
EndProcedure

Procedure generateReports ()
	
	// List of reports
	list = new Array ();
	list.Add ( "Stock" );
	list.Add ( "Cost" );
	list.Add ( "InternalOrders" );
	list.Add ( "Items" );
	list.Add ( "Provision" );
	list.Add ( "SalesOrderItems" );
	
	// Opening all of them
	IgnoreErrors = true;
	for each item in list do
		try
			CloseAll();
			Commando("e1cib/app/Report." + item);
			error = App.GetCurrentErrorInfo();
			With();
			Click("#GenerateReport");
		except
			error = ErrorInfo ();
		endtry;
		if ( error <> undefined ) then
			WriteError ( "Report <" + item + "> has not been performed:" + error.Description );
			Pause(1); // Prevent from errors replacing
		endif;
	enddo;
	IgnoreErrors = false;
	
EndProcedure
