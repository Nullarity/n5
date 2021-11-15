Commando ( "e1cib/list/Catalog.Employees" );
With ( "Employees" );
p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = _.Employee;
Call ( "Common.Find", p );
Click ( "#FormChange" );
With ( "*(Individuals)" );
Click ( "#FormCommonCommandSaveAndNew" );
With ( "Individuals (create)" );

CloseAll ();
