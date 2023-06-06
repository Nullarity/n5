// Test Signed all flag

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A171" );

OpenMenu ( "Sections panel / Sales" );
OpenMenu ( "Functions menu / Customers" );

With ();
Click ( "#FormCreate" );

With ();
Set ( "#Description", "Customer " + id );
Click ( "#FormWrite" );
Click ( "Contracts", GetLinks () );

With ( "Contracts" );
List = Get ( "#List" );
List.Choose ();

With ();
Get ( "#Signed" ).SetCheck ();
Click ( "#FormWriteAndClose" );
Choose ( "#DateStart" );
Set ( "#DateStart", " 6/01/2023" );
Choose ( "#DateEnd" );
Set ( "#DateEnd", " 6/30/2035" );
Click ( "#FormWriteAndClose" );

With ( "Contracts" );
List = Get ( "#List" );
List.GoOneLevelDown ();
Click ( "#FormCreate" );

With ();
Set ( "#Description", id );
Get ( "#Signed" ).SetCheck (); // Remove the sign flag
Click ( "#FormWriteAndClose" );

With ( "Contracts" );
List = Get ( "#List" );
List.GoOneLevelUp ();
List.Choose ();

With ();
Click ( "#FormWriteAndClose" );

With ( "Contracts" );
List = Get ( "#List" );
List.GoOneLevelDown ();
List.Choose ();
