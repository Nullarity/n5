Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Catalog.Items" );
With ( "Items (cr*" );

item = Call ( "Common.GetID" );
Set ( "#Description", item );
Click ( "#FormWrite" );
Click ( "Gallery", GetLinks () );
With ( item );
CheckState ( "Click here to *", "Visible" );
