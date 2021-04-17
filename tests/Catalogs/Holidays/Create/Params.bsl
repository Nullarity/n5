p = new Structure ();
p.Insert ( "Description" );
p.Insert ( "Year", Year ( CurrentDate () ) );
p.Insert ( "Days", new Array () ); // Call ( "Catalogs.Holidays.Create.Day" )
return p;