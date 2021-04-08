&AtClient
Procedure Open ( Form, Scope, Usage ) export
	
	p = new Structure ();
	p.Insert ( "Form", Form );
	p.Insert ( "Scope", Scope );
	p.Insert ( "Usage", Usage );
	if ( saveRequired ( Form, Usage ) ) then
		Output.SaveNewObject ( ThisObject, p );
	else
		openProperties ( p );
	endif; 
	
EndProcedure 

&AtClient
Function saveRequired ( Form, Usage )
	
	return Form.Object.Ref.IsEmpty ()
	and Usage = PredefinedValue ( "Enum.PropertiesUsage.Special" );
	
EndFunction 

&AtClient
Procedure SaveNewObject ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( Params.Form.Write () ) then
		openProperties ( Params );
	endif; 
	
EndProcedure 

&AtClient
Procedure openProperties ( Params )
	
	form = Params.Form;
	object = form.Object;
	data = findSource ( object, Params.Scope, Params.Usage );
	source = data.Source;
	if ( source = undefined ) then
		Output.ParentPropertiesNotFound ();
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Object", source );
	p.Insert ( "Scope", data.Scope );
	caller = new NotifyDescription ( "PropertiesChanged", form );
	OpenForm ( "CommonForm.Properties", p, form, , , , caller );
	
EndProcedure 

Function findSource ( Object, Scope, Usage )
	
	result = new Structure ( "Scope, Source" );
	if ( Usage = PredefinedValue ( "Enum.PropertiesUsage.Special" ) ) then
		result.Scope = Scope;
		result.Source = Object.Ref;
	else
		if ( Object.IsFolder ) then
			result.Scope = PredefinedValue ( "Enum.PropertiesScope.Groups" );
		else
			result.Scope = PredefinedValue ( "Enum.PropertiesScope.Items" );
		endif;
		result.Source = OptionalPropertiesSrv.GetOwner ( Object.Ref, Object.Parent, result.Scope );
	endif; 
	return result;
	
EndFunction 

&AtServer
Procedure Load ( Form ) export
	
	oldValues = Form.Object.Properties.Unload ();
	resetProperties ( Form );
	data = getProperties ( Form );
	loadProperties ( Form, data, oldValues );
	loadAppearance ( Form, data );
	OptionalProperties.ApplyConditions ( Form );
	OptionalProperties.BuildDescription ( Form );
	Appearance.Apply ( Form, "PropertiesData.ChangeName" );
	Appearance.Apply ( Form, "PropertiesData.ChangeDescription" );
	
EndProcedure 

&AtServer
Procedure resetProperties ( Form )
	
	Form.Object.Properties.Clear ();
	data = Form.PropertiesData;
	data.Properties.Clear ();
	data.ChangeName = false;
	data.ChangeDescription = false;
	
EndProcedure 

&AtServer
Function getProperties ( Form )
	
	object = Form.Object;
	ref = object.Ref;
	tableName = "Catalog." + ref.Metadata ().Name + ".Properties";
	s = "
	|// #Properties
	|select Properties.Mandatory as Mandatory, Properties.ToolTip as ToolTip, Properties.Ref as Property,
	|	Properties.Description as Name, Properties.Position as Position, Properties.Host as Host,
	|	case when ObjectProperties.Value is null then Properties.DefaultValue else ObjectProperties.Value end as Value,
	|	Properties.InDescription as InDescription, Properties.InName as InName,
	|	Properties.LabelDescription as LabelDescription, Properties.LabelName as LabelName,
	|	Properties.Control as Control, Properties.Folder as Folder, Properties.GroupType as GroupType,
	|	Properties.Folder.Control as ParentControl, Properties.ClearButton as ClearButton,
	|	Properties.HorizontalStretch as HorizontalStretch, Properties.Width as Width, Properties.Title as Title,
	|	Properties.ShowTitle as ShowTitle, Properties.GroupAppearance as GroupAppearance, Properties.ValueType as ValueType,
	|	Properties.DefaultValue as DefaultValue, Properties.Minimum as Minimum, Properties.Maximum as Maximum
	|from ChartOfCharacteristicTypes.Properties as Properties
	|	//
	|	// ObjectProperties
	|	//
	|	left join " + tableName +  " as ObjectProperties
	|	on ObjectProperties.Ref = &Ref
	|	and ObjectProperties.Property = Properties.Ref
	|	and not ObjectProperties.Property.DeletionMark
	|where Properties.Owner = &Source
	|and Properties.Scope = &Scope
	|and not Properties.Common
	|and not Properties.DeletionMark
	|union all
	|select Properties.Mandatory, Properties.Property.ToolTip, Properties.Property,
	|	Properties.Property.Description as Name, Properties.Position, Properties.Host,
	|	case when ObjectProperties.Value is null then Properties.DefaultValue else ObjectProperties.Value end,
	|	Properties.Property.InDescription, Properties.Property.InName,
	|	Properties.Property.LabelDescription, Properties.Property.LabelName,
	|	Properties.Property.Control, Properties.Folder, Properties.Property.GroupType,
	|	Properties.Folder.Control, Properties.Property.ClearButton,
	|	Properties.Property.HorizontalStretch, Properties.Property.Width, Properties.Property.Title,
	|	Properties.Property.ShowTitle as ShowTitle, Properties.Property.GroupAppearance as GroupAppearance, Properties.Property.ValueType as ValueType,
	|	Properties.DefaultValue as DefaultValue, Properties.Property.Minimum as Minimum, Properties.Property.Maximum as Maximum
	|from InformationRegister.CommonProperties as Properties
	|	//
	|	// ObjectProperties
	|	//
	|	left join " + tableName +  " as ObjectProperties
	|	on ObjectProperties.Ref = &Ref
	|	and ObjectProperties.Property = Properties.Property
	|	and not ObjectProperties.Property.DeletionMark
	|where Properties.Owner = &Source
	|and Properties.Scope = &Scope
	|and not Properties.Property.DeletionMark
	|order by Position
	|;
	|// #Conditions
	|select Conditions.Ref as Ref, Conditions.Item as Item, Conditions.Parent as Parent, Conditions.Operator as Operator,
	|	Conditions.Property as Property, Conditions.Value as Value
	|from Catalog.PropertyConditions.Conditions as Conditions
	|where Conditions.Ref.Owner = &Source
	|and Conditions.Ref.Scope = &Scope
	|and not Conditions.Ref.DeletionMark
	|order by Conditions.Ref.Code, Conditions.LineNumber
	|;
	|// #Fields
	|select Properties.Ref as Ref, Properties.Property as Property
	|from Catalog.PropertyConditions.Properties as Properties
	|where Properties.Ref.Owner = &Source
	|and Properties.Ref.Scope = &Scope
	|and not Properties.Ref.DeletionMark
	|order by Properties.Ref.Code, Properties.LineNumber
	|;
	|// #Appearance
	|select Catalog.Ref as Ref, Catalog.Format as Format
	|from Catalog.PropertyConditions as Catalog
	|where Catalog.Owner = &Source
	|and Catalog.Scope = &Scope
	|and not Catalog.DeletionMark
	|";
	env = SQL.Create ( s );
	q = env.Q;
	data = findSource ( object, Enums.PropertiesScope.Item, object.ObjectUsage );
	q.SetParameter ( "Ref", ref );
	q.SetParameter ( "Source", data.Source );
	q.SetParameter ( "Scope", data.Scope );
	SQL.Perform ( env );
	return env;
	
EndFunction

&AtServer
Procedure loadProperties ( Form, Data, OldValues )
	
	table = Data.Properties;
	propertiesData = Form.PropertiesData;
	properties = propertiesData.Properties;
	changeName = false;
	changeDescription = false;
	rootGroup = preparePlace ( Form );
	groups = new Map ();
	for each row in table do
		changeName = changeName or row.InName;
		changeDescription = changeDescription or row.InDescription;
		propertyRow = properties.Add ();
		FillPropertyValues ( propertyRow, row );
		control = row.Control;
		if ( control = Enums.Controls.Label ) then
			continue;
		endif;
		item = newField ( Form, row, rootGroup, groups );
		if ( control = Enums.Controls.Folder ) then
			prepareGroup ( Form, row, item );
		else
			prepareField ( Form, table, row, item, OldValues );
		endif; 
	enddo; 
	propertiesData.ChangeName = changeName;
	propertiesData.ChangeDescription = changeDescription;

EndProcedure 

&AtServer
Function preparePlace ( Form )
	
	items = Form.Items;
	place = items.PropertiesGroup;
	children = place.ChildItems;
	i = children.Count () - 1;
	while ( i >= 0 ) do
		items.Delete ( children [ i ] );
		i = i - 1;
	enddo; 
	return place;
	
EndFunction 

&AtServer
Function newField ( Form, Row, Root, Groups )
	
	place = ? ( Row.Folder.IsEmpty (), Root, Groups [ Row.Folder ] );
	name = itemName ( Row );
	if ( Row.Control = Enums.Controls.Folder ) then
		field = Form.Items.Add ( name, Type ( "FormGroup" ), place );
		Groups [ row.Property ] = field;
	else
		field = Form.Items.Add ( name, Type ( "FormField" ), place );
	endif;
	return field;
	
EndFunction 

Function itemName ( Row )
	
	return namePrefix () + Format ( Row.Position, "NG=" );

EndFunction 

Function namePrefix ()
	
	return "_";
	
EndFunction 

&AtServer
Procedure prepareGroup ( Form, Row, Field )
	
	Field.Type = FormGroupType.UsualGroup;
	Field.ShowTitle = Row.ShowTitle;
	Field.Title = Row.Title;
	if ( Row.GroupType = Enums.Groups.Horizontal ) then
		Field.Group = ChildFormItemsGroup.Horizontal;
	elsif ( Row.GroupType = Enums.Groups.Vertical ) then
		Field.Group = ChildFormItemsGroup.Vertical;
	else
		Field.Group = ChildFormItemsGroup.HorizontalIfPossible;
	endif; 
	value = Row.GroupAppearance;
	if ( value = Enums.GroupAppearance.None ) then
		Field.Representation = UsualGroupRepresentation.None;
	elsif ( value = Enums.GroupAppearance.Normal ) then
		Field.Representation = UsualGroupRepresentation.NormalSeparation;
	elsif ( value = Enums.GroupAppearance.Strong ) then
		Field.Representation = UsualGroupRepresentation.StrongSeparation;
	elsif ( value = Enums.GroupAppearance.Weak ) then
		Field.Representation = UsualGroupRepresentation.WeakSeparation;
	endif; 
	
EndProcedure

&AtServer
Procedure prepareField ( Form, Table, Row, Field, OldValues )
	
	index = loadField ( Form, Table, Row, OldValues );
	Field.DataPath = "Object.Properties[" + Format ( index, "NG=" ) + "].Value";
	Field.Type = FormFieldType.InputField;
	Field.Title = Row.Name;
	Field.Width = Row.Width;
	Field.Enabled = true;
	Field.Readonly = false;
	Field.ChooseType = false;
	Field.OpenButton = false;
	list = parametersList ( Table, Row );
	if ( list <> undefined ) then
		Field.ChoiceParameters = list;
	endif;
	if ( Row.Mandatory ) then
		Field.AutoMarkIncomplete = true;
	endif; 
	value = Row.HorizontalStretch;
	if ( value = Enums.YesNoAuto.Yes ) then
		Field.HorizontalStretch = true;
	elsif ( value = Enums.YesNoAuto.No ) then
		Field.HorizontalStretch = false;
	endif; 
	value = Row.ClearButton;
	if ( value = Enums.YesNoAuto.Yes ) then
		Field.ClearButton = true;
	elsif ( value = Enums.YesNoAuto.No ) then
		Field.ClearButton = false;
	endif; 
	tooltip = new Array ();
	value = Row.ToolTip;
	if ( value <> "" ) then
		tooltip.Add ( value );
	endif; 
	value = Row.Minimum;
	if ( value <> "" ) then
		tooltip.Add ( Output.MinumumPropertyValue ( new Structure ( "Value", value ) ) );
		Field.MinValue = Conversion.StringToNumber ( value );
	endif; 
	value = Row.Maximum;
	if ( value <> "" ) then
		tooltip.Add ( Output.MaximumPropertyValue ( new Structure ( "Value", value ) ) );
		Field.MaxValue = Conversion.StringToNumber ( value );
	endif; 
	Field.ToolTip = StrConcat ( tooltip, "; " );
	Field.SetAction ( "OnChange", "PropertyOnChange" );
	
EndProcedure 

&AtServer
Function loadField ( Form, Table, Row, OldValues )
	
	valueRow = Form.Object.Properties.Add ();
	FillPropertyValues ( valueRow, Row );
	oldValue = OldValues.Find ( Row.Property, "Property" );
	if ( oldValue = undefined ) then
		value = valueRow.Value;
	else
		value = oldValue.Value;
	endif; 
	valueRow.Value = Row.ValueType.AdjustValue ( value );
	return valueRow.LineNumber - 1;
		
EndFunction 

&AtServer
Function parametersList ( Table, Row )
	
	list = new Array ();
	if ( Row.ValueType.ContainsType ( Type ( "CatalogRef.PropertyValues" ) ) ) then
		list.Add ( new ChoiceParameter ( "Filter.Owner", Row.Property ) );
	endif;
	host = Row.Host;
	if ( not host.IsEmpty () ) then
		list.Add ( new ChoiceParameter ( "Filter.Filter", Table.Find ( host, "Property" ).Value ) );
	endif;
	if ( list.Count () = 0 ) then
		return undefined;
	else
		return new FixedArray ( list );
	endif;
	
EndFunction 

&AtServer
Procedure loadAppearance ( Form, Data )
	
	tables = Form.PropertiesData;
	tables.Conditions.Load ( Data.Conditions );
	tables.Fields.Load ( Data.Fields );
	tables.Appearance.Load ( Data.Appearance );
	
EndProcedure 

Procedure ApplyConditions ( Form, Item = undefined ) export
	
	userData = Form.Object.Properties;
	data = Form.PropertiesData;
	conditions = data.Conditions;
	formats = data.Appearance;
	fields = data.Fields;
	property = itemProperty ( Form.PropertiesData.Properties, Item );
	groupAnd = PredefinedValue ( "Enum.ConditionTypes.GroupAnd" );
	cleanInvisibility = Item <> undefined;
	filter = new Structure ( "Ref" );
	for each ref in getConditions ( conditions, property ) do
		filter.Ref = ref;
		rows = conditions.FindRows ( filter );
		result = evalCondition ( userData, rows, 0, 0, groupAnd );
		format = formats.FindRows ( filter ) [ 0 ].Format;
		rows = fields.FindRows ( filter );
		applyFormat ( result, Form, rows, format, cleanInvisibility );
	enddo; 

EndProcedure 

Function itemProperty ( Properties, Item )
	
	if ( Item = undefined ) then
		return undefined;
	endif; 
	position = Number ( StrReplace ( Item.Name, namePrefix (), "" ) );
	return Properties.FindRows ( new Structure ( "Position", position ) ) [ 0 ].Property;

EndFunction 

Function getConditions ( Conditions, Property )
	
	refs = new Array ();
	for each row in Conditions do
		if ( Property = undefined
			or Property = row.Property ) then
			refs.Add ( row.Ref );
		endif; 
	enddo; 
	Collections.Group ( refs );
	return refs;
	
EndFunction 

Function evalCondition ( UserData, Conditions, Index, Parent, Group )
	
	result = true;
	condition = PredefinedValue ( "Enum.ConditionTypes.Condition" );
	groupAnd = PredefinedValue ( "Enum.ConditionTypes.GroupAnd" );
	groupOr = PredefinedValue ( "Enum.ConditionTypes.GroupOr" );
	groupNot = PredefinedValue ( "Enum.ConditionTypes.GroupNot" );
	bound = Conditions.UBound ();
	while ( Index <= bound ) do
		row = Conditions [ Index ];
		if ( row.Parent <> Parent ) then
			return result;
		endif; 
		if ( row.Item = condition ) then
			result = checkValue ( UserData, row );
		else
			result = evalCondition ( UserData, Conditions, Index + 1, row.LineNumber, row.Item );
		endif; 
		if ( result ) then
			if ( Group = groupOr
				or Group = groupNot ) then
				break;
			endif;
		else
			if ( Group = groupAnd ) then
				break;
			endif;
		endif; 
		Index = Index + 1;
	enddo; 
	return result;
	
EndFunction 

Function checkValue ( Table, Item )
	
	leftValue = findByProperty ( Table, Item.Property ).Value;
	rightValue = Item.Value;
	operator = Item.Operator;
	if ( operator = PredefinedValue ( "Enum.Operators.Equal" ) ) then
		return leftValue = rightValue;
	else
		return leftValue <> rightValue;
	endif; 
	
EndFunction 

Function findByProperty ( Table, Property )
	
	return Table.FindRows ( new Structure ( "Property", Property ) ) [ 0 ];

EndFunction 

Procedure applyFormat ( Result, Form, Fields, Format, CleanInvisibility )
	
	for each field in Fields do
		property = field.Property;
		if ( CleanInvisibility ) then
			cleanValue ( Form, property, Format, Result );
		endif; 
		saveFormat ( Form, property, Format, Result );
		applyAppearance ( Form, property, Format, Result );
	enddo;

EndProcedure 

Procedure cleanValue ( Form, FieldProperty, Format, Result )

	if ( Format = PredefinedValue ( "Enum.Format.Visible" )
		or Format = PredefinedValue ( "Enum.Format.Invisible" ) ) then
	else
		return;
	endif; 
	property = findByProperty ( Form.PropertiesData.Properties, FieldProperty );
	willInvisible = ( not Result and ( Format = PredefinedValue ( "Enum.Format.Visible" ) ) )
	or ( Result and ( Format = PredefinedValue ( "Enum.Format.Invisible" ) ) );
	if ( willInvisible
		and propertyVisible ( property ) ) then
		row = findByProperty ( Form.Object.Properties, FieldProperty );
		row.Value = property.DefaultValue;
	endif;
	
EndProcedure 

Procedure saveFormat ( Form, FieldProperty, Format, Result )

	property = findByProperty ( Form.PropertiesData.Properties, FieldProperty );
	property.Format = format;
	property.FormatValue = Result;
	
EndProcedure 

Procedure applyAppearance ( Form, FieldProperty, Format, Result )
	
	property = findByProperty ( Form.PropertiesData.Properties, FieldProperty );
	id = itemName ( property );
	item = Form.Items [ id ];
	if ( format = PredefinedValue ( "Enum.Format.Visible" ) ) then
		item.Visible = result;
	elsif ( format = PredefinedValue ( "Enum.Format.Invisible" ) ) then
		item.Visible = not result;
	elsif ( format = PredefinedValue ( "Enum.Format.Enabled" ) ) then
		item.Enabled = result;
	elsif ( format = PredefinedValue ( "Enum.Format.Disabled" ) ) then
		item.Enabled = not result;
	endif; 
	
EndProcedure 

Procedure BuildDescription ( Form ) export
	
	object = Form.Object;
	properties = Form.PropertiesData;
	if ( properties.ChangeName ) then
		object.Description = getDescription ( Form, "InName", "LabelName" );
	endif; 
	if ( properties.ChangeDescription ) then
		object.FullDescription = getDescription ( Form, "InDescription", "LabelDescription" );
	endif; 
	
EndProcedure 

Function getDescription ( Form, Resource, Label )
	
	result = new Array ();
	properties = Form.PropertiesData.Properties;
	values = Form.Object.Properties;
	last = properties.Count () - 1;
	delimeters = getDelimeters ();
	delimeter = "";
	for i = 0 to last do
		row = properties [ i ];
		if ( not propertyVisible ( row )
			or not row [ Resource ] ) then
			continue;
		endif; 
		control = row.Control;
		if ( control = PredefinedValue ( "Enum.Controls.Label" )
			or control = PredefinedValue ( "Enum.Controls.Folder" ) ) then
			body = row.Name;
		else
			valueRows = Values.FindRows ( new Structure ( "Property", Row.Property ) );
			if ( valueRows.Count () = 0 ) then
				continue;
			endif;
			value = valueRows [ 0 ].Value;
			if ( not ValueIsFilled ( value ) ) then
				continue;
			endif; 
			body = ? ( Row [ Label ], Row.Name + ": ", "" ) + value;
		endif; 
		result.Add ( delimeter + body );
		delimeter = delimeters [ control ];
	enddo; 
	return StrConcat ( result );
	
EndFunction

Function getDelimeters ()
	
	map = new Map ();
	map [ PredefinedValue ( "Enum.Controls.Label" ) ] = " ";
	map [ PredefinedValue ( "Enum.Controls.Folder" ) ] = ": ";
	map [ PredefinedValue ( "Enum.Controls.Field" ) ] = ", ";
	return map;
	
EndFunction 

Function propertyVisible ( Row )
	
	format = Row.Format;
	value = Row.FormatValue;
	if ( value and ( format = PredefinedValue ( "Enum.Format.Invisible" ) )
		or ( not value and ( format = PredefinedValue ( "Enum.Format.Visible" ) ) ) ) then
		return false;
	else
		return true;
	endif; 
	
EndFunction 

&AtServer
Function Check ( Form ) export
	
	error = false;
	object = Form.Object;
	required = mandatoryFields ( Form );
	for each row in object.Properties do
		name = required [ row.property ];
		if ( name = undefined ) then
			continue;
		endif; 
		if ( ValueIsFilled ( row.Value ) ) then
			continue;
		endif; 
		error = true;
		Output.FieldIsEmpty ( new Structure ( "Field", name ) , , Object.Ref );
	enddo; 
	return not error;
	
EndFunction 

&AtServer
Function mandatoryFields ( Form )
	
	fields = new Map ();
	for each row in Form.PropertiesData.Properties do
		if ( row.Mandatory
			and propertyVisible ( row ) ) then
			fields [ row.Property ] = row.Name;
		endif; 
	enddo; 
	return fields;
	
EndFunction 

&AtServer
Procedure Access ( Form ) export
	
	roles = Metadata.Roles;
	setup = IsInRole ( roles.PropertiesSetup )
	or Logins.Admin ();
	if ( setup ) then
		return;
	endif; 
	items = Form.Items;
	items.ObjectUsage.Visible = false;
	items.OpenObjectUsage.Visible = false;
	if ( Form.Object.IsFolder ) then
		items.GroupsUsage.Visible = false;
		items.OpenGroupsUsage.Visible = false;
		items.ItemsUsage.Visible = false;
		items.OpenItemsUsage.Visible = false;
	endif; 
	
EndProcedure 

&AtClient
Procedure ChangeHost ( Form, Item ) export
	
	values = Form.Object.Properties;
	properties = Form.PropertiesData.Properties;
	host = itemProperty ( properties, Item );
	hostValue = findByProperty ( values, host ).Value;
	children = properties.FindRows ( new Structure ( "Host", host ) );
	items = Form.Items;
	empty = PredefinedValue ( "Catalog.PropertyValues.EmptyRef" );
	for each row in children do
		change = false;
		params = new Array ();
		field = items [ itemName ( row ) ];
		for each param in field.ChoiceParameters do
			name = param.Name;
			if ( name = "Filter.Filter"
				and param.Value <> hostValue ) then
				change = true;
				value = hostValue;
			else
				value = param.Value;
			endif; 
			params.Add ( new ChoiceParameter ( name, value ) );
		enddo; 
		if ( change ) then
			field.ChoiceParameters = new FixedArray ( params );
			valueRow = findByProperty ( values, row.Property );
			valueRow.Value = empty;
		endif; 
	enddo; 
	
EndProcedure 
