// Create a new Payment
// Check if Reference and ReferenceDate are visible
// Set Method = Cash
// Check if Reference and ReferenceDate are not visible

Call ( "Common.Init" );
CloseAll ();

// Create a new Customer Payment
Commando ( "e1cib/data/Document.Payment" );
With ( "Customer Payment (cr*" );

// Check if Reference and ReferenceDate are visible
CheckState ( "#Reference, #ReferenceDate", "Visible" );

// Set Method = Cash
Put ( "#Method", "Cash" );

// Check if Reference and ReferenceDate are not visible
CheckState ( "#Reference, #ReferenceDate", "Visible", false );
