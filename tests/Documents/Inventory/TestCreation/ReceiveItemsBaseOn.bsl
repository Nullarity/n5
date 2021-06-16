form = With ( "Receive *" );
Set( "#Account", "8111" );
form.GotoNextItem ();
Set ( "#Dim1", "_Inventory" );
form.GotoNextItem ();
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Receive *" );
Call ( "Common.CheckLogic", "#TabDoc" );
