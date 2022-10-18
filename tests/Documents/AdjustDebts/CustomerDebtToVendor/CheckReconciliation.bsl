p = Call ( "Common.Report.Params" );
p.Path = "e1cib/app/Report.Reconciliation";
p.Title = "Reconciliation Stat*";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
item.ValueFrom = BegOfYear ( CurrentDate () );
item.ValueTo = EndOfYear ( CurrentDate () );
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Organization";
item.Value = _.Customer;
filters.Add ( item );

p.Filters = filters;

With ( Call ( "Common.Report", p ) );
Click ( "#GenerateReport" );
CheckTemplate ( "#Result" );
