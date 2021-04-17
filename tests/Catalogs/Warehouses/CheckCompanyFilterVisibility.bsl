Call ( "Common.Init" );
CloseAll ();
list = Call ( "Common.OpenList", Meta.Documents.Invoice );

Choose ( "#WarehouseFilter" );
With ( "Warehouses" );
CheckState ( "#CompanyFilter", "Visible" );
Close ();

With ( list );
Click ( "#FormCreate" );
With ( "Invoice (create)" );
Choose ( "#Warehouse" );

With ( "Warehouses" );
CheckState ( "#CompanyFilter", "Visible", false );
