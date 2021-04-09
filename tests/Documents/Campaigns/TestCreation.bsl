// Create a new Campaign

Call ( "Common.Init" );
CloseAll ();

id = Call("Common.GetID");
Commando("e1cib/command/Catalog.Campaigns.Create");
With();
Set("#Description", "Campaign " + id);

Click("#FormWriteAndClose");