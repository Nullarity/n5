Connect ();
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Document.VendorInvoice" );
form = With ( "Vendor Invoice (cre*" );

date = Date ( Fetch ( "#Date" ) );

table = Activate ( "#FixedAssets" );
Click ( "#FixedAssetsAdd" );
With ( "Fixed Asset" );
testRow ( date );
Close ();
With ( form );
table = Activate ( "#IntangibleAssets" );
Click ( "#IntangibleAssetsAdd" );
With ( "Intangible Asset" );
testRow ( date );

// **************************
// Procedures
// **************************

Procedure testRow ( Date )

	// **************************
	// Test enable / disable
	// **************************

	CheckState ( "#Starting", "Enable", false );
	Click ( "#Charge" );
	CheckState ( "#Starting", "Enable" );

	// **************************
	// Test default starting from
	// **************************

	nextMonth = "" + BegOfMonth ( AddMonth ( Date, 1 ) );
	Check ( "#Starting", nextMonth );

	// **************************
	// Test starting changes
	// **************************

	nextMonth = AddMonth ( Date, 2 );
	nextMonthBegin = "" + BegOfMonth ( nextMonth );

	Set ( "#Starting", Format ( nextMonth, "DLF=D" ) );
	Next ();
	Check ( "#Starting", nextMonthBegin );

EndProcedure
