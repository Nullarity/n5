// Create Item and test flags: Service, Product, Form

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Catalog.Items.Create");

// Normal state
list = new Array ();
list.Add ( "#OfficialCode" );
list.Add ( "#Service" );
list.Add ( "#Product" );
list.Add ( "#ItemForm" );
list.Add ( "#CountPackages" );
list.Add ( "#Package" );
list.Add ( "#Weight" );
list.Add ( "#Producer" );
list.Add ( "#CustomsGroup" );
list.Add ( "#Social" );
list.Add ( "#CostMethod" );
list.Add ( "#Accuracy" );
CheckState(StrConcat(list,","), "Visible");

list = new Array ();
list.Add ( "#BOM" );
list.Add ( "#DepartmentItems" );
CheckState(StrConcat(list,","), "Visible", false);

// Service
Click("#Service");
list = new Array ();
list.Add ( "#BOM" );
list.Add ( "#DepartmentItems" );
list.Add ( "#OfficialCode" );
list.Add ( "#ItemForm" );
list.Add ( "#CountPackages" );
list.Add ( "#Package" );
list.Add ( "#Weight" );
list.Add ( "#Producer" );
list.Add ( "#CustomsGroup" );
list.Add ( "#Social" );
list.Add ( "#CostMethod" );
list.Add ( "#Accuracy" );
CheckState(StrConcat(list,","), "Visible", false);

// Product
Click("#Service");
Click("#Product");
list = new Array ();
list.Add ( "#ItemForm" );
CheckState(StrConcat(list,","), "Visible", false);

list = new Array ();
list.Add ( "#BOM" );
list.Add ( "#DepartmentItems" );
CheckState(StrConcat(list,","), "Visible");

// Form
Click("#Product");
Click("#ItemForm");
list = new Array ();
list.Add ( "#OfficialCode" );
list.Add ( "#Service" );
list.Add ( "#Product" );
list.Add ( "#Producer" );
list.Add ( "#CustomsGroup" );
list.Add ( "#Social" );
list.Add ( "#CostMethod" );
list.Add ( "#Accuracy" );
list.Add ( "#BOM" );
list.Add ( "#DepartmentItems" );
CheckState(StrConcat(list,","), "Visible", false);
