// - Create standard schedule

p = Call ( "Catalogs.Schedules.Create.Params" );
p.Description = "Пятидневка";
Call ( "Catalogs.Schedules.Create", p );
