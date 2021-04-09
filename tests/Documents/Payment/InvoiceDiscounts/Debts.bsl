p = Call ( "Common.Report.Params" );
p.Path = "e1cib/app/Report.Debts";
p.Title = "Accounts Receivable";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Name = "Customer";
item.Value = _;
filters.Add ( item );

p.Filters = filters;

form = With ( Call ( "Common.Report", p ) );

Click ( "#GenerateReport" );

With ( form );

CheckTemplate ( "#Result" );
