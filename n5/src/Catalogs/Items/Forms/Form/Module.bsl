// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	OptionalProperties.Load ( ThisObject );
	filterDepartments ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure filterDepartments ()
	
	DC.ChangeFilter ( DepartmentItems, "Item", Object.Ref, true );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		OptionalProperties.Load ( ThisObject );
		CopyingObject = Parameters.CopyingValue;
		fillNew ();
		filterDepartments ();
	endif; 
	setOptions ();
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
	|OpenObjectUsage enable inlist ( Object.ObjectUsage, Enum.PropertiesUsage.Inherit, Enum.PropertiesUsage.Special );
	|CostMethod Social CustomsGroup OfficialCode Producer Accuracy hide Object.Service or Object.Form;
	|Package CountPackages Weight hide Object.Service;
	|ItemForm hide Object.Service or Object.Product or Object.Series;
	|Product Features hide Object.Form;
	|Service hide Object.Form or Object.Series;
	|Series hide Object.Service or Object.Form;
	|Write show
	|not Object.Service
	|and Packages
	|and empty ( Object.Ref );
	|Package CountPackages enable
	|not Object.Service
	|and Packages
	|and filled ( Object.Ref );
	|DepartmentItems BOM show Object.Product;
	|DepartmentItems BOM enable Object.Product and filled ( Object.Ref );
	|CopyInfo show filled ( CopyingObject ) and Object.Product;
	|WriteProduct show Object.Product and empty ( Object.Ref );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setOptions ()
	
	Packages = Options.Packages ();
	p = new Structure ( "Visibility, Item" );
	p.Visibility = Packages and not Object.Service;
	p.Item = Object.Ref;
	SetFormFunctionalOptionParameters ( p );
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Object.Unit.IsEmpty () ) then
		Object.Unit = Application.Unit ();
	endif; 
	if ( not CopyingObject.IsEmpty () ) then
		Object.Package = undefined;
	endif; 
	if ( Parameters.FillingText <> "" ) then
		setFullDescription ( ThisObject );
	endif; 
	Object.VAT = Application.ItemsVAT ();
	Object.CostMethod = Application.ItemsCost ();
	
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

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not CopyingObject.IsEmpty () ) then
		copyDepartments ( CurrentObject );
	endif;

EndProcedure

&AtServer
Procedure copyDepartments ( CurrentObject )
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.DepartmentItems.CreateRecordSet ();
	r.Filter.Item.Set ( CopyingObject );
	r.Read ();
	departments = r.Unload ( , "Department" );
	departments.Columns.Add ( "Item" );
	departments.FillValues ( CurrentObject.Ref, "Item" );
	r = InformationRegisters.DepartmentItems.CreateRecordSet ();
	r.Load ( departments );
	r.Write ( false );

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	CopyingObject = undefined;
	filterDepartments ();
	setOptions ();
	Appearance.Apply ( ThisObject, "Object.Ref" );
	Appearance.Apply ( ThisObject, "CopyingObject" );
	
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
Procedure ServiceOnChange ( Item )
	
	applyService ();
	
EndProcedure

&AtServer
Procedure applyService ()
	
	if ( Object.Service ) then
		Object.CostMethod = undefined;
		Object.Social = false;
		Object.CustomsGroup = undefined;
		Object.OfficialCode = "";
		Object.Weight = 0;
		Object.Producer = undefined;
		Object.Accuracy = 0;
	else
		Object.CostMethod = Application.ItemsCost ();
	endif; 
	Appearance.Apply ( ThisObject, "Object.Service" );
	
EndProcedure

&AtClient
Procedure ProductOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.Product" );

EndProcedure

&AtClient
Procedure ItemFormOnChange ( Item )
	
	if ( not Object.Form
		and formInUse () ) then
		Object.Form = true;
	else
		applyForm ();
	endif;
	
EndProcedure

&AtClient
Function formInUse ()
	
	ref = Object.Ref;
	if ( ref.IsEmpty ()
		or formIsNew ( ref ) ) then
		return false;
	endif;
	Output.FormInUse ();
	return true;
	
EndFunction

&AtServerNoContext
Function formIsNew ( val Ref )
	
	s = "
	|select top 1 1
	|from Catalog.Ranges as Ranges
	|where Ranges.Item = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().IsEmpty ();
	
EndFunction

&AtClient
Procedure applyForm ()
	
	if ( Object.Form ) then
		Object.Social = false;
		Object.CustomsGroup = undefined;
		Object.OfficialCode = "";
		Object.Producer = undefined;
		Object.Accuracy = 0;
		Object.Features = undefined;
	endif; 
	Appearance.Apply ( ThisObject, "Object.Form" );
	
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
