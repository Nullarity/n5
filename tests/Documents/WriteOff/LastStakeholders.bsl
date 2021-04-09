// Description:
// Tests copying stackeholders info from last document

Call ( "Common.Init" );
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Document.WriteOff" );
form = With ( "Write Off (cr*" );

approved = "Approved";
approvedPosition = "Approved position";
head = "Head";
headPosition = "Head position";
member1 = "Member1";
member1position = "Member1 position";
member2 = "Member2";
member2position = "Member2 position";

Activate ( "#GroupStakeholders" );
setValue ( "#Approved", approved );
setValue ( "#ApprovedPosition", approvedPosition );
setValue ( "#Head", head );
setValue ( "#HeadPosition", headPosition );

table = Activate ( "#Members" );
Call ( "Table.Clear", table );
Click ( "#MembersAdd" );
setValue ( "#MembersMember", member1 );
setValue ( "#MembersPosition", member1Position );
table.EndEditRow ();
Click ( "#MembersAdd" );
setValue ( "#MembersMember", member2 );
setValue ( "#MembersPosition", member2Position );

Click ( "#FormWrite" );
Close ();

// ************************************
// Check Stakeholders: should be filled
// ************************************

MainWindow.ExecuteCommand ( "e1cib/data/Document.WriteOff" );
form = With ( "Write Off (cr*" );

Activate ( "#GroupStakeholders" );
table = Activate ( "#Members" );
Check ( "#Approved", approved );
Check ( "#ApprovedPosition", approvedPosition );
Check ( "#Head", head );
Check ( "#HeadPosition", headPosition );
Check ( "#MembersMember [ 1 ]", member1, table );
Check ( "#MembersPosition [ 1 ]", member1Position, table );
Check ( "#MembersMember [ 2 ]", member2, table );
Check ( "#MembersPosition [ 2 ]", member2Position, table );

// ****************************
// Procedures
// ****************************

Procedure setValue ( Field, Value )

	form = CurrentSource;
	Choose ( Field );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", "String" );
	Click ( "#OK" );
	CurrentSource = form;
	Set ( Field, value );
	
EndProcedure