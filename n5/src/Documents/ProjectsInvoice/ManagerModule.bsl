#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.ProjectsInvoice.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	makePayments ( Env );
	makeSales ( Env );
	makeTimeEntriesInvoicing ( Env );
	makeBrokenTimeEntriesInvoicing ( Env );
	makeProjectsInvoicing ( Env );
	makeBrokenProjectsInvoicing ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )
	
	sqlFields ( Env );
	sqlSales ( Env );
	sqlTimeEntriesInvoicing ( Env );
	sqlProjectsInvoicing ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );

EndProcedure 

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Amount as Amount
	|from Document.ProjectsInvoice as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlSales ( Env )
	
	s = "
	|// #Sales
	|select Services.Project as Project, Services.Employee as Employee,
	|	sum ( Services.Amount + Services.SalesTaxTotalAmount ) as Amount,
	|	sum ( Services.Minutes ) as Minutes
	|from Document.ProjectsInvoice.Services as Services
	|where Services.Ref = &Ref
	|group by Services.Project, Services.Employee
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlTimeEntriesInvoicing ( Env )
	
	s = "
	|// #TimeEntryInvoices
	|select Invoicing.TimeEntry as TimeEntry, Invoicing.Invoice as Invoice, Invoicing.Minutes as Minutes, Invoicing.Amount as Amount
	|from InformationRegister.TimeEntryInvoices as Invoicing
	|	//
	|	// Services
	|	//
	|	join Document.ProjectsInvoice.Services as Services
	|	on Services.Ref = &Ref
	|	and Services.TimeEntry = Invoicing.TimeEntry
	|;
	|// #BrokenTimeEntriesInvoicing
	|select Invoicing.TimeEntry as TimeEntry
	|from InformationRegister.TimeEntryInvoices as Invoicing
	|where Invoicing.Invoice = &Ref
	|and Invoicing.TimeEntry not in ( select distinct TimeEntry from Document.ProjectsInvoice.Services where Ref = &Ref )
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlProjectsInvoicing ( Env )
	
	s = "
	|// #ProjectInvoices
	|select distinct Invoicing.Project as Project, Invoicing.Invoice as Invoice
	|from InformationRegister.ProjectInvoices as Invoicing
	|	//
	|	// Services
	|	//
	|	join Document.ProjectsInvoice.Services as Services
	|	on Services.Ref = &Ref
	|	and Services.Project = Invoicing.Project
	|;
	|// #BrokenProjectsInvoicing
	|select Invoicing.Project as Project
	|from InformationRegister.ProjectInvoices as Invoicing
	|where Invoicing.Invoice = &Ref
	|and Invoicing.Project not in ( select distinct Project from Document.Invoice.Services where Ref = &Ref )
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure makePayments ( Env )
	
	if ( Env.Fields.Amount = 0 ) then
		return;
	endif; 
	movement = Env.Registers.ProjectDebts.Add ();
	movement.Period = Env.Fields.Date;
	movement.Invoice = Env.Ref;
	movement.Amount = Env.Fields.Amount;
	
EndProcedure 

Procedure makeSales ( Env )
	
	table = Env.Sales;
	for each row in table do
		if ( row.Amount = 0 ) and ( row.Minutes = 0 ) then
			continue;
		endif; 
		movement = Env.Registers.ProjectSales.Add ();
		movement.Period = Env.Fields.Date;
		movement.Project = row.Project;
		movement.Employee = row.Employee;
		movement.Amount = row.Amount;
		movement.Minutes = row.Minutes;
	enddo; 
	
EndProcedure 

Procedure makeTimeEntriesInvoicing ( Env )
	
	table = Env.TimeEntryInvoices;
	for each row in table do
		record = InformationRegisters.TimeEntryInvoices.CreateRecordManager ();
		record.TimeEntry = row.TimeEntry;
		record.Invoice = Env.Ref;
		record.Minutes = row.Minutes;
		record.Amount = row.Amount;
		record.Write ();
	enddo; 
	
EndProcedure

Procedure makeBrokenTimeEntriesInvoicing ( Env )
	
	table = Env.BrokenTimeEntriesInvoicing;
	for each row in table do
		record = InformationRegisters.TimeEntryInvoices.CreateRecordManager ();
		record.TimeEntry = row.TimeEntry;
		record.Read ();
		if ( record.Selected () ) then
			record.Invoice = undefined;
			record.Write ();
		endif; 
	enddo; 
	
EndProcedure

Procedure makeProjectsInvoicing ( Env )
	
	table = Env.ProjectInvoices;
	for each row in table do
		record = InformationRegisters.ProjectInvoices.CreateRecordManager ();
		record.Project = row.Project;
		record.Invoice = Env.Ref;
		record.Write ();
	enddo; 
	
EndProcedure

Procedure makeBrokenProjectsInvoicing ( Env )
	
	table = Env.BrokenProjectsInvoicing;
	for each row in table do
		record = InformationRegisters.ProjectInvoices.CreateRecordManager ();
		record.Project = row.Project;
		record.Read ();
		if ( record.Selected () ) then
			record.Invoice = undefined;
			record.Write ();
		endif; 
	enddo; 
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.ProjectDebts.Write = true;
	registers.ProjectSales.Write = true;
	
EndProcedure

#endregion

#endif