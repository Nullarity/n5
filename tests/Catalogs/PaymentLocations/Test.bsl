// Create a Payment Location and play with fields

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Catalog.PaymentLocations.Create");
CheckState ("#Remote", "Enable", false);
Click("#Register");
CheckState ("#Remote", "Enable");