// Create Item with two properties: Model and Size
// Add condition: if Model = Wheel then Size should appear

Call ( "Common.Init" );
CloseAll ();

itemName = "Some: " + CurrentDate ();

// Create Item
Call ( "Common.OpenList", _ );
Click ( "#FormCreate" );
form = With ( "* (cr*" );

// Add Property: Model
Pick ( "#ObjectUsage", "Current Object Settings" );
Click ( "#OpenObjectUsage" );
With ( DialogsTitle );
Click ( "Yes" );

With ( "Properties*" );
table = Activate ( "#Tree" );

Click ( "#TreeAdd" );
Set ( "#TreeName", "Model" );
Pick ( "#TreeType", "Property Values" );

Activate ( "#TreeDefaultValue" ).Create ();
With();
Set("#Description", "Wheel");
Click("#FormWriteAndClose");
With();

// Add Property: Size
Click ( "#TreeAdd" );
Set ( "#TreeName", "Size" );
Pick ( "#TreeType", "Number" );

// Add condition
Activate ( "#PageConditions" );
Click ( "#Save" );

Conditions = Get ( "#Conditions" );
Click ( "#ConditionsCreate" );

With ( "Property Conditions (create)" );
Conditions = Get ( "#Conditions" );
Click ( "#ConditionsAdd" );
Choose ( "#ConditionsProperty", Conditions );

With ( "Properties" );
Click ( "#FormChoose" );

With();
Set ( "#ConditionsValue", "Wheel" );
Next ();

// Add Size as dependant field
Click ( "#PropertiesAdd" );
properties = Get ( "#Properties" );
properties.EndEditRow ();
Set ( "#PropertiesProperty", "Size", properties );
Click ( "#FormWriteAndClose" );

With ();
Click("#FormOK");

// Change Model in item and check Size visibility
With();
Activate ( "Model" ).Create ();
With();
Set("#Description", "Handlebar");
Click("#FormWriteAndClose");
With();
Set("Model", "Handlebar");
Next();
CheckState("Size", "Visible", false);
Set("Model", "Wheel");
Next();
CheckState("Size", "Visible");