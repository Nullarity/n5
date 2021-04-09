// Create a new Service
// Goto Accounts
// Create a new record
// Check form appearance

Call ( "Common.Init" );
CloseAll ();

// Create Service
id = Call ( "Common.GetID" );
Commando ( "e1cib/data/Catalog.Items" );
With ( "Items (cr*" );
Set ( "#Description", id );
Click ( "#Service" );
Click ( "#FormWrite" );

// Add Record
Click ( "Accounts", GetLinks () );
With ( id + " (Items)" );
Click ( "#FormCreate" );

// Should be enabled
With ( "Items (cr*" );
Put ( "#Item", id );
CheckState ( "#GroupExpense", "Enable" );

// Still should be enabled
Clear ( "#Item" );
Next ();
CheckState ( "#GroupExpense", "Enable" );
