Call ( "Common.Init" );
CloseAll ();

Call ( "Common.OpenList", Meta.Documents.Hiring );

Clear ( "#EmployeeFilter" );
Set ( "#DepartmentFilter", "Administration" );

Next ();