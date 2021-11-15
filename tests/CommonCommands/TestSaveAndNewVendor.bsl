Commando ( "e1cib/list/Catalog.Organizations" );
With ( "Organizations" );
p = Call ( "Common.Find.Params" );
p.Where = "Name";
p.What = _.Vendor;
Call ( "Common.Find", p );
Click ( "#FormChange" );
With ( "*(Organizations)" );
Click ( "#FormCommonCommandSaveAndNew" );
With ( "Organizations (create)" );

CloseAll ();

