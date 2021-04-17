Call ( "Common.Init" );
CloseAll ();

// ***********************************
// Create folder with properties
// ***********************************

list = Call ( "Common.OpenList", _ );
Click ( "#FormCreateFolder" );
form = With ( "* (create*" );

// ***********************************
// Create properties
// ***********************************

Click("#FormWrite");
code = Fetch("#Code");
Pick ( "#ItemsUsage", "Current Object Settings" );
Click ( "#OpenItemsUsage" );
With ( "Properties*" );
table = Activate ( "#Tree" );

Click ( "#TreeAdd" );
Set ( "#TreeName", "System", table );
Click ( "#TreeCommon" );
Click ( "#TreeLabelName" );
Click ( "#FormOK" );

// ***********************************
// Check if common field stays
// ***********************************

With ();
Click ( "#OpenItemsUsage" );
With ( "Properties*" );
Tree = Get ( "#Tree" );
search = new Map ();
search [ "Description" ] = "System";
Tree.GotoRow ( search );
Check ("#TreeCommon", "Yes");

// ************************************
// Check if make it private again works
// ************************************

Click ("#TreeCommon");
Click("#FormOK");
With();
Click ( "#OpenItemsUsage" );
With ();
Tree = Get ( "#Tree" );
search = new Map ();
search [ "Description" ] = "System";
Tree.GotoRow ( search );
Check ("#TreeCommon", "No");

// ***************************************
// Make it common again and create an item
// ***************************************

Click ( "#TreeCommon" );
Click ( "#FormOK" );
With();
Click ("#FormWrite");
Close ();
With ( list );

caption = Call ( "Common.Meta.Caption", _ );
With ( caption );

table = Get ( "#List" );
table.GotoFirstRow ();
search = new Map ();
search [ "Code" ] = code;
table.GotoRow ( search );
table.Choose ();

// ***********************************
// Create a new Item
// ***********************************

Click ( "#FormCreate" );
With ( "* (crea*" );
Set ( "System", "Nipel" );

// ***********************************
// Check name, description
// ***********************************

Activate ( "#Description" );
Check ( "#Description", "System: Nipel" );
CheckState ( "#Description", "ReadOnly" );

// ************************************************
// Save & Reread properties for testing saved data
// ************************************************

Click ( "#FormWrite" );
Click ( "#FormReread" );
