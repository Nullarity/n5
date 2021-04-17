// Open journal Bank
// Count journal rows
// Create & Save a new Customer Payment
// Change date and save again
// Refresh jornal and check if rows count is only 1 more than last time (we created 1 document only)

Call ( "Common.Init" );
CloseAll ();

// Open journal
Commando ( "e1cib/list/InformationRegister.Bank" );
list = With ( "Bank" );

// Calc rows count
table = Get ( "#List" );
count = Call ( "Table.Count", table );

// Create Customer Payment
Click ( "#FormCreateDocument" );
CurrentSource.ExecuteChoiceFromMenu ( "Customer Payment" );

With ( "Customer Payment (cr*" );
Put ( "#Method", "Bank Transfer" );
Click ( "#FormWrite" );
number = Fetch ( "#Number" );

// Set previos day
date = Date ( Fetch ( "#Date" ) ) - 86400;
Set ( "#Date", Format ( date, "DFL=D" ) );
Click ( "#FormWrite" );

// Check rows count
With ( list, true );
Click ( "#FormRefresh" );

currentCount = Call ( "Table.Count", table );

if ( ( currentCount - count ) <> 1 ) then
	Stop ( "A Customer Payment #" + number + " is represented twice in the Bank journal. Only 1 record per document should exist" );
endif;