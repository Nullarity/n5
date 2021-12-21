// Create a new serie

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Catalog.Items.Create");
Click("#Series");
Click("#FormWrite");
Click("Series", GetLinks());
With();
Click("#FormCreate");
With();
Set ("#Lot", TestingID());
Click("#FormWrite");
