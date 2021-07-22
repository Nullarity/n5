Call ( "Common.Init" );
CloseAll ();

// ***********************************
// Open Users List
// ***********************************

Call ( "Common.OpenList", Meta.Catalogs.Users );
table = GotoRow ( "#List", "Name", "admin" );
Click ( "#FormCopy" );
