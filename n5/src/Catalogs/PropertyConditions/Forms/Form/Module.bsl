&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	restoreConditions ( Object );
	
EndProcedure

&AtServer
Procedure restoreConditions ( Source )
	
	table = FormAttributeToValue ( "Conditions" );
	table.Rows.Clear ();
	rows = new Map ();
	rows [ 0 ] = table;
	for each row in Source.Conditions do
		parent = row.Parent;
		node = rows [ parent ];
		newRow = ? ( node = undefined, rows [ parent ].Rows.Add (), node.Rows.Add () );
		FillPropertyValues ( newRow, row );
		rows [ row.LineNumber ] = newRow;
	enddo; 
	ValueToFormAttribute ( table, "Conditions" );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		copy = Parameters.CopyingValue;
		if ( not copy.IsEmpty () ) then
			restoreConditions ( copy );
		endif; 
	endif; 
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	saveConditions ( CurrentObject );
	setDescription ( CurrentObject );
	
EndProcedure

&AtServer
Procedure saveConditions ( CurrentObject )
	
	table = CurrentObject.Conditions;
	table.Clear ();
	tree = FormAttributeToValue ( "Conditions" );
	storeLevel ( table, tree );
	
EndProcedure 

&AtServer
Procedure storeLevel ( Table, TreeRow, Parent = 0 )
	
	for each row in TreeRow.Rows do
		newRow = Table.Add ();
		FillPropertyValues ( newRow, row );
		newRow.Parent = Parent;
		if ( row.Rows.Count () > 0 ) then
			storeLevel ( Table, row, newRow.LineNumber );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure setDescription ( CurrentObject )
	
	parts = new Array ();
	parts.Add ( StrConcat ( Object.Properties.Unload ().UnloadColumn ( "Property" ), ", " ) + ": " );
	parts.Add ( Object.Format );
	parts.Add ( Output.IfClause () );
	parent = 0;
	table = CurrentObject.Conditions;
	for each row in table do
		while ( parent > row.Parent ) do
			parts.Add ( ")" );
			parent = table [ parent - 1 ].Parent;
		enddo; 
		parent = row.Parent;
		parts.Add ( getConjuction ( table, row ) );
		if ( row.Item = Enums.ConditionTypes.Condition ) then
			parts.Add ( "" + row.Property + " " + row.Operator + " " + row.Value );
		endif; 
	enddo; 
	while ( parent > 0 ) do
		parts.Add ( ")" );
		parent = table [ parent - 1 ].Parent;
	enddo; 
	CurrentObject.Description = StrConcat ( parts, " " );
	
EndProcedure 

&AtServer
Function getConjuction ( Table, Row )
	
	line = Row.LineNumber;
	if ( line = 1 ) then
		return "";
	else
		parent = Row.Parent;
		if ( parent = 0 ) then
			clause = Output.AndClause ();
		else
			parentRow = Table [ parent - 1 ];
			if ( parentRow.LineNumber = ( line - 1 ) ) then
				clause = "(";
			else
				condition = parentRow.Item;
				if ( condition = Enums.ConditionTypes.GroupAnd ) then
					clause = Output.AndClause ();
				elsif ( condition = Enums.ConditionTypes.GroupOr ) then
					clause = Output.OrClause ();
				else
					clause = Output.NotClause ();
				endif; 
			endif; 
		endif; 
		return clause;
	endif; 
	
EndFunction 

// *****************************************
// *********** Table Conditions

&AtClient
Procedure GroupAnd ( Command )
	
	addGroup ( PredefinedValue ( "Enum.ConditionTypes.GroupAnd" ) );
	
EndProcedure

&AtClient
Procedure addGroup ( Type )
	
	if ( TableRow <> undefined ) then
		parent = TableRow.GetParent ();
	endif; 
	if ( parent = undefined ) then
		parent = Conditions;
	endif; 
	TableRow = parent.GetItems ().Add ();
	TableRow.Item = Type;
	Items.Conditions.CurrentRow = TableRow.GetID ();
	
EndProcedure 

&AtClient
Procedure GroupOr ( Command )
	
	addGroup ( PredefinedValue ( "Enum.ConditionTypes.GroupOr" ) );
	
EndProcedure

&AtClient
Procedure GroupNot ( Command )
	
	addGroup ( PredefinedValue ( "Enum.ConditionTypes.GroupNot" ) );
	
EndProcedure

&AtClient
Procedure ConditionsDragCheck ( Item, DragParameters, StandardProcessing, Row, Field )
	
	data = Items.Conditions.RowData ( Row );
	if ( data <> undefined
		and data.Item = PredefinedValue ( "Enum.ConditionTypes.Condition" ) ) then
		StandardProcessing = false;
		DragParameters.Action = DragAction.Cancel;
	endif; 
	
EndProcedure

&AtClient
Procedure ConditionsDrag ( Item, DragParameters, StandardProcessing, Row, Field )
	
	StandardProcessing = false;
	Forms.Drag ( ThisObject, DragParameters.Value, Row, Items.Conditions, Conditions );
	
EndProcedure

&AtClient
Procedure ConditionsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	if ( Clone ) then
		return;
	endif; 
	Cancel = true;
	newRow ();
	
EndProcedure

&AtClient
Procedure newRow ()
	
	TableRow = createRow ();
	TableRow.Item = PredefinedValue ( "Enum.ConditionTypes.Condition" );
	TableRow.Operator = PredefinedValue ( "Enum.Operators.Equal" );
	Items.Conditions.CurrentItem = Items.ConditionsProperty;
	Items.Conditions.CurrentRow = TableRow.GetID ();
	Items.Conditions.ChangeRow ();
	
EndProcedure 

&AtClient
Function createRow ()
	
	if ( TableRow <> undefined ) then
		if ( TableRow.Item = PredefinedValue ( "Enum.ConditionTypes.Condition" ) ) then
			parent = TableRow.GetParent ();
		else
			parent = TableRow;
		endif;
	endif; 
	if ( parent = undefined ) then
		parent = Conditions;
	endif;
	return parent.GetItems ().Add ();
	
EndFunction 

&AtClient
Procedure ConditionsOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure
