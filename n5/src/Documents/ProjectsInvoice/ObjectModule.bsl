#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkTimeEntry ( CheckedAttributes );
	
EndProcedure

Procedure checkTimeEntry ( CheckedAttributes )
	
	if ( InvoiceMethod = Enums.InvoiceMethods.ByTimeEntries ) then
		CheckedAttributes.Add ( "Services.TimeEntry" );
	endif; 
	
EndProcedure 

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.ProjectsInvoice.Post ( env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	if ( InvoiceMethod = Enums.InvoiceMethods.ByProjects ) then
		unbindProjectsInvoicing ();
	else
		unbindTimeEntriesInvoicing ();
	endif; 
	
EndProcedure

Procedure unbindProjectsInvoicing ()
	
	tabe = getBindedProjects ();
	record = InformationRegisters.ProjectInvoices.CreateRecordManager ();
	for each row in tabe do
		record.Project = row.Project;
		record.Read ();
		if ( record.Selected () ) then
			record.Invoice = undefined;
			record.Write ();
		endif; 
	enddo; 
	
EndProcedure 

Function getBindedProjects ()
	
	s = "
	|select ProjectInvoices.Project as Project
	|from InformationRegister.ProjectInvoices as ProjectInvoices
	|where ProjectInvoices.Invoice = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure unbindTimeEntriesInvoicing ()
	
	tabe = getBindedInvoices ();
	record = InformationRegisters.TimeEntryInvoices.CreateRecordManager ();
	for each row in tabe do
		record.TimeEntry = row.TimeEntry;
		record.Read ();
		if ( record.Selected () ) then
			record.Invoice = undefined;
			record.Write ();
		endif; 
	enddo; 
	
EndProcedure 

Function getBindedInvoices ()
	
	s = "
	|select TimeEntryInvoices.TimeEntry as TimeEntry
	|from InformationRegister.TimeEntryInvoices as TimeEntryInvoices
	|where TimeEntryInvoices.Invoice = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ();
	
EndFunction 

#endif