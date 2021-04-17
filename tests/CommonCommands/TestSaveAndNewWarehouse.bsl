Commando ( "e1cib/list/Catalog.Warehouses" );
With ( "Warehouses" );
p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = _.Warehouse;
Call ( "Common.Find", p );
Click ( "#FormChange" );
With ( "*(Warehouses)" );
Click ( "#FormCommonCommandSaveAndNew" );
With ( "Warehouses (create)" );

CloseAll ();

