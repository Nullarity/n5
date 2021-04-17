// Create a new Item
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
Click ( "#FormWrite" );

// Add Record
Click ( "Accounts", GetLinks () );
With ( id + " (Items)" );
Click ( "#FormCreate" );

// Should be disabled
With ( "Items (cr*" );
CheckState ( "#GroupExpense", "Enable", false );

// Should be enabled
Clear ( "#Item" );
Next ();
CheckState ( "#GroupExpense", "Enable" );

// Should be disabled
Put ( "#Item", id );
Next ();
CheckState ( "#GroupExpense", "Enable", false );
