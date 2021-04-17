form = With ( "Sales*" );
Click ( "#CmdLoadVariant" );
With ( "Report variants" );
table = Activate ( "#SettingsTable" );
search = new Map ();
search [ "Date" ] = "";
search [ "Description" ] = "By Months";
table.GotoRow ( search, RowGotoDirection.Down );
Click ( "#FormChoose" );

With ( form );

filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
item.ValueFrom = _.ValueFrom;
item.ValueTo = _.ValueTo;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Department";
item.Value = _.Department;
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Warehouse";
item.Value = _.Warehouse;
filters.Add ( item );

p = Call ( "Common.Report.Params" );
p.Filters = filters;

Call ( "Common.Report.FillFilters", p );
Click ( "#GenerateReport" );

settings = Activate ( "#UserSettings" );
settings.GotoFirstRow ();
search = new Map ();
search.Insert ( "Setting", "Chart" );
settings.GotoRow ( search );

Activate ( "#UserSettingsUse", settings );
Click ( "#UserSettingsUse", settings );

With ( form );
Click ( "#GenerateReport" );

CheckTemplate ( "#Result" );



