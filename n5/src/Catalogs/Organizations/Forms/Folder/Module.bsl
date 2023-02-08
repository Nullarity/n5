// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	OptionalProperties.Load ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		OptionalProperties.Load ( ThisObject );
		fillNew ();
	endif; 
	OptionalProperties.Access ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|PropertiesGroup show inlist ( Object.ObjectUsage, Enum.PropertiesUsage.Inherit, Enum.PropertiesUsage.Special );
	|OpenObjectUsage enable inlist ( Object.ObjectUsage, Enum.PropertiesUsage.Inherit, Enum.PropertiesUsage.Special );
	|OpenGroupsUsage enable inlist ( Object.GroupsUsage, Enum.PropertiesUsage.Inherit, Enum.PropertiesUsage.Special );
	|OpenItemsUsage enable inlist ( Object.ItemsUsage, Enum.PropertiesUsage.Inherit, Enum.PropertiesUsage.Special );
	|Description lock PropertiesData.ChangeName;
	|FullDescription lock PropertiesData.ChangeDescription
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Parameters.FillingText <> "" ) then
		setFullDescription ( ThisObject );
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setFullDescription ( Form )
	
	object = Form.Object;
	object.FullDescription = object.Description;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not OptionalProperties.Check ( ThisObject ) ) then
		Cancel = true;
	endif; 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DescriptionOnChange ( Item )
	
	setFullDescription ( ThisObject );
	
EndProcedure

&AtClient
Procedure ParentOnChange ( Item )
	
	applyParent ();
	
EndProcedure

&AtServer
Procedure applyParent ()
	
	OptionalProperties.Load ( ThisObject );
	
EndProcedure 

&AtClient
Procedure ObjectUsageOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.ObjectUsage" );
	
EndProcedure

&AtClient
Procedure OpenObjectUsage ( Command )
	
	OptionalProperties.Open ( ThisObject, PredefinedValue ( "Enum.PropertiesScope.Item" ), Object.ObjectUsage );
	
EndProcedure

&AtClient
Procedure GroupsUsageOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.GroupsUsage" );
	
EndProcedure

&AtClient
Procedure OpenGroupsUsage ( Command )
	
	OptionalProperties.Open ( ThisObject, PredefinedValue ( "Enum.PropertiesScope.Groups" ), Object.GroupsUsage );
	
EndProcedure

&AtClient
Procedure ItemsUsageOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.ItemsUsage" );
	
EndProcedure

&AtClient
Procedure OpenItemsUsage ( Command )
	
	OptionalProperties.Open ( ThisObject, PredefinedValue ( "Enum.PropertiesScope.Items" ), Object.ItemsUsage );
	
EndProcedure

// *****************************************
// *********** Group Properties

&AtClient
Procedure PropertiesChanged ( Changed, Form ) export
	
	updateProperties ();
	
EndProcedure 

&AtServer
Procedure updateProperties ()
	
	OptionalProperties.Load ( ThisObject );
	
EndProcedure 

&AtClient
Procedure PropertyOnChange ( Item ) export
	
	OptionalProperties.ApplyConditions ( ThisObject, Item );
	OptionalProperties.BuildDescription ( ThisObject );
	OptionalProperties.ChangeHost ( ThisObject, Item );
	
EndProcedure 
