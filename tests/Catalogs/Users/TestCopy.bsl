Call ( "Common.Init" );
CloseAll ();

// ***********************************
// Open Users List
// ***********************************

Call ( "Common.OpenList", Meta.Catalogs.Users );
table = GotoRow ( "#List", "Name", "admin" );
Click ( "#FormCopy" );

// *******************************************************
// Open a new user and check copied Administrator's rights
// *******************************************************

With ( "Users (cr*" );
table = Activate ( "#UserGroups" );
GotoRow ( table, "Folder", "Administrators" );
Check ( "#UsersGroupsUse", "Yes" );
