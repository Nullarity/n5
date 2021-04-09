p = Call ( "Common.Report.Params" );
p.Path = "Sales / Accounts Receivable";
p.Title = "Accounts Receivable";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Name = "Customer";
item.Value = _;
filters.Add ( item );

p.Filters = filters;

ClientWindow = MainWindow;
CommandInterface = ClientWindow.GetCommandInterface ();
CommandInterfaceGroup = CommandInterface.GetObject ( , "Section panel" );
CommandInterfaceButton = CommandInterfaceGroup.GetObject ( , "Sales" );
CommandInterfaceButton.Click ();

ClientWindow = MainWindow;
CommandInterface = ClientWindow.GetCommandInterface ();
CommandInterfaceGroup = CommandInterface.GetObject ( , "Functions menu" );
CommandInterfaceGroup1 = CommandInterfaceGroup.GetObject ( , "Reports" );
CommandInterfaceButton = CommandInterfaceGroup1.GetObject ( , "Accounts Receivable" );

CommandInterfaceButton.Click ();

form = With ( Call ( "Common.Report", p ) );
Click ( "#GenerateReport" );

With ( form );

CheckTemplate ( "#Result" );
