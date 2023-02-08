// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	init ();
	
EndProcedure

&AtServer
Procedure init () 

	params = List.Parameters;
	params.SetParameterValue ( "CurrentDate", CurrentDate () );
	params.SetParameterValue ( "Nothing", "" ); // Do not use "" is the query. Parameter should be used to avoid string shrinking
	params.SetParameterValue ( "NotHired", Output.NotHired () );
	params.SetParameterValue ( "HiredFrom", Output.HiredFrom () );
	params.SetParameterValue ( "FiredFrom", Output.FiredFrom () );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DepartmentFilterOnChange ( Item )
	
	filterByDepartment ();
	
EndProcedure

&AtServer
Procedure filterByDepartment ()
	
	DC.ChangeFilter ( List, "Department", DepartmentFilter, not DepartmentFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure StatusFilterOnChange ( Item )
	
	filterByStatus ();
	
EndProcedure

&AtServer
Procedure filterByStatus ()
	
	DC.ChangeFilter ( List, "Hired", ? ( StatusFilter = 1,  Output.HiredFrom (), Output.FiredFrom () ), StatusFilter > 0 );
	
EndProcedure

// *****************************************
// *********** Table List

&AtServerNoContext
Procedure ListOnGetDataAtServer ( ItemName, Settings, Rows )
	
	if ( IsInRole ( Metadata.Roles.HR ) ) then
		formatStatus ( Rows );
	endif;
	
EndProcedure

&AtServerNoContext
Procedure formatStatus ( Rows )

	for each item in Rows do
		data = item.Value.Data;
		data.Status = data.Hired + Format ( data.Period, "DLF=D" );
	enddo;

EndProcedure

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
