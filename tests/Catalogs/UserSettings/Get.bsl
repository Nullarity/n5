MainWindow.ExecuteCommand ( "e1cib/data/Catalog.UserSettings" );
With ( "* (User Settings)" );

data = new Structure ();
data.Insert ( "Company", Fetch ( "#Company" ) );
data.Insert ( "Department", Fetch ( "#Department" ) );
data.Insert ( "Warehouse", Fetch ( "#Warehouse" ) );
data.Insert ( "PaymentLocation", Fetch ( "#PaymentLocation" ) );

Close ();
return data;
