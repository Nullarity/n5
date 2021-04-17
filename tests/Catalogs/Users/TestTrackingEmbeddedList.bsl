Call ( "Common.Init" );
CloseAll ();

Call ( "Common.OpenList", Meta.Catalogs.Users );
Click ( "#FormChange" );

With ( "* (Users)" );
Click ( "Tracking", GetLinks () );

With ( "Tracking" );
CheckState ( "#UserFilter", "Visible", false );
