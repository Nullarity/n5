// Opens report Allocation by passed SO number

p = Call ( "Common.Report.Params" );
p.Path = "Purchases / Allocation";
p.Title = "Allocation";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Name = "Sales Order";
item.Value = _;
item.UserFilter = false;
filters.Add ( item );

p.Filters = filters;
With ( Call ( "Common.Report", p ) );

CheckTemplate ( "#Result" );

Close ();