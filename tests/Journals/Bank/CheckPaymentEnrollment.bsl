// - Open Bank journal
// - Create, save & close Customer Payment
// - Check if current row gets focus correctly

Call ( "Common.Init" );
CloseAll ();

// Open Bank
Commando ( "e1cib/list/InformationRegister.Bank" );
list = With ( "Bank" );

// Create Payment
Click ( "#FormCreateDocument" );
CurrentSource.ExecuteChoiceFromMenu ( "Customer Payment" );
With ( "Customer Payment (cr*" );
Put ( "#Method", "Visa" );
memoID = Call ( "Common.GetID" );
Set ( "#Memo", memoID );
Click ( "#FormWrite" );
Close ();

// Check current row
With ( list );
Check ( "Memo", memoID, Get ( "#List" ) );
