p = Call ( "Common.Report.Params" );
p.Path = "Sales / Customer debt details";
p.Title = "Customer debt details";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Name = "Customer";
item.Value = _;
filters.Add ( item );

p.Filters = filters;
With ( Call ( "Common.Report", p ) );
CheckTemplate ( "#Result" );
