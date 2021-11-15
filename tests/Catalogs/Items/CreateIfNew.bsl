// Description:
// Just creates an Item
//
// Parameters:
// P1: name of item

p = Call ( "Common.CreateIfNew.Params" );
p.Object = Meta.Catalogs.Items;
p.Description = _;
creation = Call ( "Catalogs.Items.Create.Params" );
creation.Description = _;
creation.CountPackages = false;
p.CreationParams = creation;
Call ( "Common.CreateIfNew", p );
