Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Catalog.DeductionsClassifier" );
form = With ( "Deductions (cr*" );

id = Call ( "Common.GetID" );
Set ( "#Code", id );
Set ( "#Description", id );

// Check Rates availability
CheckState ( "#Rates", "Enable", false );
Click ( "#FormWrite" );
CheckState ( "#Rates", "Enable" );

// Add a new Rate
Click ( "#RatesCreate" );
With ( "Deduction Rates (cr*" );
Check ( "#Deduction", id );
Set ( "#Rate", "10000" );
Click ( "#FormWriteAndClose" );
