// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	initList ();
	loadFixedSettings ();
	filterByStatus ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Owner show empty ( FixedCustomerFilter ) and empty ( CustomerFilter );
	|CustomerFilter show empty ( FixedCustomerFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure initList ()
	
	UserTasks.InitList ( List );
	List.Parameters.SetParameterValue ( "CurrentDate", CurrentSessionDate () );
	
EndProcedure 

&AtServer
Procedure loadFixedSettings ()
	
	Parameters.Filter.Property ( "Owner", FixedCustomerFilter );
	
EndProcedure 

&AtServer
Procedure filterByStatus ()
	
	if ( StatusFilter = 0 ) then
		DC.ChangeFilter ( List, "Completed", false, true );
	elsif ( StatusFilter = 1 ) then
		DC.ChangeFilter ( List, "Completed", true, true );
	elsif ( StatusFilter = 2 ) then
		DC.DeleteFilter ( List, "Completed" );
	endif; 
	
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
	
EndProcedure 

// *****************************************
// *********** Group Main

&AtClient
Procedure ClientOnChange ( Item )
	
	filterByClient ();
	
EndProcedure

&AtServer
Procedure filterByClient ()
	
	DC.ChangeFilter ( List, "Owner", CustomerFilter, not CustomerFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "CustomerFilter" );

EndProcedure

&AtClient
Procedure EmployeeOnChange ( Item )
	
	filterByEmployee ();
	
EndProcedure

&AtServer
Procedure filterByEmployee ()
	
	filter = not EmployeeFilter.IsEmpty ();
	if ( filter ) then
		DC.SetParameter ( List, "Employee", EmployeeFilter, true );
	else
		DC.SetParameter ( List, "Employee", undefined, false );
	endif;

EndProcedure

&AtClient
Procedure FilterByStatusOnChange ( Item )
	
	filterByStatus ();
	
EndProcedure

&AtClient
Procedure InvoiceFilterOnChange ( Item )
	
	filterByInvoice ();	
	
EndProcedure

&AtServer
Procedure filterByInvoice ()
	
	if ( not AccessRight ( "View", Metadata.InformationRegisters.ProjectInvoices )  ) then
		return;
	endif; 
	setFilter = ( InvoiceFilter = 1 );
	filterValue = ( InvoiceFilter = 0 );
	DC.ChangeFilter ( List, "Invoiced", filterValue, setFilter );
	
EndProcedure 

&AtClient
Procedure TagFilterOnChange ( Item )
	
	filterByTag ();
	
EndProcedure

&AtServer
Procedure filterByTag ()
	
	DC.ChangeFilter ( List, "Tag", TagFilter, not TagFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
