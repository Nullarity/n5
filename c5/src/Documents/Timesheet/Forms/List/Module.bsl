
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
	init ();
	loadFixedFilters ();
	loadParams ();
	if ( not CustomerFilter.IsEmpty () ) then
		filterByCustomer ();
	endif; 
	if ( FixedEmployeeFilter.IsEmpty () ) then
		filterByMe ();
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|EmployeeFilter show empty ( FixedEmployeeFilter );
	|CustomerFilter show empty ( FixedCustomerFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure init ()
	
	params = List.Parameters;
	params.SetParameterValue ( "Customer", undefined );
	params.SetParameterValue ( "Project", undefined );
	params.SetParameterValue ( "CustomerSelected", false );
	params.SetParameterValue ( "ProjectSelected", false );
	UserTasks.InitList ( List );
	
EndProcedure 

&AtServer
Procedure loadFixedFilters ()
	
	Parameters.Filter.Property ( "Individual", FixedEmployeeFilter );
	Parameters.Property ( "Customer", FixedCustomerFilter );
	CustomerFilter = FixedCustomerFilter;
	
EndProcedure 

&AtServer
Procedure loadParams ()
	
	Parameters.Property ( "Customer", FixedCustomerFilter );
	CustomerFilter = FixedCustomerFilter;
	
EndProcedure 

&AtServer
Procedure filterByCustomer ()
	
	List.Parameters.SetParameterValue ( "CustomerSelected", not CustomerFilter.IsEmpty () );
	List.Parameters.SetParameterValue ( "Customer", CustomerFilter );
	DC.ChangeFilter ( List, "Totals.Customer", CustomerFilter, not CustomerFilter.IsEmpty () );
	
EndProcedure 

&AtServer
Procedure filterByMe ()
	
	EmployeeFilter = DF.Pick ( SessionParameters.Employee, "Individual" );
	filterByEmployee ();
	
EndProcedure

&AtServer
Procedure filterByEmployee ()
	
	DC.ChangeFilter ( List, "Individual", EmployeeFilter, not EmployeeFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	uploadFixedFilters ();
	
EndProcedure

&AtClient
Procedure uploadFixedFilters ()
	
	if ( not FixedEmployeeFilter.IsEmpty () ) then
		EmployeeFilter = FixedEmployeeFilter;
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure ApproveTimesheet ( Command )
	
	Output.ApproveTimesheetConfirmation ( ThisObject );

EndProcedure

&AtClient
Procedure ApproveTimesheetConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		startApproving ( Items.List.SelectedRows, UUID );
		Progress.Open ( UUID, ThisObject, new NotifyDescription ( "DocumentsApproved", ThisObject ), true );
	endif; 
	
EndProcedure 

&AtServerNoContext
Procedure startApproving ( val Timesheets, val UUID )

	p = DataProcessors.ApproveTimesheet.GetParams ();
	p.Timesheets = Timesheets;
	args = new Array ();
	args.Add ( "ApproveTimesheet" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, UUID, , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure DocumentsApproved ( Result, Params ) export
	
	Items.List.Refresh ();
	
EndProcedure

&AtClient
Procedure EmployeeFilterOnChange ( Item )
	
	filterByEmployee ();
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange ( Item )
	
	filterByStatus ();
	
EndProcedure

&AtServer
Procedure filterByStatus ()
	
	DC.ChangeFilter ( List, "TimesheetStatus", StatusFilter, not StatusFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure CustomerFilterOnChange ( Item )
	
	applyCustomer ();
	
EndProcedure

&AtServer
Procedure applyCustomer ()
	
	filterByCustomer ();
	filterByProject ();

EndProcedure 

&AtClient
Procedure ProjectFilterOnChange ( Item )
	
	filterByProject ();
	
EndProcedure

&AtServer
Procedure filterByProject ()
	
	List.Parameters.SetParameterValue ( "ProjectSelected", not ProjectFilter.IsEmpty () );
	List.Parameters.SetParameterValue ( "Project", ProjectFilter );
	DC.ChangeFilter ( List, "Totals.Project", ProjectFilter, not ProjectFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
