// Create a common property and a private property.
// Create a condition: if common property = x then private property becomes visible

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.GetID" );

#region createItem
Commando("e1cib/command/Catalog.Items.Create");
Set("#Description", "Item " + id);
Set("#ObjectUsage", "Current Object Settings");
Click("#FormWrite");
#endregion

#region createCommonProperty
Click("#OpenObjectUsage");
With();
Tree = Get ( "#Tree" );
Click ( "#TreeAdd" );
commonProperty = "Common Property" + id;
Set ( "#TreeName", commonProperty, Tree );
Click("#TreeCommon");
#endregion

#region createPrivateProperty
Click("#Add");
Set ( "#TreeName", "Test", Tree );
Activate ( "#PageConditions" ); // Conditions
Click ( "#Save" );
#endregion

#region createCondition
Conditions = Get ( "#Conditions" );
Click ( "#ConditionsCreate" );
With ();
Conditions = Get ( "#Conditions" );
Click ( "#ConditionsAdd" );
Choose ( "#ConditionsProperty" );
With();
With ( "Properties" );
GotoRow(Get ( "#List" ), "Description", commonProperty);
Click("#FormChoose");
With();
Set ( "#ConditionsValue", "x", Conditions );
Properties = Get ( "#Properties" );
Click ( "#PropertiesAdd" );
Properties.EndEditRow ();
Set ( "#PropertiesProperty", "Test", Properties );
Next();
Click ( "#FormWriteAndClose" );
With ();
Click ( "#FormOK" );
#endregion

#region checkCondition
With();
CheckState("Test", "Visible", false);
Set("Common Property*", "x");
Next();
CheckState("Test", "Visible");
#endregion