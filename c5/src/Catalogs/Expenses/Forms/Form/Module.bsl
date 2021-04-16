// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	OptionalProperties.Load ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	if ( Object.Ref.IsEmpty () ) then
		OptionalProperties.Load ( ThisObject );
		fillNew ();
	endif; 
	OptionalProperties.Access ( ThisObject );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Description lock PropertiesData.ChangeName;
	|FullDescription lock PropertiesData.ChangeDescription;
	|PropertiesGroup show inlist ( Object.ObjectUsage, Enum.PropertiesUsage.Inherit, Enum.PropertiesUsage.Special );
	|OpenObjectUsage enable inlist ( Object.ObjectUsage, Enum.PropertiesUsage.Inherit, Enum.PropertiesUsage.Special )
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

// *****************************************
// *********** Page Properties

&AtClient
Procedure ObjectUsageOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.ObjectUsage" );
	
EndProcedure

&AtClient
Procedure OpenObjectUsage ( Command )
	
	OptionalProperties.Open ( ThisObject, PredefinedValue ( "Enum.PropertiesScope.Item" ), Object.ObjectUsage );
	
EndProcedure

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
