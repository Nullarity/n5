Call ( "Common.Init" );
CloseAll ();

p = Call ( "Common.Report.Params" );
p.Path = "Accounting / Account Balance";
p.Title = "Account Balance*";
filters = p.Filters;
filter = Call ( "Common.Report.Filter" );
filter.Name = "Account";
filter.Value = "2171";
filters.Add ( filter );

Call ( "Common.Report", p );
