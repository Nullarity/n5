Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.InternalOrder );

With ( form );

Choose ( "#WarehouseFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = "Main";
Call ( "Common.Select", p );

With ( form );
warehouse = Fetch ( "#WarehouseFilter" );
Click ( "#FormCreate" );

With ( "Internal Order (create)" );
Check ( "#Warehouse", warehouse );
