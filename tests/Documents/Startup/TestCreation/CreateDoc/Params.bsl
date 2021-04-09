params = new Structure ();
id = Call ( "Common.ScenarioID", "24ED90A4#" );
params.Insert ( "ID", id );
params.Insert ( "Department", "LVI Department " + id );
params.Insert ( "Expense", "LVI expense " + id );
params.Insert ( "Employee", "Startup employee " + id );
return params;
