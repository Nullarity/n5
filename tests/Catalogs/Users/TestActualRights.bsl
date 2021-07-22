Call ( "Common.Init" );

CloseAll ();
MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Users" );

list = With ( "Users" );

p = Call ( "Common.Find.Params" );
p.Where = "Name";
p.What = "admin";
Call ( "Common.Find", p );

With ( list );
Click ( "#FormChange" );

form = With ( "admin (*" );
table = Activate ( "#Membership" );
search = new Map ();
search.Insert ( "Group", "Managers" );
table.GotoRow ( search, RowGotoDirection.Down );
Click ( "#MembershipUse" );
Click ( "#MembershipUse" );
Click ( "Individual rights" );

editor = With ( "Individual rights" );
table = Activate ( "#Rights" );
Click ( "#RightsUse" );
Click ( "OK" );

With ( "admin (*" );
Click ( "Individual rights" );
editor = With ( "Individual rights" );
table = Activate ( "#Rights" );
Click ( "#RightsUse" );
Click ( "OK" );

With ( "admin (*" );
Click ( "#FormWriteAndClose" );//"Save and *" );