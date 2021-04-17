Call ( "Common.Init" );
CloseAll ();

// ***********************************
// Open Department list and Company
// filter should be visible
// ***********************************

MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Departments" );
With ( "Departments" );
CheckState ( "#CompanyFilter", "Visible" );

// ***********************************
// Open Department list from Company
// and Company filter should be invisible
// ***********************************

CloseAll ();
MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Companies" );
With ( "Companies" );
Click ( "#FormChange" );
With ( "*(Companies)" );
window = GetWindow ();
Click ( "Departments", GetLinks () );
With ( Get ( "Departments", window ) );
CheckState ( "#CompanyFilter", "Visible", false );
