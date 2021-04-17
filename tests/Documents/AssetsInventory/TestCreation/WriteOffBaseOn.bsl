form = With ( "Assets Write *" );
Set( "#ExpenseAccount", _.ExpenseAccount );
form.GotoNextItem ();
Set ( "Expenses", _.Expense );
form.GotoNextItem ();
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Assets Write Off *" );
Call ( "Common.CheckLogic", "#TabDoc" );
