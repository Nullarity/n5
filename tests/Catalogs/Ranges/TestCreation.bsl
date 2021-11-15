// Create a new virtual range
// Check autoregistration process

Call ( "Common.Init" );
CloseAll ();

prefix = Right(Call("Common.GetID"), 5);

Commando("e1cib/list/Catalog.Ranges");
Click("#FormCreate");
With();
Set("#Prefix", prefix);
Set("#Start", 1);
Set("#Finish", 30);
Set("#Length", 3);
Click("#WriteAndClose");

// Check autoregistration process
With ("Enroll Range*");
Click("#FormWriteAndClose");

Disconnect();