// Create new Invoice
// Add new Item and check Items list caption
// Add new Service and check Services list caption

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/data/Document.Invoice");
form = With ("Invoice (cr*");

// Add new Item
Click ("#ItemsTableAdd");
Choose("#ItemsItem");

// Check caption: Items
With("Items");
Close ();
With ( form );

// Add new Item
Click ("#ServicesAdd");
Choose("#ServicesItem");

// Check caption: Items
With("Services");
