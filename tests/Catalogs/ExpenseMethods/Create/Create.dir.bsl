// Description:
// Creates a new PaymentOption
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.ExpenseMethods" );

form = With ( "Expense Methods (create)" );
if ( _ = undefined ) then
	name = "_Method: " + CurrentDate ();
	expense = "_Expense: " + CurrentDate ();
	account = "8111";
else
	name = _.Description;
	expense = _.Expense;
	account = _.Account;
endif;

Set ( "#Description", name );

table = Activate ( "#Expenses" );
Call ( "Table.AddEscape", table );
Click ( "#ExpensesAdd" );

Set ( "#ExpensesAccount", account, table );
Choose ( "#ExpensesExpense" );
name = expense;
params = Call ( "Common.Select.Params" );
params.Object = Meta.Catalogs.Expenses;
params.Search = name;
//params.App = "Core";
Call ( "Common.Select", params );
With ( form );
Click ( "#FormWrite" );
code = Fetch ( "Code" );
Close ();

return new Structure ( "Code, Description", code, name );


