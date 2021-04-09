Call ( "Common.Init" );
CloseAll ();

env = getEnv ();

// Create Account / Subaccount
Commando ( "e1cib/list/ChartOfAccounts.General" );
list = With ( "Chart of Accounts" );
Click ( "#FormList" );
Click ( "#FormCreate" );
With ( "Chart of Accounts (cr*" );
account = Env.Account;
Set ( "#Code", account );
Set ( "#Description", account );
Put ( "#Class", "Non-Posting" );
Click ( "#FormWrite" );
Check ( "#Folder", "No" );
Close ();

With ( list );
Click ( "#FormCreate" );
With ( "Chart of Accounts (cr*" );
Set ( "#Code", Env.Subaccount );
Set ( "#Description", Env.Subaccount );
Put ( "#Parent", account );
Put ( "#Class", "Non-Posting" );
Click ( "#FormWrite" );
Check ( "#Folder", "No" );
Close ();

// Check parent folder: flag Folder should be Yes
With ( list );
GotoRow ( Get ( "#List" ), "Code", account );
Click ( "#FormChange" );
With ( account + "*" );
Check ( "#Folder", "Yes" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.GetID" );
	subname = Right ( id, 6 );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Account", "A" + subname );
	p.Insert ( "Subaccount", "B" + subname );
	return p;

EndFunction
