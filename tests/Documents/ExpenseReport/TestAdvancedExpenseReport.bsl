Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Settings / Application" );
With ( "Application Settings" );
if ( Fetch ( "#AdvancedExpenseReport" ) = "Yes" ) then
	Click ( "#AdvancedExpenseReport" );
endif;
Click ( "#FormWriteAndClose" );
MainWindow.ExecuteCommand ( "e1cib/list/Document.ExpenseReport" );
With ( "Expense Reports" );
Click ( "#FormCreate" );
With ( "Expense Report (create)" );
try
	Click ( "#FixedAssetsAdd" );
	error = true;
except
	error = false;
endtry;
if ( error ) then	
	Stop ( "Fixed Assets must be invisible" );
endif;	
CloseAll ();
OpenMenu ( "Settings / Application" );
With ( "Application Settings" );
Click ( "#AdvancedExpenseReport" );
Click ( "#FormWriteAndClose" );

MainWindow.ExecuteCommand ( "e1cib/list/Document.ExpenseReport" );
With ( "Expense Reports" );
Click ( "#FormCreate" );
With ( "Expense Report (create)" );
Click ( "#FixedAssetsAdd" );
