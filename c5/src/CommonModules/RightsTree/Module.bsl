&AtServer
Function FillRights ( Form ) export
	
	env = GetEnv ( Form );
	PrepareRightsTable ( env );
	getSelectedRights ( env );
	relations = RightsTree.FillRightsTable ( env );
	RightsTree.SetCheckboxesForGroups ( env.RightsTable.Rows );
	Form.ValueToFormAttribute ( env.RightsTable, "Rights" );
	return relations;
	
EndFunction

&AtServer
Function GetEnv ( Form ) export
	
	env = new Structure ();
	env.Insert ( "Form", Form );
	env.Insert ( "Object", Form.Object );
	env.Insert ( "RightsTable", new ValueTree () );
	env.Insert ( "CurrentGroup" );
	return env;
	
EndFunction 

&AtServer
Procedure PrepareRightsTable ( Env ) export
	
	stringType = new TypeDescription ( "String" );
	numberType = new TypeDescription ( "Number" );
	Env.RightsTable.Columns.Add ( "Description", stringType );
	Env.RightsTable.Columns.Add ( "Explanation", stringType );
	Env.RightsTable.Columns.Add ( "RoleName", stringType );
	Env.RightsTable.Columns.Add ( "Use", numberType );
	Env.RightsTable.Columns.Add ( "Confirmed", numberType );
	
EndProcedure

&AtServer
Procedure getSelectedRights ( Env )
	
	Env.Insert ( "SelectedRights", getRoleNamesFromObject ( Env.Object ) );
	
EndProcedure 

&AtServer
Function getRoleNamesFromObject ( Object )
	
	return Object.Rights.Unload ().UnloadColumn ( "RoleName" );
	
EndFunction

&AtServer
Function FillRightsTable ( Env ) export
	
	table = rightsTable ();
	relations = new Array ();	
	for each node in table do
		addNodeToTable ( Env, node );
		addNodeToRelations ( node, relations );
	enddo;	
	return new FixedArray ( relations )
	
EndFunction

&AtServer
Function rightsTable ()
	
	template = GetCommonTemplate ( "Rights" );
	table = new ValueTable();
	root = Logins.Sysadmin ();
	unlimited = Enum.SuperRolesUnlimited ();
	sysadmin = Enum.SuperRolesSysadmin ();
	for i = 1 to template.TableWidth do		
		area = template.Area ( 1, i, 1, i );
		name = area.Parameter;
		typeName = area.DetailsParameter;
		if ( typeName = undefined ) then
			type = new TypeDescription ( "String" );		
		else
			type = new TypeDescription ( typeName );			
		endif;
		table.Columns.Add ( name, type );
		for j = 2 to template.TableHeight do
			area = template.Area ( j, i, j, i );
			value = ? ( area.Parameter = undefined, area.Text, area.Parameter );
			if ( root ) then
			else
				if ( value = unlimited
					or value = sysadmin ) then
					continue;
				endif;
			endif;
			value = ? ( typeName = "Array", Conversion.StringToArray ( value ), value);
			value = ? ( typeName = "Structure", Conversion.StringToStructure ( value ), value);
			row = ? ( i = 1, table.Add (), table.Get ( j - 2 ) );			
			row [ name ] = value;
		enddo;
	enddo; 	
	return table;
	
EndFunction

&AtServer
Procedure addNodeToTable ( Env, Node )
	
	if ( Node.Group <> "" ) then
		Env.CurrentGroup = Env.RightsTable.Rows.Add ();		
		Env.CurrentGroup.Description = Node.Group;
		Env.CurrentGroup.Explanation = Node.Explanation;		
	elsif ( Node.Name <> undefined ) then
		roleName = getRoleName ( Node.Name );
		role = Metadata.Roles.Find ( roleName );
		if ( role = undefined ) then
			Message ( "The role """ + roleName + """ is not found in metadata configuration" );
			return;
		endif; 
		row = Env.CurrentGroup.Rows.Add ();
		row.RoleName = roleName;
		row.Description = role.Presentation ();
		row.Explanation = Node.Explanation;
		row.Use = InRole ( Env, row.RoleName );
	endif; 
	
EndProcedure 

&AtServer
Function getRoleName ( Name )
	
	if ( Name = "UseAnalysisOfWorkingTime" ) then
		return "WorkingTimeAnalysis";
	elsif ( Name = "UseCalendar" ) then
		return "Calendar";
	elsif ( Name = "UseDocuments" ) then
		return "Documents";
	elsif ( Name = "UseExternalObjects" ) then
		return "ExternalObjects";
	elsif ( Name = "UseReportPayments" ) then
		return "PaymentsReport";
	elsif ( Name = "UseReportProjectAnalysis" ) then
		return "ProjectAnalysisReport";
	elsif ( Name = "UseReportSales" ) then
		return "SalesReports";
	elsif ( Name = "UseReportWorkLog" ) then
		return "WorkLogReport";
	else
		return Name;
	endif; 
	
EndFunction 

&AtServer
Procedure addNodeToRelations ( Node, Relations )
	
	if ( Node.Roles.Count () = 0 ) then
		return;
	endif; 
	Relations.Add ( new Structure ( "RoleName, Roles", Node.Name, Node.Roles ) );
	
EndProcedure 

&AtServer
Function GetRelations () export
	
	table = rightsTable ();
	relations = new Array ();	
	for each node in table do
		addNodeToRelations ( node, relations );
	enddo;	
	return new FixedArray ( relations );
	
EndFunction

&AtServer
Function InRole ( Env, RoleName ) export
	
	return Env.SelectedRights.Find ( RoleName ) <> undefined;
	
EndFunction 

Procedure SetCheckboxesForGroups ( Groups ) export
	
	for each row in Groups do
		#if ( Server ) then
			row.Use = GetGroupCheckboxState ( row.Rows );
		#else
			row.Use = GetGroupCheckboxState ( row.GetItems () );
		#endif
	enddo; 
	
EndProcedure 

Function GetGroupCheckboxState ( Rows ) export
	
	currentState = undefined;
	for each row in Rows do
		if ( currentState = undefined ) then
			currentState = row.Use;
		elsif ( currentState <> row.Use ) then
			return 2;
		endif; 
	enddo; 
	return currentState;
	
EndFunction 

&AtServer
Function FillCheck ( Form ) export
	
	tree = Form.FormAttributeToValue ( "Rights" );
	return tree.Rows.Find ( 1, "Use", true ) <> undefined;
	
EndFunction

&AtServer
Procedure SaveSeletedRights ( Form, CurrentObject ) export
	
	tree = Form.FormAttributeToValue ( "Rights" );
	for each groupRow in tree.Rows do
		for each rightRow in groupRow.Rows do
			roleName = rightRow.RoleName;
			currentRightRow = CurrentObject.Rights.Find ( roleName, "RoleName" );
			if ( rightRow.Use > 0 and currentRightRow = undefined ) then
				currentRightRow = CurrentObject.Rights.Add ();
				currentRightRow.RoleName = roleName;
			elsif ( rightRow.Use = 0 and currentRightRow <> undefined ) then
				CurrentObject.Rights.Delete ( currentRightRow );
			endif; 
		enddo; 
	enddo; 
	
EndProcedure 

&AtClient
Function UseChanged ( Form ) export
	
	tree = Form.Rights;
	roles = tree.GetItems ();
	relations = Form.RightsRelations;	
	row = Form.Items.Rights.CurrentData;	
	map = getRolesMap ( tree );
	
	captureCurrentRoles ( roles );
	if ( row.Use = 2 ) then
		row.Use = 0;		
	endif; 
	row.Confirmed = 1 - row.Use;
	if ( isGroup ( row ) ) then
		setCheckboxesByGroup ( row, tree, map, relations );
	else
		setCheckboxes ( row, tree, map, relations );
	endif; 	
	SetCheckboxesForGroups ( roles );	
	return mustConfirmChanges ( roles );	
	
EndFunction 

&AtClient
Function getRolesMap ( RolesTree )
	
	roles = new Map ();
	groups = RolesTree.GetItems ();
	for each group in groups do
		rows = group.GetItems ();
		for each row in rows do
			roles [ row.RoleName ] = row;
		enddo;
	enddo;
	return roles;
	
EndFunction 

&AtClient
Procedure RevertRights ( Form ) export
	
	revertChanges ( Form.Rights.GetItems () );
	Form.RightsChanges.GetItems ().Clear ();
	Form.Items.RightsPages.CurrentPage = Form.Items.RightsPage;	
	Form.Items.ConfirmPage.Enabled = false;
	Form.Items.RightsPage.Enabled = true;
	
EndProcedure

&AtServer
Procedure ShowConfirmation ( Form ) export
	
	Form.Items.RightsPages.CurrentPage = Form.Items.ConfirmPage;
	Form.Items.ConfirmPage.Enabled = true;
	Form.Items.RightsPage.Enabled = false;
	
EndProcedure

&AtClient
Procedure Expand ( Form, Control = "RightsChanges" ) export
	
	tree = Form.Items [ Control ];
	table = Form [ Control ];
	for each row in  table.GetItems () do
		tree.Expand ( row.GetID (), true );
	enddo;	
	
EndProcedure

&AtClient
Procedure HideConfirmation ( Form ) export
	
	Form.Items.RightsPages.CurrentPage = Form.Items.RightsPage;
	Form.Items.ConfirmPage.Enabled = false; // Bug workaround: in some cases "CurrentPage" does not work
	Form.Items.RightsPage.Enabled = true;
	
EndProcedure

&AtClient
Procedure captureCurrentRoles ( Rows )
	
	for each row in Rows do
		row.Confirmed = row.Use;
		captureCurrentRoles ( row.GetItems () );
	enddo;
	
EndProcedure

&AtClient
Function mustConfirmChanges ( Groups )	
	
	groupCount = 0;
	for each group in Groups do
		if ( group.Use <> group.Confirmed ) then
			groupCount = groupCount + 1;
		endif;
		
		itemCount = group.GetItems ().Count();
		changedCount = 0;
		for each row in group.GetItems () do
			if ( row.Use <> row.Confirmed ) then
				changedCount = changedCount + 1;
			endif;
		enddo; 
	enddo;	
	if ( groupCount > 1 ) then
		return true;
	elsif ( changedCount > 1 and changedCount < itemCount ) then
		return true;
	else
		return false;
	endif;
	
EndFunction

&AtServer
Procedure FillChanges ( Form ) export
	
	tree = Form.FormAttributeToValue ( "Rights" );	
	removeConfirmedRows ( tree );	
	Form.ValueToFormAttribute ( tree, "RightsChanges" );
	
EndProcedure 

&AtServer
Procedure removeConfirmedRows ( Tree )
	
	i = 0;
	while ( i < Tree.Rows.Count () ) do
		parent = Tree.Rows [ i ];
		display = false;		
		j = 0;
		while ( j < parent.Rows.Count () ) do
			role = parent.Rows [ j ];
			if ( role.Use = role.Confirmed ) then
				parent.Rows.Delete ( j );
			else				
				j = j + 1;
				display = true;
			endif;
		enddo;		
		if ( not display ) then
			Tree.Rows.Delete ( parent );
		else			
			i = i + 1;
		endif;
	enddo; 
	
EndProcedure 

&AtClient
Procedure RoleChangesRejected ( Answer, Params ) export
	
	if ( Answer <> DialogReturnCode.Yes ) then		
		revertChanges ( Params.Roles );
	endif;		
	
EndProcedure

&AtClient
Procedure revertChanges ( Rows )
	
	for each row in Rows do		
		row.Use = row.Confirmed;		
		revertChanges ( row.GetItems () );
	enddo;
	
EndProcedure

&AtClient
Procedure getRoleUseChanges ( Rows, Changed )
	for each row in Rows do
		if ( isGroup ( row ) ) then
			getRoleUseChanges ( row.GetItems(), Changed );
		elsif ( row.Confirmed <> row.Use ) then
			Changed.Add ( row.RoleName );
		endif;
	enddo;
EndProcedure

&AtClient
Function isGroup ( Row )
	
	return Row.RoleName = "";
	
EndFunction 

&AtClient
Procedure setCheckboxesByGroup ( Group, RolesTree, RolesMap, RightsRelations )
	
	rows = Group.GetItems ();
	for each row in rows do
		row.Use = Group.Use;
		setCheckboxes ( row, RolesTree, RolesMap, RightsRelations );
	enddo; 
	
EndProcedure 

&AtClient
Procedure setCheckboxes ( Row, RolesTree, RolesMap, RightsRelations )
	
	if ( Row.Use = 1 ) then
		enableBasedRoles ( Row.RoleName, RolesMap, RightsRelations );
	else
		resetSubordinatedRoles ( Row.RoleName, rolesMap, RightsRelations );
	endif; 
	
EndProcedure 

&AtClient
Procedure enableBasedRoles ( RoleName, RolesMap, RightsRelations )
	
	basedRoles = findBasedRoles ( RoleName, RightsRelations );
	if ( basedRoles = undefined ) then
		return;
	endif; 
	if ( basedRolesChecked ( RolesMap, basedRoles ) ) then
		return;
	endif;
	for each role in basedRoles.Roles do
		RolesMap [ role ].Use = 1;
		nextRoles = findBasedRoles ( role, RightsRelations );
		if ( nextRoles <> undefined ) then
			enableBasedRoles ( role, RolesMap, RightsRelations );
		endif; 
	enddo;
	
EndProcedure

&AtClient
Function findBasedRoles ( RoleName, RightsRelations )
	
	for each item in RightsRelations do
		if ( item.RoleName = RoleName ) then
			return item;
		endif; 
	enddo; 
	return undefined;
	
EndFunction 

&AtClient
Function basedRolesChecked ( RolesMap, BasedRoles )
	
	for each role in BasedRoles.Roles do
		if ( not RolesMap [ role ].Use = 1 ) then
			return false;
		endif; 
	enddo; 
	return true;
	
EndFunction 

&AtClient
Procedure resetSubordinatedRoles ( RoleName, RolesMap, RightsRelations )
	
	for each subordinatedRole in RightsRelations do
		subordinatedRoleName = subordinatedRole.RoleName;
		if ( subordinatedRoleName = RoleName ) then
			continue;
		endif;
		if ( subordinatedRole.Roles.Find ( RoleName ) = undefined ) then
			continue;
		endif; 
		if ( basedRolesChecked ( RolesMap, subordinatedRole ) ) then
			continue;
		endif;
		RolesMap [ subordinatedRoleName ].Use = 0;
		basedRoles = findBasedRoles ( subordinatedRoleName, RightsRelations );
		if ( basedRoles <> undefined ) then
			resetSubordinatedRoles ( subordinatedRoleName, RolesMap, RightsRelations );
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure MarkAll ( RightsTable ) export
	
	markRows ( RightsTable, 1 );
	
EndProcedure 

&AtClient
Procedure UnmarkAll ( RightsTable ) export
	
	markRows ( RightsTable, 0 );
	
EndProcedure 

&AtClient
Procedure markRows ( RightsTable, Marker )
	
	groups = RightsTable.GetItems ();
	for each group in groups do
		group.Use = Marker;
		items = group.GetItems ();
		for each item in items do
			item.Use = Marker;
		enddo; 
	enddo; 
	
EndProcedure 
