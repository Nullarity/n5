// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( not SessionParameters.TenantUse ) then
		Cancel = true;
		return;
	endif;
	if ( Forms.InsideMobileHomePage ( ThisObject ) ) then
		Cancel = true;
		return;
	endif;
	UserTasks.InitList ( List );
	loadFixedFilters ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|CustomerFilter show empty ( FixedProjectFilter ) and empty ( FixedCustomerFilter );
	|EmployeeFilter show empty ( FixedEmployeeFilter );
	|Project show empty ( FixedProjectFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFixedFilters ()
	
	Parameters.Filter.Property ( "Project", FixedProjectFilter );
	Parameters.Filter.Property ( "Individual", FixedEmployeeFilter );
	Parameters.Filter.Property ( "Customer", FixedCustomerFilter );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	uploadFixedFilters ();
	
EndProcedure

&AtClient
Procedure uploadFixedFilters ()
	
	if ( not FixedCustomerFilter.IsEmpty () ) then
		CustomerFilter = FixedCustomerFilter;
	endif; 
	if ( not FixedEmployeeFilter.IsEmpty () ) then
		EmployeeFilter = FixedEmployeeFilter;
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CustomerFilterOnChange ( Item )
	
	filterByCustomer ();
	
EndProcedure

&AtServer
Procedure filterByCustomer ()
	
	DC.ChangeFilter ( List, "Customer", CustomerFilter, not CustomerFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure EmployeeFilterOnChange ( Item )
	
	filterByEmployee ();
	
EndProcedure

&AtServer
Procedure filterByEmployee ()
	
	DC.ChangeFilter ( List, "Individual", EmployeeFilter, not EmployeeFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure InvoiceFilterOnChange ( Item )
	
	filterByInvoice ();	
	
EndProcedure

&AtServer
Procedure filterByInvoice ()
	
	if ( not AccessRight ( "View", Metadata.InformationRegisters.TimeEntryInvoices )  ) then
		return;
	endif; 
	setFilter = ( InvoiceFilter = 1 );
	filterValue = ( InvoiceFilter = 0 );
	DC.ChangeFilter ( List, "Invoiced", filterValue, setFilter );
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure

