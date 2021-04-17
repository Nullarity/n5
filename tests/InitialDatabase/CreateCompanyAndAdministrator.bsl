company = "Наша компания";

// ******************
// Rename our company
// ******************

//Commando ( "e1cib/list/Catalog.Organizations" );
//With ( "Organizations" );
//GotoRow ( "#List", "Name", "Our company" );
//Click ( "#FormChange" );
//With ( "*(Organizations)" );
//Set ( "#Description", company );
//Set ( "#ObjectUsage", "Properties Are Not Defined" );
//Click ( "#FormWriteAndClose" );

//Commando ( "e1cib/data/Catalog.Organizations" );
//With ( "Organizations (create)" );
//Put ( "#Description", company );
//Set ( "#ObjectUsage", "Properties Are Not Defined" );
//Click ( "#FormWriteAndClose" );

// ******************
// Create our company
// ******************

Commando ( "e1cib/command/Catalog.Companies.Create" );
With ( "Companies (cr*" );
Set ( "#Description", company );
Put ( "#BalanceControl", "Control Always" );
//Put ( "#Organization", company );
Click ( "#CostOnline" );
Click ( "#FormWriteAndClose" );

// ********************
// Create Administrator
// ********************

Commando ( "e1cib/command/Catalog.Users.Create" );
form = With ( "Users (cr*" );
Set ( "#Description", "Администратор" );
Set ( "#Email", "user@domain.com" );
Click ( "#MustChangePassword" );
Put ( "#Company", company );

Activate ( "#GroupRights" );
Click ( "#RightsEditRights" );
With ( "Individual rights" );
table = Get ( "#Rights" );
GotoRow ( table, "Right", "General" );
table.Expand ();
GotoRow ( table, "Right", "Administrator" );
Click ( "#RightsUse" );
Click ( "#Commit" );

With ( form );
Click ( "#FormWrite" );

Click ( "#CreateEmployee" );
With ( "Individuals (cr*" );
Click ( "#FormWriteAndClose" );

With ( form );
Click ( "#FormWriteAndClose" );
