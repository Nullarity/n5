Call ( "Common.Init" );
CloseAll ();

env = Run ( "getEnv", "272B331B#" );

Commando ( "e1cib/data/Document.IntangibleAssetsWriteOff" );
form = With ( "Intangible Assets Write Off (create)" );

table = Activate ( "#Items" );
Click ( "#ItemsDelete" );
for each row in env.Items do
	
	Click ( "#ItemsAdd" );
	Put ( "#ItemsItem", row.Name, table );
	
enddo;
Put ( "#ExpenseAccount", Env.ExpenseAccount );
Put ( "#Dim1", env.Expense );
Put ( "#Dim2", env.Department );

Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
With ( "Records: Intangible Assets Write Off*" );
Call ( "Common.CheckLogic", "#TabDoc" );

With ( form );
Click ( "#FormUndoPosting" );

