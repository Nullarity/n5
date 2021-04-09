Commando ( "e1cib/list/Catalog.Departments" );
With ( "Departments" );
p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = _.Department;
Call ( "Common.Find", p );
Click ( "#FormChange" );
With ( "*(Departments)" );
Click ( "#FormCommonCommandSaveAndNew" );
With ( "Departments (create)" );

CloseAll ();
