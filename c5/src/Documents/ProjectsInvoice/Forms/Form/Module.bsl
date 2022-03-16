// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setDocumentPaid ();
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure setDocumentPaid ()
	
	if ( not Object.Posted ) then
		DocumentPaid = false;
		return;
	endif; 
	DocumentPaid = documentIsPaid ();
	
EndProcedure 

&AtServer
Function documentIsPaid ()
	
	s = "
	|select top 1 1
	|from AccumulationRegister.ProjectDebts.Balance ( , Invoice = &Invoice ) as Balances
	|where Balances.AmountBalance = 0
	|";
	q = new Query ( s );
	q.SetParameter ( "Invoice", Object.Ref );
	return q.Execute ().Select ().Next ();
	
EndFunction 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setCreator ();
		setCurrency ( ThisObject );
		Constraints.ShowAccess ( ThisObject );
	endif; 
	if ( TypeOf ( Parameters.Base ) = Type ( "Array" ) ) then
		typeOfBase = TypeOf ( Parameters.Base [ 0 ] );
		if ( typeOfBase = Type ( "DocumentRef.TimeEntry" ) ) then
			fillByTimeEntries ();
		elsif ( typeOfBase = Type ( "CatalogRef.Projects" ) ) then
			fillByProjects ();
		endif; 
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|SalesTax2 show Object.TwoSalesTaxes;
	|DocumentPaid show DocumentPaid;
	|SalesTaxAmount show ( filled ( Object.SalesTax1 ) or Object.TwoSalesTaxes );
	|ServicesTimeEntryEmployee ServicesFill show Object.InvoiceMethod = Enum.InvoiceMethods.ByTimeEntries;
	|ServicesSalesTaxAmount1 show filled ( Object.SalesTax1 );
	|ServicesSalesTaxAmount2 ServicesSalesTaxTotalAmount show Object.TwoSalesTaxes;
	|ServicesProject ServicesEmployee lock Object.InvoiceMethod = Enum.InvoiceMethods.ByTimeEntries;
	|ServicesTimeEntry show Object.InvoiceMethod = Enum.InvoiceMethods.ByTimeEntries
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setCreator ()
	
	Object.Creator = SessionParameters.User;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setCurrency ( Form )
	
	object = Form.Object;
	if ( object.Customer.IsEmpty () ) then
		return;
	endif; 
	currency = DF.Pick ( object.Customer, "CustomerContract.Currency" );
	if ( currency.IsEmpty () ) then
		return;
	endif; 
	object.Currency = currency;
	
EndProcedure 

&AtServer
Procedure fillByTimeEntries ()
	
	fillServices ( Parameters.Base );
	calcTotals ( Object );
	calcTotalMinutes ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillServices ( TimeEntries = undefined )
	
	table = getTimeEntries ( getFillingParams ( Object ), TimeEntries );
	for each row in table do
		servicesRow = Object.Services.Add ();
		fillServicesRow ( ThisObject, servicesRow, row );
	enddo; 
	
EndProcedure 

&AtClientAtServerNoContext
Function getFillingParams ( Object )
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Customer", Object.Customer );
	p.Insert ( "Ref", Object.Ref );
	p.Insert ( "Currency", Object.Currency );
	return p;
	
EndFunction 

&AtServerNoContext
Function getTimeEntries ( val Params, val TimeEntries = undefined )
	
	s = "
	|select allowed TimeEntryInvoices.TimeEntry as TimeEntry, TimeEntryInvoices.Minutes as Minutes, TimeEntryInvoices.Amount as Amount
	|into Services
	|from InformationRegister.TimeEntryInvoices as TimeEntryInvoices
	|	//
	|	// TimeEntries
	|	//
	|	join Document.TimeEntry as TimeEntries
	|	on TimeEntries.Ref = TimeEntryInvoices.TimeEntry";
	if ( TimeEntries = undefined ) then
		s = s + "
		|	and TimeEntries.Date <= &DateEnd
		|	and TimeEntries.Customer = &Customer
		|	and TimeEntries.Project.Currency = &Currency";
	else
		s = s + "
		|	and TimeEntries.Ref in ( &TimeEntries )";
	endif; 
	s = s + "
	|where ( Invoice = value ( Document.ProjectsInvoice.EmptyRef )
	|or Invoice = &Ref )
	|index by TimeEntry
	|;
	|select Tariffs.TimeEntry as TimeEntry, count ( distinct Tariffs.HourlyRate ) as TariffsCount, max ( Tariffs.HourlyRate ) as HourlyRate
	|into Tariffs
	|from InformationRegister.TimeEntryRates as Tariffs
	|	//
	|	// Services
	|	//
	|	join Services as Services
	|	on Services.TimeEntry = Tariffs.TimeEntry
	|group by Tariffs.TimeEntry
	|index by TimeEntry
	|;
	|select Services.TimeEntry as TimeEntry, Services.TimeEntry.Project as Project, Services.TimeEntry.Employee as Employee,
	|	Services.Minutes as Minutes, Services.Amount as Amount,
	|	case when Tariffs.TariffsCount = 1 then Tariffs.HourlyRate else Services.Amount / case when Services.Minutes = 0 then 1 else Services.Minutes end end as HourlyRate
	|from Services as Services
	|	//
	|	// Tariffs
	|	//
	|	left join Tariffs as Tariffs
	|	on Tariffs.TimeEntry = Services.TimeEntry
	|order by Services.TimeEntry.Date
	|";
	q = new Query ( s );
	q.SetParameter ( "DateEnd", EndOfDay ( Params.Date ) );
	q.SetParameter ( "Ref", Params.Ref );
	q.SetParameter ( "Customer", Params.Customer );
	q.SetParameter ( "Currency", Params.Currency );
	q.SetParameter ( "TimeEntries", TimeEntries );
	return q.Execute ().Unload ()
	
EndFunction 

&AtClientAtServerNoContext
Procedure fillServicesRow ( Form, ServicesRow, DataRow )
	
	ServicesRow.Amount = DataRow.Amount;
	ServicesRow.Duration = Conversion.MinutesToDuration ( DataRow.Minutes );
	ServicesRow.HourlyRate = DataRow.HourlyRate;
	ServicesRow.Minutes = DataRow.Minutes;
	ServicesRow.TimeEntry = DataRow.TimeEntry;
	ServicesRow.Project = DataRow.Project;
	ServicesRow.Employee = DataRow.Employee;
	calcTaxes ( Form, ServicesRow );
	calcTotalTaxes ( ServicesRow );
		
EndProcedure 

&AtClientAtServerNoContext
Procedure calcTaxes ( Form, Row )
	
	object = Form.Object;
	Row.SalesTaxAmount1 = Row.Amount / 100 * Form.SalesTaxPercent1;
	if ( object.TwoSalesTaxes ) then
		Row.SalesTaxAmount2 = Row.Amount / 100 * Form.SalesTaxPercent2;
	else
		Row.SalesTaxAmount2 = 0;
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcTotalTaxes ( Row )
	
	Row.SalesTaxTotalAmount = Row.SalesTaxAmount1 + Row.SalesTaxAmount2;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	Object.SalesTaxAmount = Object.Services.Total ( "SalesTaxTotalAmount" );
	Object.Amount = Object.Services.Total ( "Amount" ) + Object.SalesTaxAmount;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcTotalMinutes ( Form )
	
	object = Form.Object;
	object.Minutes = object.Services.Total ( "Minutes" );
	object.Duration = Conversion.MinutesToDuration ( object.Minutes );
	
EndProcedure 

&AtServer
Procedure fillByProjects ()
	
	table = Collections.DeserializeTable ( getProjectFields ( Parameters.Base ) );
	for each fieldsRow in table do
		row = Object.Services.Add ();
		fillServicesRow ( ThisObject, row, fieldsRow );
	enddo; 
	calcTotals ( Object );
	calcTotalMinutes ( ThisObject );
	
EndProcedure

&AtServerNoContext
Function getProjectFields ( val Projects )
	
	s = "
	|select Projects.Project as Project, Projects.TimeEntry as TimeEntry, Projects.Employee as Employee, Projects.EmployeeDescription as EmployeeDescription,
	|	 Projects.HourlyRate as HourlyRate, sum ( Projects.Amount ) as Amount, sum ( Projects.Minutes ) as Minutes
	|from (
	|	select Projects.Ref as Project, null as TimeEntry, ProjectTasks.Employee as Employee, ProjectTasks.Employee.Description as EmployeeDescription,
	|		case when Projects.Pricing = value ( Enum.ProjectsPricing.Amount ) then Projects.Amount else ProjectTasks.Amount end as Amount,
	|		case when Projects.Pricing = value ( Enum.ProjectsPricing.Amount ) then case when Projects.PaidMinutes = 0 then 0 else Projects.Amount / ( Projects.PaidMinutes / 60 ) end
	|			when Projects.Pricing = value ( Enum.ProjectsPricing.HourlyRate ) then Projects.HourlyRate
	|			else ProjectTasks.HourlyRate
	|		end as HourlyRate,
	|		case when Projects.Pricing = value ( Enum.ProjectsPricing.Amount ) then Projects.PaidMinutes else ProjectTasks.Minutes end as Minutes
	|	from Catalog.Projects as Projects
	|		left join Catalog.Projects.Tasks as ProjectTasks
	|		on ProjectTasks.Ref = Projects.Ref
	|		and ProjectTasks.TimeType = value ( Enum.Time.Billable )
	|		and Projects.Pricing <> value ( Enum.ProjectsPricing.Amount )
	|	where Projects.Ref in ( &Projects )
	|	and not Projects.IsFolder ) as Projects
	|group by Projects.Project, Projects.TimeEntry, Projects.Employee, Projects.EmployeeDescription, Projects.HourlyRate
	|";
	q = new Query ( s );
	q.SetParameter ( "Projects", Projects );
	SetPrivilegedMode ( true );
	table = q.Execute ().Unload ();
	SetPrivilegedMode ( false );
	return CollectionsSrv.Serialize ( table );
	
EndFunction 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )
	
	Object.Services.Clear ();
	fillDocument ();
	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure fillDocument ()
	
	if ( Object.Customer.IsEmpty ()
		or Object.Currency.IsEmpty ()
		or Object.InvoiceMethod.IsEmpty ()
		or ( Object.Date = Date ( 1, 1, 1 ) ) ) then
		return;
	endif; 
	if ( Object.InvoiceMethod = PredefinedValue ( "Enum.InvoiceMethods.ByTimeEntries" ) ) then
		fillServices ();
	endif; 
	calcTotals ( Object );
	calcTotalMinutes ( ThisObject );
	
EndProcedure 

&AtClient
Procedure CustomerOnChange ( Item )
	
	setCurrency ( ThisObject );
	Object.Services.Clear ();
	fillDocument ();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange ( Item )
	
	Object.Services.Clear ();
	fillDocument ();
	
EndProcedure

&AtClient
Procedure InvoiceMethodOnChange ( Item )
	
	Object.Services.Clear ();
	fillDocument ();
	Appearance.Apply ( ThisObject, "Object.InvoiceMethod" );
	
EndProcedure

// *****************************************
// *********** Table Services

&AtClient
Procedure Fill ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif; 
	Forms.ClearTables ( Object.Services, "ClearTableConfirmation", ThisObject );
	
EndProcedure

&AtClient
Procedure ClearTableConfirmation ( Result, Params ) export
	
	if ( Object.Services.Count () > 0 ) then
		return;
	endif; 
	fillDocument ();
	
EndProcedure

&AtClient
Procedure ServicesOnEditEnd ( Item, NewRow, CancelEdit )
	
	calcTotalMinutes ( ThisObject );
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ServicesAfterDeleteRow ( Item )
	
	calcTotalMinutes ( ThisObject );
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ServicesTimeEntryOnChange ( Item )
	
	currentData = Items.Services.CurrentData;
	applyNewTimeEntry ( currentData );
	
EndProcedure

&AtClient
Procedure applyNewTimeEntry ( Row )
	
	fields = getTimeEntryFields ( getFillingParams ( Object ), Row.TimeEntry );
	fillServicesRow ( ThisObject, Row, fields );
	
EndProcedure 

&AtServerNoContext
Function getTimeEntryFields ( val Params, val TimeEntry )
	
	fields = new Structure ( "Project, Employee, TimeEntry, Minutes, Amount, HourlyRate", , , TimeEntry, 0, 0, 0 );
	timeEntries = new Array ();
	timeEntries.Add ( TimeEntry );
	table = getTimeEntries ( Params, timeEntries );
	if ( table.Count () > 0 ) then
		FillPropertyValues ( fields, table [ 0 ] );
	else
		fields.Project = DF.Pick ( TimeEntry, "Project" );
	endif; 
	return fields;
	
EndFunction 

&AtClient
Procedure ServicesProjectOnChange ( Item )
	
	currentData = Items.Services.CurrentData;
	applyNewProject ( currentData, Item );
	
EndProcedure

&AtClient
Procedure applyNewProject ( Row, Item )
	
	projects = new Array ();
	projects.Add ( Row.Project );
	table = Collections.DeserializeTable ( getProjectFields ( projects ) );
	if ( table.Count () = 1 ) then
		fillServicesRow ( ThisObject, Row, table [ 0 ] );
	else
		employeesList = getEmployeesList ( table );
		ShowChooseFromMenu ( new NotifyDescription ( "AddSelectedEmployee", ThisObject, Row ), employeesList, Item );
	endif; 
	
EndProcedure 

&AtClient
Function getEmployeesList ( Table )
	
	list = new ValueList ();
	list.LoadValues ( Table );
	for each item in list do
		item.Presentation = item.Value.EmployeeDescription;
	enddo; 
	return list;
	
EndFunction 

&AtClient
Procedure AddSelectedEmployee ( EmployeeItem, Row ) export
	
	if ( EmployeeItem = undefined ) then
		return;
	endif; 
	fillServicesRow ( ThisObject, Row, EmployeeItem.Value );
	
EndProcedure 

&AtClient
Procedure ServicesDurationOnChange ( Item )
	
	currentData = Items.Services.CurrentData;
	Conversion.AdjustTime ( currentData.Duration );
	calcMinutesByDuration ( currentData );
	calcAmount ( currentData );
	calcTaxes ( ThisObject, currentData );
	calcTotalTaxes ( currentData );
	
EndProcedure

&AtClient
Procedure calcMinutesByDuration ( Row )
	
	Row.Minutes = Conversion.DurationToMinutes ( Row.Duration );
	
EndProcedure 

&AtClient
Procedure ServicesHourlyRateOnChange ( Item )
	
	calcAmount ( Items.Services.CurrentData );
	
EndProcedure

&AtClient
Procedure calcAmount ( Row )
	
	amount = Row.HourlyRate * ( Row.Minutes / 60 );
	discount = amount / 100 * Row.DiscountRate;
	Row.Amount = amount - discount;
	
EndProcedure 

&AtClient
Procedure ServicesDiscountRateOnChange ( Item )
	
	currentData = Items.Services.CurrentData;
	calcAmount ( currentData );
	calcTaxes ( ThisObject, currentData );
	calcTotalTaxes ( currentData );
	
EndProcedure

&AtClient
Procedure ServicesAmountOnChange ( Item )
	
	currentData = Items.Services.CurrentData;
	calcHourlyRate ( currentData );
	calcTaxes ( ThisObject, currentData );
	calcTotalTaxes ( currentData );
	
EndProcedure

&AtClient
Procedure calcHourlyRate ( Row )
	
	factor = ( Row.Minutes / 60 ) * ( 1 - 0.01 * Row.DiscountRate );
	Row.HourlyRate = Row.Amount / factor;
	
EndProcedure 

&AtClient
Procedure ServicesSalesTaxAmount1OnChange ( Item )
	
	currentData = Items.Services.CurrentData;
	calcTotalTaxes ( currentData );
	
EndProcedure

&AtClient
Procedure ServicesSalesTaxAmount2OnChange ( Item )
	
	currentData = Items.Services.CurrentData;
	calcTotalTaxes ( currentData );
	
EndProcedure
