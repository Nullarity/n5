&AtServer
var Properties;
&AtServer
var CurrentIndex;
&AtClient
var TableRow;
&AtClient
var OldRow;
&AtClient
var DefaultValue;
&AtClient
var RootControl;
&AtClient
var FolderControl;
&AtClient
var FieldControl;
&AtClient
var LabelControl;
&AtClient
var PropertyValuesType;
&AtServer
var CommonFields;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setObjectClass ();
	restoreTree ();
	setPropertyTypes ();
	filterConditions ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Conditions enable not Dirty;
	|Save show Dirty;
	|TreeInDescription TreeInDescription1 TreeInDescription2 TreeLabelDescription show DescriptionExist;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	Object = Parameters.Object;
	DescriptionExist = Metafields.Exists ( Object.Ref, "FullDescription" );
	
EndProcedure 

&AtServer
Procedure setObjectClass ()
	
	ObjectClass = Enums.PropertiesClass [ Metadata.FindByType ( TypeOf ( Object ) ).Name ];
	
EndProcedure

&AtServer
Procedure restoreTree ()
	
	readProperties ();
	assignPictures ();
	table = FormAttributeToValue ( "Tree" );
	rows = table.Rows;
	rows.Clear ();
	root = rows.Add ();
	root.Control = Enums.Controls.Root;
	root.Name = Output.PropertiesRoot ();
	if ( Properties.Count () > 0 ) then
		folders = new Map ();
		folders [ ChartsOfCharacteristicTypes.Properties.EmptyRef () ] = root.Rows;
		for each row in Properties do
			rows = folders [ row.Folder ];
			newRow = rows.Add ();
			FillPropertyValues ( newRow, row );
			rowControl = row.Control;
			if ( rowControl = Enums.Controls.Folder ) then
				folders [ row.Property ] = newRow.Rows;
			endif; 
		enddo; 
	endif; 
	ValueToFormAttribute ( table, "Tree" );
	
EndProcedure 

&AtServer
Procedure readProperties ()
	
	s = "
	|select Properties.DefaultValue as DefaultValue, Properties.Folder as Folder, Properties.InDescription as InDescription,
	|	Properties.InName as InName, Properties.Mandatory as Mandatory, Properties.Position as Position,
	|	Properties.ToolTip as ToolTip, Properties.Ref as Property, Properties.Host as Host,
	|	Properties.Description as Name, Properties.Control as Control, Properties.Width as Width, Properties.Title as Title,
	|	Properties.ShowTitle as ShowTitle, Properties.HorizontalStretch as HorizontalStretch,
	|	Properties.GroupAppearance as GroupAppearance, Properties.GroupType as GroupType, Properties.ClearButton as ClearButton,
	|	Properties.ValueType as ValueType, Properties.LabelDescription as LabelDescription, Properties.LabelName as LabelName,
	|	Properties.Minimum as Minimum, Properties.Maximum as Maximum, false as Common
	|from ChartOfCharacteristicTypes.Properties as Properties
	|where Properties.Owner = &Object
	|and Properties.Scope = &Scope
	|and not Properties.DeletionMark
	|union all
	|select Properties.DefaultValue, Properties.Folder, Properties.Property.InDescription,
	|	Properties.Property.InName, Properties.Mandatory, Properties.Position,
	|	Properties.Property.ToolTip, Properties.Property, Properties.Host,
	|	Properties.Property.Description, Properties.Property.Control, Properties.Property.Width, Properties.Property.Title,
	|	Properties.Property.ShowTitle, Properties.Property.HorizontalStretch,
	|	Properties.Property.GroupAppearance, Properties.Property.GroupType, Properties.Property.ClearButton,
	|	Properties.Property.ValueType, Properties.Property.LabelDescription, Properties.Property.LabelName,
	|	Properties.Property.Minimum, Properties.Property.Maximum, true
	|from InformationRegister.CommonProperties as Properties
	|where Properties.Owner = &Object
	|and Properties.Scope = &Scope
	|order by Position
	|";
	q = new Query ( s );
	q.SetParameter ( "Object", Object );
	q.SetParameter ( "Scope", Parameters.Scope );
	Properties = q.Execute ().Unload ();
	
EndProcedure 

&AtServer
Procedure assignPictures ()
	
	Properties.Columns.Add ( "Picture", new TypeDescription ( "Number" ) );
	for each row in Properties do
		row.Picture = getPicture ( row.Control );
	enddo; 
	
EndProcedure 

&AtClientAtServerNoContext
Function getPicture ( Control )
	
	if ( Control = PredefinedValue ( "Enum.Controls.Root" ) ) then
		return 0;
	elsif ( Control = PredefinedValue ( "Enum.Controls.Folder" ) ) then
		return 1;
	elsif ( Control = PredefinedValue ( "Enum.Controls.Label" ) ) then
		return 2;
	else
		return 3;
	endif; 
	
EndFunction 

&AtServer
Procedure setPropertyTypes ()

	types = Metadata.ChartsOfCharacteristicTypes.Properties.Type.Types ();
	table = new ValueTable ();
	columns = table.Columns;
	columns.Add ( "Priority", new TypeDescription ( "Number" ) );
	columns.Add ( "Name", new TypeDescription ( "String" ) );
	columns.Add ( "Value" );
	columns.Add ( "Picture" );
	booleanType = Type ( "Boolean" );
	stringType = Type ( "String" );
	numberType = Type ( "Number" );
	dateType = Type ( "Date" );
	set = new Array ();
	for each type in types do
		row = table.Add ();
		set.Add ( type );
		type = new TypeDescription ( set );
		set.Clear ();
		row.Name = String ( type );
		row.Value = type;
		if ( type.ContainsType ( numberType ) ) then
			row.Priority = 0;
			row.Picture = PictureLib.NumberType;
		elsif ( type.ContainsType ( stringType ) ) then
			row.Priority = 1;
			row.Picture = PictureLib.StringType;
		elsif ( type.ContainsType ( dateType ) ) then
			row.Priority = 2;
			row.Picture = PictureLib.DateType;
		elsif ( type.ContainsType ( booleanType ) ) then
			row.Priority = 3;
			row.Picture = PictureLib.Boolean;
		else
			row.Priority = 4;
			row.Picture = PictureLib.Catalog;
		endif;
	enddo;
	table.Sort ( "Priority, Name" );
	list = Items.TreeType.ChoiceList;
	for each row in table do
		list.Add ( row.Value, row.Name, , row.Picture );
	enddo;

EndProcedure

&AtServer
Procedure filterConditions ()
	
	DC.ChangeFilter ( Conditions, "Owner", Parameters.Object, true );
	DC.ChangeFilter ( Conditions, "Scope", Parameters.Scope, true );
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( Exit ) then
		Cancel = true;
		return;
	endif; 
	if ( Modified ) then
		Cancel = true;
		Output.ConfirmExit ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Procedure ConfirmExit ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Cancel ) then
		return;
	elsif ( Answer = DialogReturnCode.No ) then
		Modified = false;
	else
		saveData ();
	endif; 
	Close ();
	
EndProcedure 

&AtServer
Procedure saveData ()
	
	prepareProperties ();
	table = FormAttributeToValue ( "Tree" );
	CurrentIndex = 0;
	BeginTransaction ();
	storeLevel ( table.Rows [ 0 ] );
	checkCommonFields ();
	cleanUnused ();
	ValueToFormAttribute ( table, "Tree" );
	CommitTransaction ();
	Modified = false;
	Dirty = false;
	Appearance.Apply ( ThisObject, "Dirty" );
	
EndProcedure 

&AtServer
Procedure prepareProperties ()
	
	CommonFields = new ValueTable ();
	CommonFields.Columns.Add ( "Property" );
	readProperties ();
	Properties.Columns.Add ( "Use", new TypeDescription ( "Boolean" ) );
	
EndProcedure 

&AtServer
Procedure storeLevel ( TreeRow )
	
	folder = ? ( TypeOf ( TreeRow ) = Type ( "ValueTree" ), undefined, TreeRow.Property );
	for each row in TreeRow.Rows do
		CurrentIndex = CurrentIndex + 1;
		setProperty ( row, folder );
		if ( row.Rows.Count () > 0 ) then
			storeLevel ( row );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure setProperty ( TableRow, Folder )
	
	commonField = TableRow.Common;
	rowProperty = TableRow.Property;
	if ( rowProperty.IsEmpty () ) then
		obj = ChartsOfCharacteristicTypes.Properties.CreateItem ();
	else
		setUse ( TableRow );
		if ( not commonField ) then
			enrollCommonField ( TableRow );
		endif;
		obj = rowProperty.GetObject ();
	endif;
	fixProperty ( obj, TableRow );
	FillPropertyValues ( obj, TableRow );
	obj.Description = TableRow.Name;
	obj.Class = ? ( TableRow.Control = Enums.Controls.Field, ObjectClass, undefined );
	if ( commonField ) then
		obj.Owner = undefined;
		obj.Scope = undefined;
		obj.Host = undefined;
		obj.DefaultValue = undefined;
		obj.Folder = undefined;
		obj.Position = 0;
		obj.Mandatory = false;
	else
		obj.Owner = Object;
		obj.Scope = Parameters.Scope;
		obj.DefaultValue = getDefaultValue ( TableRow );
		obj.Folder = Folder;
		obj.Position = CurrentIndex;
	endif;
	obj.Write ();
	ref = obj.Ref;
	TableRow.Property = ref;
	if ( commonField ) then
		writeCommonField ( TableRow, Folder );
	else
		rollbackCommonProperty ( ref );
	endif;
	
EndProcedure

&AtServer
Procedure enrollCommonField ( TableRow )
	
	row = CommonFields.Add ();
	row.Property = TableRow.Property;
	
EndProcedure

&AtServer
Function getDefaultValue ( TableRow )
	
	if ( TableRow.Control = Enums.Controls.Field ) then
		valueType = TableRow.ValueType;
		if ( valueType <> null ) then
			return valueType.AdjustValue ( TableRow.DefaultValue );
		endif; 
	endif; 
	return undefined;
	
EndFunction

&AtServer
Procedure writeCommonField ( TableRow, Folder )
	
	r = InformationRegisters.CommonProperties.CreateRecordManager ();
	r.Owner = Object;
	r.Property = TableRow.Property;
	r.Scope = Parameters.Scope;
	r.Position = CurrentIndex;
	r.Folder = Folder;
	r.Host = TableRow.Host;
	r.Mandatory = TableRow.Mandatory;
	r.DefaultValue = getDefaultValue ( TableRow );
	r.Write ();
	
EndProcedure

&AtServer
Procedure rollbackCommonProperty ( Property )
	
	r = InformationRegisters.CommonProperties.CreateRecordManager ();
	r.Owner = Object;
	r.Property = Property;
	r.Scope = Parameters.Scope;
	r.Delete ();
	
EndProcedure

&AtServer
Procedure checkCommonFields ()
	
	lockCommonFields ();
	list = getCommonFields ();
	for each row in list do
		raise Output.CommonFieldInUse ( new Structure ( "Property, Owner", row.Property, row.Owner ) );
	enddo;
	
EndProcedure

&AtServer
Procedure lockCommonFields ()
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.CommonProperties");
	item.Mode = DataLockMode.Exclusive;
	item.DataSource = CommonFields;
	item.UseFromDataSource ( "Property", "Property" );
	lock.Lock ();
	
EndProcedure

&AtServer
Function getCommonFields ()
	
	s = "
	|select presentation ( Properties.Property ) as Property, presentation ( max ( Properties.Owner ) ) as Owner
	|from InformationRegister.CommonProperties as Properties
	|where Properties.Property in ( &Properties )
	|and Properties.Owner <> &Object
	|group by Properties.Property
	|having count ( Properties.Owner ) > 0";
	q = new Query ( s );
	q.SetParameter ( "Object", Object );
	q.SetParameter ( "Properties", CommonFields.UnloadColumn ( "Property" ) );
	return q.Execute ().Unload ();
	
EndFunction

&AtServer
Procedure setUse ( TableRow )
	
	row = Properties.Find ( TableRow.Property, "Property" );
	if ( row <> undefined ) then
		row.Use = true;
	endif;

EndProcedure

&AtServer
Procedure fixProperty ( Item, TableRow )
	
	if ( TableRow.Name = "" ) then
		TableRow.Name = Output.PropertiesDefaultName () + Format ( CurrentIndex - 1, "NG=" );
	endif; 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	saveData ();
	Close ();
	
EndProcedure

&AtServer
Procedure cleanUnused ()
	
	for each row in Properties do
		if ( not row.Use ) then
			ref = row.Property;
			if ( row.Common  ) then
				rollbackCommonProperty ( ref );
			else
				ref.GetObject ().SetDeletionMark ( true );
			endif;
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure Save ( Command )
	
	writeData ();
	
EndProcedure

&AtClient
Procedure writeData ()
	
	position = savePosition ( TableRow );
	saveData ();
	expandTree ();
	restorePosition ( position );
	
EndProcedure 

&AtClient
Function savePosition ( CurrentRow, Path = undefined )
	
	if ( Path = undefined ) then
		root = true;
		Path = new Array ();
	else
		root = false;
	endif; 
	parent = CurrentRow.GetParent ();
	table = ? ( parent = undefined, Tree, parent );
	index = table.GetItems ().IndexOf ( CurrentRow );
	Path.Add ( index );
	if ( parent <> undefined ) then
		savePosition ( parent, Path );
	endif; 
	if ( root ) then
		return Path;
	endif; 
	
EndFunction 

&AtClient
Procedure expandTree ()
	
	Items.Tree.Expand ( Tree.GetItems () [ 0 ].GetID (), true );

EndProcedure 

&AtClient
Procedure restorePosition ( Position )
	
	i = Position.UBound ();
	currentRow = Tree;
	while ( i >= 0 ) do
		index = Position [ i ];
		currentRow = currentRow.GetItems ().Get ( index );
		i = i - 1;
	enddo; 
	TableRow = currentRow;
	Items.Tree.CurrentRow = currentRow.GetID ();
	
EndProcedure 

&AtClient
Procedure AddGroup ( Command )
	
	add ( FolderControl );
	
EndProcedure

&AtClient
Procedure add ( Control )
	
	row = newRow ( Control );
	table = Items.Tree;
	table.CurrentRow = row.GetID ();
	table.ChangeRow ();
	
EndProcedure 

&AtClient
Function newRow ( Control )
	
	currentControl = TableRow.Control;
	if ( currentControl = RootControl
		or currentControl = FolderControl ) then
		folder = TableRow;
	else
		folder = TableRow.GetParent ();
	endif;
	auto = PredefinedValue ( "Enum.YesNoAuto.Auto" );
	rows = folder.GetItems ();
	row = rows.Add ();
	row.Control = Control;
	row.Picture = getPicture ( Control );
	row.ValueType = new TypeDescription ( "String" );
	if ( Control = FolderControl ) then
		row.Mandatory = true;
		row.GroupType = PredefinedValue ( "Enum.Groups.Vertical" );
		row.GroupAppearance = PredefinedValue ( "Enum.GroupAppearance.None" );
		row.HorizontalStretch = auto;
	elsif ( Control = FieldControl ) then
		row.Mandatory = true;
		row.InName = true;
		row.InDescription = DescriptionExist;
		row.ClearButton = auto;
		row.HorizontalStretch = auto;
	elsif ( Control = LabelControl ) then
		row.InName = true;
		row.InDescription = DescriptionExist;
	endif; 
	return row;
	
EndFunction 

&AtClient
Procedure AddLabel ( Command )
	
	add ( LabelControl );
	
EndProcedure

&AtClient
Procedure AddCommon ( Command )

	openCommonFields ();

EndProcedure

&AtClient
Procedure openCommonFields ()
	
	filter = new Structure ( "Common, Control", true, FieldControl );
	OpenForm ( "ChartOfCharacteristicTypes.Properties.ChoiceForm",
		new Structure ( "Filter", filter ), , , , ,
		new NotifyDescription ( "CommonFieldSelected", ThisObject ) );
	
EndProcedure

&AtClient
Procedure CommonFieldSelected ( Value, Params ) export
	
	if ( Value = undefined ) then
		return;
	endif;
	addCommonField ( Value );
	
EndProcedure

&AtClient
Procedure addCommonField ( Value )
	
	row = newRow ( FieldControl );
	data = DF.Values ( Value,
	"Description,
	|ClearButton,
	|InDescription,
	|InName,
	|LabelDescription,
	|LabelName,
	|Maximum,
	|Minimum,
	|ShowTitle,
	|Title,
	|ToolTip,
	|Width,
	|ValueType" );
	FillPropertyValues ( row, data );
	row.Common = true;
	row.Property = Value;
	row.Name = data.Description;
	table = Items.Tree;
	table.CurrentRow = row.GetID ();
	table.ChangeRow ();
	
EndProcedure 

&AtClient
Procedure PagesOnCurrentPageChange ( Item, CurrentPage )
	
	if ( CurrentPage = Items.PageConditions ) then
		Dirty = Modified;
		Appearance.Apply ( ThisObject, "Dirty" );
	endif; 
	
EndProcedure

// *****************************************
// *********** Table Tree

&AtClient
Procedure TreeOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	if ( OldRow = TableRow ) then
		return;
	endif; 
	OldRow = TableRow;
	showOptions ();
	applyAppearance ();
	
EndProcedure

&AtClient
Procedure showOptions ()
	
	control = TableRow.Control;
	if ( control = FieldControl ) then
		page = Items.FieldOptions;
	elsif ( control = FolderControl ) then
		page = Items.FolderOptions;
	elsif ( control = LabelControl ) then
		page = Items.LabelOptions;
	else
		page = Items.RootOptions;
	endif; 
	Items.OptionsPanel.CurrentPage = page;
	
EndProcedure 

&AtClient
Procedure applyAppearance ( Name = undefined )
	
	if ( Name = "ValueType" or Name = undefined ) then
		if ( TableRow.Control = FieldControl ) then
			flag = hostSupported ();
			Items.TreeHost.Enabled = flag;
			Items.TreeDefaultValue.Enabled = not flag or TableRow.Host.IsEmpty ();
			flag = numericField ();
			Items.TreeMinimum.Enabled = flag;
			Items.TreeMaximum.Enabled = flag;
		endif; 
	endif; 
	if ( Name = "Host" or Name = undefined ) then
		if ( TableRow.Control = FieldControl ) then
			Items.TreeDefaultValue.Enabled = not hostSupported () or TableRow.Host.IsEmpty ();
		endif; 
	endif; 
	
EndProcedure

&AtClient
Function hostSupported ()
	
	return PropertyValuesType = TableRow.ValueType;
	
EndFunction 

&AtClient
Function numericField ()
	
	return TableRow.ValueType.ContainsType ( Type ( "Number" ) );
	
EndFunction 

&AtClient
Procedure TreeBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	if ( Clone ) then
		if ( isRoot () ) then
			Cancel = true;
		endif; 
	else
		Cancel = true;
		add ( FieldControl );
	endif; 
	
EndProcedure

&AtClient
Function isRoot ()
	
	return TableRow.Control = RootControl;
	
EndFunction 

&AtClient
Procedure TreeBeforeRowChange ( Item, Cancel )
	
	if ( isRoot () ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtClient
Procedure TreeBeforeDeleteRow ( Item, Cancel )
	
	if ( isRoot ()
		or hasConditions () ) then
		Cancel = true;
	else
		detachChildren ();
	endif; 
	
EndProcedure

&AtClient
Function hasConditions ()
	
	if ( conditionExists ( TableRow.Property, Object, Parameters.Scope ) ) then
		Output.PropertyDeletionError ();
		return true;
	endif; 
	return false;
	
EndFunction 

&AtServerNoContext
Function conditionExists ( val Property, val Owner, val Scope )
	
	s = "
	|select top 1 1
	|from Catalog.PropertyConditions.Conditions as Conditions
	|where not Conditions.Ref.DeletionMark
	|and Conditions.Property = &Property
	|and Conditions.Ref.Owner = &Owner
	|and Conditions.Ref.Scope = &Scope
	|union all
	|select top 1 1
	|from Catalog.PropertyConditions.Properties as Properties
	|where not Properties.Ref.DeletionMark
	|and Properties.Property = &Property
	|and Properties.Ref.Owner = &Owner
	|and Properties.Ref.Scope = &Scope
	|";
	q = new Query ( s );
	q.SetParameter ( "Property", Property );
	q.SetParameter ( "Owner", Owner );
	q.SetParameter ( "Scope", Scope );
	return not q.Execute ().IsEmpty ();

EndFunction 

&AtClient
Procedure detachChildren ( Rows = undefined )
	
	if ( Rows = undefined ) then
		Rows = Tree.GetItems ();
	endif; 
	property = TableRow.Property;
	for each row in Rows do
		if ( row.Host = property ) then
			row.Host = undefined;
		endif; 
		next = row.GetItems ();
		if ( next.Count () > 0 ) then
			detachChildren ( next );
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure TreeDragStart ( Item, DragParameters, Perform )
	
	if ( isRoot () ) then
		Perform = false;
	endif; 
	
EndProcedure

&AtClient
Procedure TreeDragCheck ( Item, DragParameters, StandardProcessing, Row, Field )
	
	data = Items.Tree.RowData ( Row );
	if ( data = undefined
		or not data.Control = FolderControl ) then
		StandardProcessing = false;
		DragParameters.Action = DragAction.Cancel;
	endif; 
	
EndProcedure

&AtClient
Procedure TreeDrag ( Item, DragParameters, StandardProcessing, Row, Field )
	
	StandardProcessing = false;
	Forms.Drag ( ThisObject, DragParameters.Value, Row, Items.Tree, Tree );
	
EndProcedure

&AtClient
Procedure TreeTypeClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure TreeTypeOnChange ( Item )
	
	resetMinMax ();
	resetHost ();
	if ( not appropriateHost ( TableRow ) ) then
		detachChildren ();
	endif; 
	applyAppearance ( "ValueType" );
	
EndProcedure

&AtClient
Procedure resetMinMax ()
	
	if ( not numericField () ) then
		TableRow.Minimum = undefined;
		TableRow.Maximum = undefined;
	endif; 
	
EndProcedure 

&AtClient
Procedure resetHost ()
	
	if ( not hostSupported () ) then
		TableRow.Host = undefined;
	endif; 
	
EndProcedure 

&AtClient
Function appropriateHost ( Row )
	
	simple = Row.ValueType.ContainsType ( Type ( "String" ) )
	or Row.ValueType.ContainsType ( Type ( "Number" ) )
	or Row.ValueType.ContainsType ( Type ( "Date" ) )
	or Row.ValueType.ContainsType ( Type ( "Boolean" ) );
	return not simple;
	
EndFunction 

&AtClient
Procedure TreeInNameOnChange ( Item )
	
	resetLabelName ();
	
EndProcedure

&AtClient
Procedure resetLabelName ()
	
	if ( not TableRow.InName ) then
		TableRow.LabelName = false;
	endif; 
	
EndProcedure 

&AtClient
Procedure TreeHostStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	saveNewProperty ();
	owners = getOwners ();
	if ( owners.FindByValue ( PredefinedValue ( "ChartOfCharacteristicTypes.Properties.EmptyRef" ) ) = undefined ) then
		ChoiceData = owners;
	else
		Output.SaveNewProperties ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Procedure saveNewProperty ()
	
	if ( TableRow.Property.IsEmpty () ) then
		writeData ();
	endif; 
	
EndProcedure

&AtClient
Function getOwners ( Rows = undefined, List = undefined )
	
	if ( Rows = undefined ) then
		Rows = Tree.GetItems ();
		root = true;
		List = new ValueList ();
	else
		root = false;
	endif; 
	child = TableRow.Property;
	for each row in Rows do
		property = row.Property;
		if ( row.Control = FieldControl
			and appropriateHost ( row )
			and property <> child ) then
			cossreference = ( row.Host = child );
			if ( cossreference ) then
				List.Add ( undefined, String ( property ) + " " + Output.HostAlreadyUsed () );
			else
				List.Add ( property );
			endif; 
		endif; 
		next = row.GetItems ();
		if ( next.Count () > 0 ) then
			getOwners ( next, List )
		endif; 
	enddo; 
	if ( root ) then
		return List;
	endif; 
	
EndFunction

&AtClient
Procedure TreeHostOnChange ( Item )

	applyHost ();
	applyAppearance ( "Host" );

EndProcedure

&AtClient
Procedure applyHost ()
	
	if ( not TableRow.Host.IsEmpty () ) then
		TableRow.DefaultValue = undefined;
	endif;	
	
EndProcedure

&AtClient
Procedure TreeDefaultValueCreating ( Item, StandardProcessing )
	
	saveNewProperty ();
	
EndProcedure

&AtClient
Procedure SaveNewProperties ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	writeData ();
	
EndProcedure 

&AtClient
Procedure TreeLabelNameOnChange ( Item )
	
	setInName ();
	
EndProcedure

&AtClient
Procedure setInName ()
	
	if ( TableRow.LabelName ) then
		TableRow.InName = true;
	endif; 
	
EndProcedure 

&AtClient
Procedure TreeInDescriptionOnChange ( Item )
	
	resetLabelDescription ();
	
EndProcedure

&AtClient
Procedure resetLabelDescription ()
	
	if ( not TableRow.InDescription ) then
		TableRow.LabelDescription = false;
	endif; 
	
EndProcedure 

&AtClient
Procedure TreeLabelDescriptionOnChange ( Item )
	
	setInDescription ();
	
EndProcedure

&AtClient
Procedure setInDescription ()
	
	if ( TableRow.LabelDescription ) then
		TableRow.InDescription = DescriptionExist;
	endif; 
	
EndProcedure 

&AtClient
Procedure TreeFieldClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

// *****************************************
// *********** Variables Initialization

#if ( Client ) then
	
RootControl = PredefinedValue ( "Enum.Controls.Root" );
FolderControl = PredefinedValue ( "Enum.Controls.Folder" );
FieldControl = PredefinedValue ( "Enum.Controls.Field" );
LabelControl = PredefinedValue ( "Enum.Controls.Label" );

PropertyValuesType = new TypeDescription ( "CatalogRef.PropertyValues" );
	
#endif
