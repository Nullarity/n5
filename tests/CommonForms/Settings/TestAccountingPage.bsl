Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Settings / Application" );
form = With ( "Application Settings" );

Activate ( "#SetupDate" );

Set ( "#SetupDate", "2/2/2016" );
Next ();
Check ( "#SetupDate", "2/1/2016 12:00:00 AM" ); // Should be In the beginning of the month

// ***********************************
// Try to edit Folder
// ***********************************

table = Get ( "#Settings" );
table.Choose ();
Close ( DialogsTitle ); // Error message should be seen

// ***********************************
// Open and change parameter
// ***********************************

setupAccount = "12800";
setupDate = Format ( BegOfYear ( CurrentDate () ), "DLF=D" );

table = Activate ( "#Settings" );
GotoRow ( table, "Parameter", "Expense Report Account" );
table.Choose ();

With ( "Expense Repo*" );
Set ( "#Value", setupAccount );
Set ( "!SetupDate", setupDate );
Click ( "#FormOK" );

// ***********************************
// Find updated Value
// ***********************************

With ( form );
GotoRow ( table, "Value", setupAccount ); // Updated value should be found

// ********************************************
// Open this value again and see prefilled data
// ********************************************

table.Choose ();
With ( "Expense Repo*" );
Check ( "#Value", setupAccount );
Check ( "#SetupDate", setupDate + " 12:00:00 AM" );
