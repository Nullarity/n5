// - Create a new Item
// - Fill magento parameters and save

Call ( "Common.Init" );
CloseAll ();

return;

Commando ( "e1cib/command/Catalog.Items.Create" );
With ( "Items (cr*" );

id = Call ( "Common.GetID" );
Set ( "#Description", "Item " + id );
Click ( "#Magento" );
Set ( "#price", 15 );
Set ( "#sku", "SKU-" + id );
Set ( "#meta_title", "meta_title " + id );
Set ( "#meta_keyword", "meta_keyword " + id );
Set ( "#meta_description", "<b>meta_description</b> " + id );
Next ();
Click ( "#FormWrite" );
