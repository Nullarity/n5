Commando ( "e1cib/list/Catalog.Items" );
With ( "Items" );
Clear ( "#WarehouseFilter" );
p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = _.Item;
Call ( "Common.Find", p );
Click ( "#FormChange" );
With ( "*(Items)" );
Click ( "#FormCommonCommandSaveAndNew" );
With ( "Items (create)" );

CloseAll ();

