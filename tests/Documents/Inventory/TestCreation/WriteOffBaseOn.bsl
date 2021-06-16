form = With ( "Write *" );
Set( "#ExpenseAccount", "8111" );
form.GotoNextItem ();
Set ( "Expenses", "_Inventory" );
form.GotoNextItem ();
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Write Off *" );
Call ( "Common.CheckLogic", "#TabDoc" );
