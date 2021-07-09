#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.TimeEntry.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

Procedure SetKeys ( Object ) export
	
	Catalogs.RowKeys.Set ( Object.Items, 1 );
	Catalogs.RowKeys.Set ( Object.Tasks, 2 );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	makeProjectsCost ( Env );
	prepareTariffsTable ( Env );
	makeTimeEntriesTariffs ( Env );
	makeWork ( Env );
	makeTimeEntriesInvoicing ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )
	
	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	setEmployeeHourlyCost ( Env );
	sqlTasks ( Env );
	sqlTariffs ( Env );
	sqlBillableMinutes ( Env );
	sqlItems ( Env );
	sqlInvoicing ( Env );
	Env.Q.SetParameter ( "Project", Env.Fields.Project );
	Env.Q.SetParameter ( "Employee", Env.Fields.Employee );
	SQL.Perform ( Env );

EndProcedure 

Procedure sqlFields ( Env )
	
	s = "
	|select Documents.Date as Date, Documents.Employee as Employee, Documents.Project as Project, Documents.Project.Currency as ProjectCurrency,
	|	Documents.Project.HourlyRate as ProjectHourlyRate, Documents.Project.Pricing as Pricing,
	|	Documents.Employee.HourlyCost as EmployeeHourlyCost, Documents.Employee.Currency as EmployeeCurrency,
	|	Documents.Employee.HourlyRate as EmployeeHourlyRate
	|into Fields
	|from Document.TimeEntry as Documents
	|where Documents.Ref = &Ref
	|;
	|// @Fields
	|select * from Fields
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure setEmployeeHourlyCost ( Env )
	
	employeeHourlyCost = Currencies.Convert ( Env.Fields.EmployeeHourlyCost, Env.Fields.EmployeeCurrency, Env.Fields.ProjectCurrency, Env.Fields.Date );
	Env.Q.SetParameter ( "EmployeeHourlyCost", employeeHourlyCost );
	
EndProcedure 

Procedure sqlTasks ( Env )
	
	s = "
	|select distinct Tasks.Task as Task, Tasks.Employee as Employee, Tasks.TimeType as TimeType, Tasks.HourlyCost as HourlyCost
	|into ProjectTasks
	|from Catalog.Projects.Tasks as Tasks
	|where Tasks.Ref = &Project
	|;
	|// #Tasks
	|select Tasks.Task as Task,
	|	sum ( case when Tasks.TimeType = value ( Enum.Time.Billable ) then Tasks.Minutes else 0 end ) as BillableMinutes,
	|	sum ( case when Tasks.TimeType <> value ( Enum.Time.Billable ) then Tasks.Minutes else 0 end ) as NonBillableMinutes,
	|	sum ( isnull ( ProjectTasks.HourlyCost, isnull ( ProjectCost.HourlyCost, &EmployeeHourlyCost ) ) * ( Tasks.Minutes / 60 ) ) as Cost
	|from Document.TimeEntry.Tasks as Tasks
	|	//
	|	// Fields
	|	//
	|	join Fields as Fields
	|	on true
	|	left join ProjectTasks as ProjectTasks
	|	on ProjectTasks.Task = Tasks.Task
	|	and ProjectTasks.Employee = Fields.Employee
	|	and ProjectTasks.TimeType = Tasks.TimeType
	|	//
	|	// ProjectCost
	|	//
	|	left join ProjectTasks as ProjectCost
	|	on ProjectTasks.Task = Tasks.Task
	|	and ProjectTasks.Employee = Fields.Employee
	|	and ProjectTasks.TimeType <> Tasks.TimeType
	|where Tasks.Ref = &Ref
	|and not Tasks.TimeType in ( value ( Enum.Time.Evening ), value ( Enum.Time.Night ) )
	|group by Tasks.Task
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlTariffs ( Env )
	
	s = "
	|// #Tariffs
	|select DocumentTasks.Minutes as Minutes,
	|	DocumentTasks.RowKey as RowKey";
	if ( Env.Fields.Pricing = Enums.ProjectsPricing.Employees
		or Env.Fields.Pricing = Enums.ProjectsPricing.Tasks ) then
		s = s + ", ProjectTasks.HourlyRate as ProjectTaskHourlyRate";
	endif;
	if ( Env.Fields.Pricing = Enums.ProjectsPricing.Tasks ) then
		s = s + ", CompanyTasks.HourlyRate as TaskHourlyRate, CompanyTasks.Currency as TaskCurrency";
	endif;
	s = s + "
	|from Document.TimeEntry.Tasks as DocumentTasks";
	if ( Env.Fields.Pricing = Enums.ProjectsPricing.Employees
		or Env.Fields.Pricing = Enums.ProjectsPricing.Tasks ) then
		s = s + "
		|	left join ( select distinct Tasks.Task as Task, Tasks.Employee as Employee, Tasks.HourlyRate as HourlyRate
		|				from Catalog.Projects.Tasks as Tasks
		|				where Tasks.Ref = &Project ) as ProjectTasks
		|	on ProjectTasks.Employee = &Employee
		|	and ProjectTasks.Task = DocumentTasks.Task";
	endif;
	if ( Env.Fields.Pricing = Enums.ProjectsPricing.Tasks ) then
		s = s + "
		|	left join Catalog.Tasks as CompanyTasks
		|	on CompanyTasks.Ref = DocumentTasks.Task";
	endif; 
	s = s + "
	|where DocumentTasks.Ref = &Ref
	|and DocumentTasks.TimeType = value ( Enum.Time.Billable )
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlBillableMinutes ( Env )
	
	s = "
	|// #BillableMinutes
	|select Tasks.RowKey as RowKey, Tasks.Minutes as Minutes
	|from Document.TimeEntry.Tasks as Tasks
	|where Tasks.Ref = &Ref
	|and Tasks.TimeType = value ( Enum.Time.Billable )
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlItems ( Env )
	
	s = "
	|// #Items
	|select Items.RowKey as RowKey, Items.Quantity as Quantity
	|from Document.TimeEntry.Items as Items
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlInvoicing ( Env )
	
	s = "
	|// @Invoicing
	|select top 1 Invoicing.Invoice as Invoice
	|from InformationRegister.TimeEntryInvoices as Invoicing
	|where Invoicing.TimeEntry = &Ref
	|and Invoicing.Invoice <> value ( Document.ProjectsInvoice.EmptyRef )
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure makeProjectsCost ( Env )
	
	table = Env.Tasks;
	for each row in table do
		movement = Env.Registers.ProjectsCost.Add ();
		movement.Period = Env.Fields.Date;
		movement.Employee = Env.Fields.Employee;
		movement.Project = Env.Fields.Project;
		movement.Task = row.Task;
		movement.BillableMinutes = row.BillableMinutes;
		movement.NonBillableMinutes = row.NonBillableMinutes;
		movement.Cost = row.Cost;
	enddo; 
	
EndProcedure 

Procedure prepareTariffsTable ( Env )
	
	tariffsTable = new ValueTable ();
	tariffsTable.Columns.Add ( "RowKey", new TypeDescription ( "CatalogRef.RowKeys" ) );
	tariffsTable.Columns.Add ( "HourlyRate", new TypeDescription ( "Number" ) );
	tariffsTable.Columns.Add ( "Quantity", new TypeDescription ( "Number" ) );
	tariffsTable.Columns.Add ( "Amount", new TypeDescription ( "Number" ) );
	table = Env.Tariffs;
	for each row in table do
		tariffRow = tariffsTable.Add ();
		tariffRow.RowKey = row.RowKey;
		tariff = getEmployeeTariff ( Env, row );
		tariffRow.HourlyRate = tariff;
		qty = row.Minutes / 60;
		tariffRow.Quantity = qty;
		tariffRow.Amount = qty * tariff;
	enddo; 
	Env.Tariffs = tariffsTable;
	
EndProcedure  

Function getEmployeeTariff ( Env, Row )
	
	if ( Env.Fields.Pricing = Enums.ProjectsPricing.Amount
		or Env.Fields.Pricing = Enums.ProjectsPricing.HourlyRate ) then
		return Env.Fields.ProjectHourlyRate;
	elsif ( Env.Fields.Pricing = Enums.ProjectsPricing.Employees ) then
		if ( Row.ProjectTaskHourlyRate = null ) then
			return Currencies.Convert ( Env.Fields.EmployeeHourlyRate, Env.Fields.EmployeeCurrency, Env.Fields.ProjectCurrency, Env.Fields.Date );
		else
			return Row.ProjectTaskHourlyRate;
		endif; 
	elsif ( Env.Fields.Pricing = Enums.ProjectsPricing.Tasks ) then
		if ( Row.ProjectTaskHourlyRate = null ) then
			if ( Row.TaskHourlyRate = null ) then
				return 0;
			else
				return Currencies.Convert ( Row.TaskHourlyRate, Row.TaskCurrency, Env.Fields.ProjectCurrency, Env.Fields.Date );
			endif; 
		else
			return Row.ProjectTaskHourlyRate;
		endif; 
	endif; 
	
EndFunction 

Procedure makeTimeEntriesTariffs ( Env )
	
	table = Env.Tariffs;
	for each row in table do
		rate = row.HourlyRate;
		movement = Env.Registers.TimeEntryRates.Add ();
		movement.TimeEntry = Env.Ref;
		movement.RowKey = row.RowKey;
		movement.HourlyRate = rate;
	enddo; 
	recordset = Env.Registers.Work;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.Add ();
		movement.Period = date;
		movement.TimeEntry = Env.Ref;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Amount;
	enddo; 
	
EndProcedure 

Procedure makeWork ( Env )
	
	table = Env.Items;
	recordset = Env.Registers.Work;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.Add ();
		movement.Period = date;
		movement.TimeEntry = Env.Ref;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeTimeEntriesInvoicing ( Env )
	
	record = InformationRegisters.TimeEntryInvoices.CreateRecordManager();
	record.TimeEntry = Env.Ref;
	if ( Env.BillableMinutes.Count () = 0 ) then
		record.Delete ();
	else
		invoicingData = getInvoicingData ( Env );
		record.Minutes = invoicingData.Minutes;
		record.Amount = invoicingData.Amount;
		if ( Env.Invoicing <> undefined ) then
			record.Invoice = Env.Invoicing.Invoice;
		endif; 
		record.Write ();
	endif; 
		
EndProcedure 

Function getInvoicingData ( Env )
	
	tariffsTable = Env.Tariffs;
	minutesTable = Env.BillableMinutes;
	invoicingTable = new ValueTable ();
	invoicingTable.Columns.Add ( "HourlyRate", new TypeDescription ( "Number" ) );
	invoicingTable.Columns.Add ( "Minutes", new TypeDescription ( "Number" ) );
	for each row in tariffsTable do
		invoicingRow = invoicingTable.Add ();
		invoicingRow.HourlyRate = row.HourlyRate;
		invoicingRow.Minutes = minutesTable.Find ( row.RowKey, "RowKey" ).Minutes;
	enddo; 
	invoicingTable.GroupBy ( "HourlyRate", "Minutes" );
	invoicingTable.Columns.Add ( "Amount", new TypeDescription ( "Number" ) );
	for each row in invoicingTable do
		row.Amount = row.HourlyRate * ( row.Minutes / 60 );
	enddo; 
	result = new Structure ( "Minutes, Amount" );
	result.Minutes = invoicingTable.Total ( "Minutes" );
	result.Amount = invoicingTable.Total ( "Amount" );
	return result;
		
EndFunction 

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.ProjectsCost.Write = true;
	registers.TimeEntryRates.Write = true;
	registers.Work.Write = true;
	
EndProcedure

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	setDataParams ( Params, Env );
	setPageSettings ( Params );
	Print.OutputSchema ( Env.T, Params.TabDoc );
	putSignature ( Params, Env );
	return true;
	
EndFunction

Procedure setDataParams ( Params, Env )
	
	Env.T.Parameters.Ref.Value = Params.Reference;
	
EndProcedure 

Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	Print.SetFooter ( tabDoc );
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure putSignature ( Params, Env )
	
	data = DF.Values ( Params.Reference, "Signature, Signer" );
	signature = data.Signature.Get ();
	if ( signature = undefined ) then
		return;
	endif; 
	tabDoc = Params.TabDoc;
	placeholder = tabDoc.FindText ( Env.T.Parameters.SignatureAnchor.Value );
	placeholder.Text = "";
	placeholder.PictureHorizontalAlign = HorizontalAlign.Center;
	placeholder.Picture = new Picture ( signature );

EndProcedure 

#endregion

Function GetTimesheetByEmployee ( Date, Employee ) export
	
	SetPrivilegedMode ( true );
	s = "
	|select top 1 Timesheet.Ref as Timesheet
	|from Document.Timesheet as Timesheet
	|where Timesheet.Employee = &Employee
	|and &Date between Timesheet.DateStart and Timesheet.DateEnd
	|and not Timesheet.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Date", Date );
	q.SetParameter ( "Employee", Employee );
	table = q.Execute ().Unload ();
	SetPrivilegedMode ( false );
	return ? ( table.Count () = 0, undefined, table [ 0 ].Timesheet );
	
EndFunction 

#endif