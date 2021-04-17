Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Document.IntangibleAssetsWriteOff" );
With ( "Intangible Assets Write Off (cr*" );

Click ( "#ShowDetails" );
Click ( "#ItemsAdd" );
Put ( "#ItemsExpenseAccount", "8111" );
Choose ( "#ItemsDim2" );

// Choice form should not have Company filter
CheckState ( "#CompanyFilter", "Visible", false, "Departments" );
