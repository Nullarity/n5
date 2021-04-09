p = new Structure ();
p.Insert ( "Description", "_Warehouse: " + BegOfDay ( CurrentDate () ) );
p.Insert ( "Company" );
p.Insert ( "Production", false );
p.Insert ( "Department" );
return p;