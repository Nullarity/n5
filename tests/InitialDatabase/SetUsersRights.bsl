//Call ( "Common.Init" );
//CloseAll ();

Commando ( "e1cib/list/Catalog.UserGroups" );
With ( "Groups" );
p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = "Users";
Call ( "Common.Find", p );
Click ( "#FormChange" );
try
	With ( "Users (User Groups)" );
	Put ( "#Description", "Пользователи" );
	Click ( "#RightsUnmarkAllRights" );
	// General
	table = Activate ( "#Rights" );
	table.Expand ();
	goToRow ( table, "SaveSettings" );
	Click ( "#RightsUse" );
	
	Click ( "#RightsChangesConfirmRights" );
	
	// Sections
	goToRow ( table, "Sections" );
	table.Expand ();
	goToRow ( table, "TimeSubsystem" );
	Click ( "#RightsUse" );
	goToRow ( table, "SettingsSubsystem" );
	Click ( "#RightsUse" );
	
	// Tools
	goToRow ( table, "Tools" );
	table.Expand ();
	goToRow ( table, "Calendar" );
	Click ( "#RightsUse" );
	Click ( "#RightsChangesConfirmRights" );
	
	Click ( "#FormWriteAndClose" );
except
endtry;

//
//	Add Full Rights
//
Commando ( "e1cib/data/Catalog.UserGroups" );
With ( "User Groups (create)" );
Put ( "#Description", "Полные права" );
Click ( "#UsersContextMenuAdd" );
table = Activate ( "#Users" );
Put ( "#UsersUser", "Администратор", table );
table = Activate ( "#Rights" );
table.Expand ();
goToRow ( table, "Administrator" );
Click ( "#RightsUse" );
Click ( "#FormWriteAndClose" );

Procedure goToRow ( Table, Right )

	search = new Map ();
	search.Insert ( "Right", Right );
	table.GotoRow ( search, RowGotoDirection.Down );

EndProcedure