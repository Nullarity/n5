// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setListsMultipleChoice ();
	setMultipleChoiceVisibility ();
	setDefaultButton ( ThisObject, Items.Pages.CurrentPage );
	
EndProcedure

&AtServer
Procedure setListsMultipleChoice ()
	
	Items.List.MultipleChoice = Parameters.MultipleSelection;
	Items.Users.MultipleChoice = Parameters.MultipleSelection;
	Items.Customers.MultipleChoice = Parameters.MultipleSelection;
	Items.Employees.MultipleChoice = Parameters.MultipleSelection;
	
EndProcedure 

&AtServer
Procedure setMultipleChoiceVisibility ()
	
	Items.MultipleChoice.Visible = Parameters.MultipleSelection;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setDefaultButton ( Form, CurrentPage )
	
	items = Form.Items;
	if ( CurrentPage = Items.UsersPage ) then
		items.UsersChoose.DefaultButton = true;
	elsif ( CurrentPage = items.CustomersPage ) then
		items.CustomersChoose.DefaultButton = true;
	elsif ( CurrentPage = items.EmployeesPage ) then
		items.EmployeesChoose.DefaultButton = true;
	elsif ( CurrentPage = items.AddressBookPage ) then
		items.AddressesChoose.DefaultButton = true;
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Employees

&AtClient
Procedure PagesOnCurrentPageChange ( Item, CurrentPage )
	
	setDefaultButton ( ThisObject, CurrentPage );
	
EndProcedure

// *****************************************
// *********** Group Employees

&AtClient
Procedure ProjectFilterOnChange ( Item )
	
	filterByProject ();
	
EndProcedure

&AtServer
Procedure filterByProject ()
	
	if ( ProjectFilter.IsEmpty () ) then
		DC.ChangeFilter ( Employees, "Ref", undefined, false );
	else
		employeesList = getEmployeesList ();
		DC.ChangeFilter ( Employees, "Ref", employeesList, true, DataCompositionComparisonType.InListByHierarchy );
	endif; 
	
EndProcedure 

&AtServer
Function getEmployeesList ()
	
	s = "
	|select allowed distinct Tasks.Employee as Employee
	|from Catalog.Projects.Tasks as Tasks
	|where Tasks.Ref = &Project
	|";
	q = new Query ( s );
	q.SetParameter ( "Project", ProjectFilter );
	return q.Execute ().Unload ().UnloadColumn ( "Employee" );
	
EndFunction 

&AtClient
Procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	chooseValue ( Item, Value, StandardProcessing );
	
EndProcedure

&AtClient
Procedure chooseValue ( Item, Value, StandardProcessing )
	
	StandardProcessing = false;
	addresses = new Array ();
	if ( Item.MultipleChoice ) then
		for each selectedValue in Value do
			addresses.Add ( Item.RowData ( selectedValue ).Email );
		enddo; 
	else
		addresses.Add ( Item.RowData ( Value ).Email );
	endif; 
	NotifyChoice ( StrConcat ( addresses, ", " ) );
	
EndProcedure 

&AtClient
Procedure UsersValueChoice ( Item, Value, StandardProcessing )
	
	chooseValue ( Item, Value, StandardProcessing );
	
EndProcedure

&AtClient
Procedure CustomersValueChoice ( Item, Value, StandardProcessing )
	
	chooseValue ( Item, Value, StandardProcessing );
	
EndProcedure

&AtClient
Procedure EmployeesValueChoice ( Item, Value, StandardProcessing )
	
	chooseValue ( Item, Value, StandardProcessing );
	
EndProcedure
