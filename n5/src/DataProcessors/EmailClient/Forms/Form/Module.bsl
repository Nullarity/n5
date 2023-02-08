&AtServer
var MailboxesSelection;
&AtServer
var Totals;
&AtClient
var CurrentEmail;
&AtClient
var CurrentOutgoingEmail;
&AtClient
var FirstWindow;
&AtClient
var IncomingDragStarted;
&AtClient
var OutgoingDragStarted;
&AtClient
var SearchItem;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	restoreSettings ();
	init ();
	loadLabels ();
	initIncoming ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	if ( Environment.MobileClient ()
		and not HideTree) then
		hideLabels ();
	endif;

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Labels show not HideTree;
	|HideTree HideTree1 HideTree2 HideTree3 press not HideTree;
	|IncomingPagePreview OutgoingPagePreview show Preview;
	|IncomingPage OutgoingPage show not Preview;
	|Filters Filters1 Filters2 Filters3 show QuickFilter;
	|GroupSearch GroupSearch1 GroupSearch2 GroupSearch3 show not QuickFilter;
	|LabelsShowHiddenLabels press ShowHiddenLabels
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure restoreSettings ()
	
	value = CommonSettingsStorage.Load ( Enum.SettingsEmailsPreview () );
	if ( value = undefined ) then
		Preview = true;
	else
		Preview = value;
	endif; 
	value = CommonSettingsStorage.Load ( Enum.SettingsHideTree () );
	if ( value = undefined ) then
		HideTree = false;
	else
		HideTree = value;
	endif; 
	
EndProcedure 

&AtServer
Procedure init ()
	
	MailService = Cloud.MailService ();
	initFixedSettings ();
	initUserSettings ();
	
EndProcedure 

&AtServer
Procedure initFixedSettings ()
	
	DC.SetParameter ( Incoming, "User", SessionParameters.User );
	DC.SetParameter ( Incoming, "Reply", Enum.MailCommandsReply () );
	DC.SetParameter ( Incoming, "Forward", Enum.MailCommandsForward () );
	DC.SetParameter ( Incoming, "Out", Output.OutClause () + " " );
	DC.SetParameter ( Outgoing, "Reply", Enum.MailCommandsReply () );
	DC.SetParameter ( Outgoing, "Forward", Enum.MailCommandsForward () );
	DC.SetParameter ( Outgoing, "To", Output.ToClause () + " " );

EndProcedure 

&AtServer
Procedure initUserSettings ()
	
	DC.SetParameter ( Incoming.SettingsComposer, "DeletionMark", false );
	DC.SetParameter ( Incoming.SettingsComposer, "IncomingType", Type ( "DocumentRef.IncomingEmail" ) );
	FilterIsChanged = false;
	SearchStarted = false;	
	
EndProcedure 

&AtServer
Procedure loadLabels ()
	
	table = initLabels ();
	fillLabels ( table );
	if ( not syncLabels ( Labels.GetItems (), table.Rows ) ) then
		ValueToFormAttribute ( table, "Labels" );
	endif;
	setUnread ();
	
EndProcedure 

&AtServer
Function initLabels ()
	
	table = new ValueTree ();
	table.Columns.Add ( "Description", new TypeDescription ( "String" ) );
	table.Columns.Add ( "Picture", new TypeDescription ( "Number" ) );
	table.Columns.Add ( "Count", new TypeDescription ( "Number" ) );
	table.Columns.Add ( "Label", new TypeDescription ( "CatalogRef.MailLabels" ) );
	table.Columns.Add ( "Mailbox", new TypeDescription ( "CatalogRef.MailBoxes" ) );
	table.Columns.Add ( "RowType", new TypeDescription ( "Number" ) );
	return table;
	
EndFunction 

&AtServer
Procedure fillLabels ( Table )
	
	getMailData ();
	while ( MailboxesSelection.Next () ) do
		row = Table.Rows.Add ();
		FillPropertyValues ( row, mailboxesSelection );
		row.Description = mailboxesSelection.MailboxDescription;
		row.RowType = Enum.MailboxLabelsBox ();
		row.Picture = Enum.MailboxPicturesBox ();
		row.Count = getMailsCount ();
		attachLabels ( mailboxesSelection, row.Rows );
	enddo; 
	
EndProcedure 

&AtServer
Procedure getMailData ()
	
	s = "
	|select NewMail.IncomingEmail as Email, Labels.Label as Label, Labels.Label.LabelType as LabelType
	|into LabeledMail
	|from InformationRegister.NewMail as NewMail
	|	//
	|	// Emails
	|	//
	|	join Document.IncomingEmail as Documents
	|	on Documents.Ref = NewMail.IncomingEmail
	|	//
	|	// Labels
	|	//
	|	join Catalog.MailKeys.Labels as Labels
	|	on Labels.Ref = Documents.Key
	|	and not Labels.Ref.DeletionMark
	|where NewMail.User = &User
	|index by Label, Email
	|;
	|select LabeledMail.Label as Label, LabeledMail.Email as Email
	|into NewMail
	|from LabeledMail as LabeledMail
	|union
	|select SystemLabels.Ref, NewMail.IncomingEmail
	|from Catalog.MailLabels as SystemLabels
	|	//
	|	// UnlabeledMail
	|	//
	|	join InformationRegister.NewMail as NewMail
	|	on NewMail.User = &User
	|	and NewMail.IncomingEmail.Mailbox = SystemLabels.Owner
	|	and ( NewMail.IncomingEmail not in ( select Email from LabeledMail where LabelType <> value ( Enum.LabelTypes.IMAP ) ) )
	|where SystemLabels.System
	|and SystemLabels.LabelType = value ( Enum.LabelTypes.Incoming )
	|and SystemLabels.User = &User
	|index by Label, Email
	|;
	|// Totals by Mailboxes
	|select NewMail.IncomingEmail.Mailbox as Mailbox, count ( NewMail.IncomingEmail ) as Count
	|from InformationRegister.NewMail as NewMail
	|where NewMail.User = &User
	|group by NewMail.IncomingEmail.Mailbox
	|;
	|// Labels tree
	|select Labels.Owner as Mailbox, Labels.Owner.Description as MailboxDescription, Labels.Ref as Label, Labels.System as System,
	|	Labels.Description as Description, Labels.LabelType as LabelType, NewMail.Email as Count
	|from Catalog.MailLabels as Labels
	|	//
	|	// NewMail
	|	//
	|	left join NewMail as NewMail
	|	on NewMail.Label = Labels.Ref
	|where not Labels.DeletionMark
	|and Labels.User = &User";
	if ( not ShowHiddenLabels ) then
		s = s + "
		|and not Labels.Hide";
	endif; 
	s = s + "
	|order by Labels.Owner.Code,
	|	case when Labels.LabelType = value ( Enum.LabelTypes.Incoming ) then 0
	|		when Labels.LabelType = value ( Enum.LabelTypes.IMAP ) then 1
	|		when Labels.LabelType = value ( Enum.LabelTypes.Outgoing ) then 2
	|		else 3 end,
	|	Labels.System desc,
	|	case when Labels.LabelType = value ( Enum.LabelTypes.IMAP ) then Labels.SortOrder else Labels.Code end
	|totals count ( NewMail.Email )
	|by Mailbox, Label hierarchy
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	data = q.ExecuteBatch ();
	Totals = data [ 2 ].Unload ();
	MailboxesSelection = data [ 3 ].Select ( QueryResultIteration.ByGroups, "Mailbox" );
	
EndProcedure

&AtServer
Function getMailsCount ()
	
	row = Totals.Find ( MailboxesSelection.Mailbox, "Mailbox" );
	return ? ( row = undefined, 0, row.Count );
	
EndFunction

&AtServer
Procedure attachLabels ( Selection, Rows )
	
	labelsSelection = Selection.Select ( QueryResultIteration.ByGroupsWithHierarchy, "Label" );
	while ( labelsSelection.Next () ) do
		if ( Rows.Parent.Label = labelsSelection.Label ) then
			Rows.Parent.Count = labelsSelection.Count;
			continue;
		endif; 
		row = Rows.Add ();
		FillPropertyValues ( row, labelsSelection );
		setRowType ( row, labelsSelection );
		row.Picture = getPictureByRowType ( row.RowType );
		attachLabels ( labelsSelection, row.Rows );
	enddo; 
	if ( Rows.Count () > 0 ) then
		Rows.Parent.Picture = getPictureByRowType ( Rows.Parent.RowType, true );
	endif; 
	
EndProcedure 

&AtServer
Function getPictureByRowType ( RowType, HasChildren = false )
	
	if ( RowType = Enum.MailboxLabelsIncoming () ) then
		return Enum.MailboxPicturesIncomingFolder ();
	elsif ( RowType = Enum.MailboxLabelsIncomingLabel () ) then
		return ? ( HasChildren, Enum.MailboxPicturesIncomingFolder (), Enum.MailboxPicturesIncomingLabel () );
	elsif ( RowType = Enum.MailboxLabelsIncomingIMAPLabel () ) then
		return Enum.MailboxPicturesLabelIMAP ();
	elsif ( RowType = Enum.MailboxLabelsOutgoing () ) then
		return Enum.MailboxPicturesOutboxFolder ();
	elsif ( RowType = Enum.MailboxLabelsOutgoingLabel () ) then
		return ? ( HasChildren, Enum.MailboxPicturesOutboxFolder (), Enum.MailboxPicturesOutboxLabel () );
	elsif ( RowType = Enum.MailboxLabelsTrash () ) then
		return Enum.MailboxPicturesTrash ();
	endif; 
	
EndFunction 

&AtServer
Procedure setRowType ( Row, Selection )
	
	if ( Selection.LabelType = Enums.LabelTypes.Incoming ) then
		Row.RowType = ? ( Selection.System, Enum.MailboxLabelsIncoming (), Enum.MailboxLabelsIncomingLabel () );
	elsif ( Selection.LabelType = Enums.LabelTypes.IMAP ) then
		Row.RowType = Enum.MailboxLabelsIncomingIMAPLabel ();
	elsif ( Selection.LabelType = Enums.LabelTypes.Outgoing ) then
		Row.RowType = ? ( Selection.System, Enum.MailboxLabelsOutgoing (), Enum.MailboxLabelsOutgoingLabel () );
	else
		Row.RowType = Enum.MailboxLabelsTrash ();
	endif;
	
EndProcedure 

&AtServer
Function syncLabels ( Rows1, Rows2 )
	
	j = Rows2.Count ();
	if ( Rows1.Count () <> j ) then
		return false;
	endif; 
	for i = 0 to j - 1 do
		row1 = Rows1 [ i ];
		row2 = Rows2 [ i ];
		syncRow ( row1, row2 );
		FillPropertyValues ( row1, row2 );
		nextRows1 = row1.GetItems ();
		nextRows2 = row2.Rows;
		if ( not syncLabels ( nextRows1, nextRows2 ) ) then
			return false;
		endif; 
	enddo; 
	return true;
	
EndFunction

&AtServer
Procedure syncRow ( Row1, Row2 )
	
	if ( Row1.Description <> Row2.Description ) then
		Row1.Description = Row2.Description;
	endif; 
	if ( Row1.Count <> Row2.Count ) then
		Row1.Count = Row2.Count;
	endif; 
	if ( Row1.Label <> Row2.Label ) then
		Row1.Label = Row2.Label;
	endif; 
	if ( Row1.Mailbox <> Row2.Mailbox ) then
		Row1.Mailbox = Row2.Mailbox;
	endif; 
	if ( Row1.RowType <> Row2.RowType ) then
		Row1.RowType = Row2.RowType;
	endif; 
	if ( Row1.Picture <> Row2.Picture ) then
		Row1.Picture = Row2.Picture;
	endif; 
	
EndProcedure 

&AtServer
Procedure initIncoming ()
	
	rows = Labels.GetItems ();
	if ( rows.Count () = 0 ) then
		return;
	endif; 
	row = rows [ 0 ];
	OldLabel = row.Mailbox;
	setListByLabel ( row.Mailbox, row.RowType );
	Items.Pages.CurrentPage = incomingPage ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Function incomingPage ( Form )
	
	items = Form.Items;
	if ( Form.Preview ) then
		return items.IncomingPagePreview;
	else
		return items.IncomingPage;
	endif; 
	
EndFunction 

&AtServer
Procedure setListByLabel ( val Mailbox, val RowType )
	
	DC.ChangeFilter ( Incoming, "Mailbox", Mailbox, true );
	DC.ChangeFilter ( Outgoing, "Mailbox", Mailbox, true );
	deletionMark = DC.GetParameter ( Incoming.SettingsComposer, "DeletionMark" );
	deletionMark.Use = true;
	incomingType = DC.GetParameter ( Incoming.SettingsComposer, "IncomingType" );
	if ( RowType = Enum.MailboxLabelsBox () ) then
		filterByLabel ( Incoming, false );
		incomingType.Use = false;
		deletionMark.Value = false;
	elsif ( RowType = Enum.MailboxLabelsIncoming () ) then
		filterByLabel ( Incoming, false );
		incomingType.Use = true;
		incomingType.Value = Type ( "DocumentRef.IncomingEmail" );
		deletionMark.Value = false;
	elsif ( RowType = Enum.MailboxLabelsIncomingLabel ()
		or RowType = Enum.MailboxLabelsIncomingIMAPLabel () ) then
		filterByLabel ( Incoming );
		incomingType.Use = false;
		deletionMark.Value = false;
	elsif ( RowType = Enum.MailboxLabelsOutgoing () ) then
		filterByLabel ( Outgoing, false );
		deletionMark.Value = false;
	elsif ( RowType = Enum.MailboxLabelsOutgoingLabel () ) then
		filterByLabel ( Outgoing );
		deletionMark.Value = false;
	elsif ( RowType = Enum.MailboxLabelsTrash () ) then
		filterByLabel ( Incoming, false );
		incomingType.Use = false;
		deletionMark.Value = true;
	endif; 

EndProcedure 

&AtServer
Procedure filterByLabel ( DataSource, Filter = true )
	
	if ( Filter ) then
		keys = getKeys ();
		DC.ChangeFilter ( DataSource, "Key", keys, true );
	else
		DC.DeleteFilter ( DataSource, "Key" );
	endif; 
	
EndProcedure 

&AtServer
Function getKeys ()
	
	s = "
	|select distinct MailKeys.Ref as Ref
	|from Catalog.MailKeys.Labels as MailKeys
	|where MailKeys.Label = &Label
	|";
	q = new Query ( s );
	q.SetParameter ( "Label", OldLabel );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 

&AtServer
Procedure applyFilters ()
	
	filterBySender ();
	filterByReceiver ();
	filterByText ();
	filterByTasks ();
	
EndProcedure 

&AtServer
Procedure filterBySender ()
	
	table = getTable ( ThisObject );
	DC.ChangeFilter ( table, "Sender", From, not IsBlankString ( From ), DataCompositionComparisonType.Contains );
	
EndProcedure 

&AtClientAtServerNoContext
Function getTable ( Form )
	
	items = Form.Items;
	currentPage =  items.Pages.CurrentPage;
	if ( currentPage = items.IncomingPage
		or currentPage = items.IncomingPagePreview ) then
		return Form.Incoming;
	else
		return Form.Outgoing;		
	endif; 
	
EndFunction 

&AtServer
Procedure filterByReceiver ()
	
	table = getTable ( ThisObject );
	DC.ChangeFilter ( table, "Receiver", Receiver, not IsBlankString ( Receiver ), DataCompositionComparisonType.Contains );
	
EndProcedure 

&AtServer
Procedure filterByText ()
	
	table = getTable ( ThisObject );
	deleteFilters ( table );
	filterID = "5ebccb70-e119-11e3-8b68-0800200c9a66";
	typeGroup = Type ( "DataCompositionFilterItemGroup" );
	typeItem = Type ( "DataCompositionFilterItem" );
	firstGroup = table.SettingsComposer.Settings.Filter.Items.Add ( typeGroup );
	firstGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	firstGroup.Use = true;
	firstGroup.UserSettingID = filterID;
	patterns = Conversion.StringToArray ( TextFilter, " " );
	subjectField = new DataCompositionField ( "Subject" );
	contentField = new DataCompositionField ( "Content" );
	for each pattern in patterns do
		secondGroup = firstGroup.Items.Add ( typeGroup );
		secondGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		secondGroup.Use = true;
		filter = secondGroup.Items.Add ( typeItem );
		filter.LeftValue = subjectField;
		filter.Use = true;
		filter.ComparisonType = DataCompositionComparisonType.Contains;
		filter.RightValue = pattern;
		filter = secondGroup.Items.Add ( typeItem );
		filter.LeftValue = contentField;
		filter.Use = true;
		filter.ComparisonType = DataCompositionComparisonType.Contains;
		filter.RightValue = pattern;
	enddo;	
	
EndProcedure 

&AtServer
Procedure deleteFilters ( Table )
	
	filterID = "5ebccb70-e119-11e3-8b68-0800200c9a66";
	filters = Table.SettingsComposer.Settings.Filter;
	for each item in filters.Items do
		if ( item.UserSettingID = filterID ) then
			filters.Items.Delete ( item );
			break;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure filterByTasks ()
	
	table = getTable ( ThisObject );
	emptyTask = Tasks.UserTask.EmptyRef ();
	if ( TasksFilter.IsEmpty () ) then
		DC.SetParameter ( table, "EmptyTask", undefined, false );
		DC.SetParameter ( table, "ExecutedTasks", undefined, false );
	elsif ( TasksFilter = Enums.EmailTasksFilter.All ) then
		DC.SetParameter ( table, "EmptyTask", emptyTask );
		DC.SetParameter ( table, "ExecutedTasks", undefined, false );
	elsif ( TasksFilter = Enums.EmailTasksFilter.Active ) then
		DC.SetParameter ( table, "EmptyTask", emptyTask );
		DC.SetParameter ( table, "ExecutedTasks", false );
	elsif ( TasksFilter = Enums.EmailTasksFilter.Completed ) then
		DC.SetParameter ( table, "EmptyTask", emptyTask );
		DC.SetParameter ( table, "ExecutedTasks", true );
	endif; 
	
EndProcedure 

&AtServer
Procedure setUnread ()
	
	Unread = Totals.Total ( "Count" );
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageNewMail ()
		or EventName = Enum.MessageEmailIsRead () ) then
		refreshIncoming ();
	elsif ( EventName = Enum.MessageEmailDeleted () ) then
		loadLabels ();
		setAppTitle ();
	elsif ( EventName = Enum.MessageMailLabelChanged () ) then
		loadLabels ();
		restorePosition ( Parameter );
		expandLabels ();
		setAppTitle ();
	elsif ( EventName = Enum.MessageMailBoxChanged () ) then
		loadLabels ();
		restorePosition ( OldLabel );
		expandLabels ();
		setAppTitle ();
	elsif ( EventName = Enum.MessageMailLabelWasAttached () ) then
		loadLabels ();
	elsif ( EventName = Enum.MessageMailLabelWasAttached () ) then
		loadLabels ();
	endif; 
	
EndProcedure

&AtClient
Procedure refreshIncoming ()
	
	loadLabels ();
	incomingTable ( ThisObject ).Refresh ();
	restorePosition ( OldLabel );
	expandLabels ();
	setAppTitle ();
		
EndProcedure 

&AtClientAtServerNoContext
Function incomingTable ( Form )
	
	if ( Form.Preview ) then
		return Form.Items.IncomingPreview;
	else
		return Form.Items.Incoming;
	endif; 
	
EndFunction 

&AtClient
Procedure restorePosition ( Label, Rows = undefined )
	
	if ( Rows = undefined ) then
		Rows = Labels.GetItems ();
	endif; 
	for each row in Rows do
		if ( row.Label = Label ) then
			Items.Labels.CurrentRow = row.GetID ();
			return;
		else
			restorePosition ( Label, row.GetItems () );
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure expandLabels ()
	
	if ( HideTree ) then
		return;
	endif;
	rows = Labels.GetItems ();
	for each row in rows do
		Items.Labels.Expand ( row.GetID (), true );
	enddo;
	
EndProcedure 

&AtClient
Procedure setAppTitle ()
	
	SetAppCaption ( Unread );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( MailIsOpen ) then
		FirstWindow = false;
		Cancel = true;
		return;
	else
		FirstWindow = true;
	endif; 
	MailIsOpen = true;
	findUserProfile ();
	setTitle ();
	setAppTitle ();

EndProcedure

&AtClient
Procedure setTitle ()
	
	if ( Items.Pages.CurrentPage = outgoingPage () ) then
		Title = Output.MailOutbox ();
	else
		label = Items.Labels.CurrentData;
		type = ? ( label = undefined, undefined, label.RowType );
		if ( type = undefined
			or type = Enum.MailboxLabelsBox () ) then
			Title = Output.Mailbox ();
		elsif ( type = Enum.MailboxLabelsIncoming ()
			or type = Enum.MailboxLabelsIncomingLabel ()
			or type = Enum.MailboxLabelsIncomingIMAPLabel () ) then
			Title = Output.MailInbox ();
		elsif ( type = Enum.MailboxLabelsTrash () ) then
			Title = Output.MailTrash ();
		endif;
	endif;
	
EndProcedure 

&AtClient
Procedure findUserProfile ()
	
	if ( not MailChecking.ProfileExists () ) then
		Output.MailboxIsNotConfigured ( ThisObject );
	endif; 
	
EndProcedure 

&AtClient
Procedure MailboxIsNotConfigured ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		Close ();
	else
		OpenForm ( "Catalog.Mailboxes.ObjectForm", , , , , , new NotifyDescription ( "FindProfile", ThisObject ) );
	endif; 
	
EndProcedure 

&AtClient
Procedure FindProfile ( Result, Params ) export
	
	if ( not MailChecking.ProfileExists () ) then
		Close ();
	endif; 
	
EndProcedure 

&AtClient
Procedure OnClose ( Exit )
	
	if ( FirstWindow ) then
		MailIsOpen = false;
	endif; 
	if ( not Exit ) then
		cancelSearch ( true );
	endif; 

EndProcedure

&AtServer
Procedure cancelSearch ( val Closing = false )
	
	job = Jobs.GetByID ( SearchJob );
	if ( job <> undefined ) then
		job.Cancel ();
	endif; 
	if ( Closing ) then
		return;
	endif; 
	DC.DeleteFilter ( getTable ( ThisObject ), "Ref" );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CheckMail ( Command )
	
	OpenForm ( "DataProcessor.EmailClient.Form.Checking" );
	
EndProcedure

&AtClient
Procedure ReceiveMail ( Command )
	
	receive ();
	
EndProcedure

&AtServerNoContext
Procedure receive ()
	
	MailboxesSrv.Receive ();
	
EndProcedure 

&AtClient
Procedure NewEmail ( Command )
	
	openNewEmail ();
	
EndProcedure

&AtClient
Procedure openNewEmail ()
	
	label = Items.Labels.CurrentData;
	if ( label = undefined ) then
		p = undefined;
	else
		values = new Structure ();
		values.Insert ( "Mailbox", label.Mailbox );
		p = new Structure ( "FillingValues", values );
	endif; 
	OpenForm ( "Document.OutgoingEmail.ObjectForm", p , , new UUID () );
	
EndProcedure 

&AtClient
Procedure MarkAllAsRead ( Command )
	
	label = Items.Labels.CurrentData;
	if ( label = undefined ) then
		return;
	endif; 
	deleteNewMail ( label.Mailbox );
	refreshIncoming ();
	NotifyChanged ( Type ( "DocumentRef.IncomingEmail" ) );
	
EndProcedure

&AtServerNoContext
Procedure deleteNewMail ( val Mailbox )
	
	table = getNewMail ( Mailbox );
	r = InformationRegisters.NewMail.CreateRecordManager ();
	BeginTransaction ();
	count = 0;
	for each row in table do
		r.User = SessionParameters.User;
		r.IncomingEmail = row.IncomingEmail;
		r.Delete ();
		count = count + 1;
		if ( count = 300 ) then
			CommitTransaction ();
			BeginTransaction ();
			count = 0;
		endif; 
	enddo; 
	if ( TransactionActive () ) then
		CommitTransaction ();
	endif; 
	
EndProcedure 

&AtServerNoContext
Function getNewMail ( Mailbox )
	
	s = "
	|select NewMail.IncomingEmail as IncomingEmail
	|from InformationRegister.NewMail as NewMail
	|where NewMail.User = &User
	|and NewMail.IncomingEmail.Mailbox = &Mailbox
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Mailbox", Mailbox );
	return q.Execute ().Unload ();
	
EndFunction 

&AtClient
Procedure HideTree ( Command )
	
	hideLabels ();
	
EndProcedure

&AtServer
Procedure hideLabels ()
	
	HideTree = not HideTree;
	if ( HideTree ) then
		initIncoming ();
	endif; 
	LoginsSrv.SaveSettings ( Enum.SettingsHideTree (), , HideTree );
	Appearance.Apply ( ThisObject, "HideTree" );
	
EndProcedure 

// *****************************************
// *********** Group Labels

&AtClient
Procedure LabelsOnActivateRow ( Item )
	
	AttachIdleHandler ( "syncLists", 0.1, true );
	
EndProcedure

&AtClient
Procedure syncLists () export
	
	label = Items.Labels.CurrentData;
	if ( label = undefined ) then
		return;
	endif; 
	if ( label.Label = OldLabel ) then
		return;
	elsif ( label.Label.IsEmpty () ) then
		if ( label.Mailbox = OldLabel ) then
			return;
		endif; 
	endif; 
	setTitle ();
	OldLabel = ? ( label.RowType = Enum.MailboxLabelsBox (), label.Mailbox, label.Label );
	setListByLabel ( label.Mailbox, label.RowType );
	activatePageByLabel ( label.RowType );
	
EndProcedure 

&AtClient
Procedure activatePageByLabel ( RowType )
	
	incomingPage = incomingPage ( ThisObject );
	outgoingPage = outgoingPage ();
	oldPage = Items.Pages.CurrentPage;
	if ( RowType = Enum.MailboxLabelsOutgoing ()
		or RowType = Enum.MailboxLabelsOutgoingLabel () ) then
		currentPage = outgoingPage;
	else
		currentPage = incomingPage;
	endif; 
	if ( currentPage = oldPage ) then
		return;
	elsif ( currentPage = outgoingPage ) then
		activateOutbox ();
	else
		activateInbox ();
	endif; 
	
EndProcedure 

&AtClient
Function outgoingPage ()
	
	if ( Preview ) then
		return Items.OutgoingPagePreview;
	else
		return Items.OutgoingPage;
	endif; 
	
EndFunction 

&AtClient
Procedure activateOutbox ()
	
	resetSearch ();
	Items.Pages.CurrentPage = outgoingPage ();
	setTitle ();
	filterList ();
	
EndProcedure

&AtServer
Procedure filterList ()
	
	if ( FilterIsChanged ) then
		applyFilters ();
		FilterIsChanged = false;
	endif;
	
EndProcedure 

&AtClient
Procedure activateInbox ()
	
	resetSearch ();
	Items.Pages.CurrentPage = incomingPage ( ThisObject );
	setTitle ();
	filterList ();
	
EndProcedure 

&AtClient
Procedure LabelsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	openLabel ();
	
EndProcedure

&AtClient
Procedure openLabel ()
	
	label = Items.Labels.CurrentData;
	if ( label.RowType = Enum.MailboxLabelsBox () ) then
		ShowValue ( , label.Mailbox );
	else
		ShowValue ( , label.Label );
	endif; 
	
EndProcedure 

&AtClient
Procedure LabelsDragCheck ( Item, DragParameters, StandardProcessing, Row, Field )
	
	if ( IncomingDragStarted or OutgoingDragStarted ) then
		if ( targetOK ( Row ) ) then
			StandardProcessing = false;
		endif; 
	endif;
	
EndProcedure

&AtClient
Function targetOK ( Row )
	
	label = Items.Labels.CurrentData;
	if ( Row = undefined or label = undefined ) then
		return false;
	endif; 
	rowData = Items.Labels.RowData ( Row );
	if ( rowData.Mailbox <> label.Mailbox )
		or ( IncomingDragStarted and ( rowData.RowType <> Enum.MailboxLabelsIncoming () and rowData.RowType <> Enum.MailboxLabelsIncomingLabel () and rowData.RowType <> Enum.MailboxLabelsTrash () ) )
		or ( OutgoingDragStarted and ( rowData.RowType <> Enum.MailboxLabelsOutgoing () and rowData.RowType <> Enum.MailboxLabelsOutgoingLabel () and rowData.RowType <> Enum.MailboxLabelsTrash () ) ) then
		return false;
	endif; 
	Target = rowData.Label;
	TargetType = rowData.RowType;
	return true;
	
EndFunction 

&AtClient
Procedure LabelsDrag ( Item, DragParameters, StandardProcessing, Row, Field )
	
	StandardProcessing = false;
	if ( TargetType = Enum.MailboxLabelsTrash () ) then
		deleteEmails ( DragParameters.Value );
	else
		label = Items.Labels.CurrentData;
		markEmails ( DragParameters.Value, label.RowType = Enum.MailboxLabelsTrash () );
	endif; 
	
EndProcedure

&AtClient
Procedure deleteEmails ( Documents )
	
	jobKey = "DeleteEmails" + UserName ();
	startDeletion ( Documents, jobKey );
	Progress.Open ( jobKey, ThisObject, new NotifyDescription ( "EmailsWereDragged", ThisObject ) );
	
EndProcedure 

&AtServerNoContext
Procedure startDeletion ( val Emails, val JobKey )
	
	p = new Array ();
	p.Add ( JobKey );
	p.Add ( Emails );
	Jobs.Run ( "MailboxesSrv.DeleteEmails", p, JobKey );
	
EndProcedure 

&AtClient
Procedure EmailsWereDragged ( Result, Params ) export
	
	loadLabels ();
	if ( Target = OldLabel ) then
		return;
	endif; 
	if ( TargetType = Enum.MailboxLabelsIncoming ()
		or TargetType = Enum.MailboxLabelsIncomingLabel () ) then
		incomingTable ( ThisObject ).Refresh ();
	else
		outgoingTable ( ThisObject ).Refresh ();
	endif; 
		
EndProcedure 

&AtClientAtServerNoContext
Function outgoingTable ( Form )
	
	if ( Form.Preview ) then
		return Form.Items.OutgoingPreview;
	else
		return Form.Items.Outgoing;
	endif; 
	
EndFunction 

&AtClient
Procedure markEmails ( Documents, FromTrash )
	
	jobKey = "MarkEmails" + UserName ();
	startEmailsMarking ( Documents, Target, FromTrash, jobKey );
	Progress.Open ( jobKey, ThisObject, new NotifyDescription ( "EmailsWereDragged", ThisObject ) );
	
EndProcedure 

&AtServerNoContext
Procedure startEmailsMarking ( val Emails, val Label, val FromTrash, val JobKey )
	
	p = new Array ();
	p.Add ( Emails );
	p.Add ( Label );
	p.Add ( FromTrash );
	Jobs.Run ( "MailboxesSrv.MarkEmails", p, JobKey );
	
EndProcedure 

&AtClient
Procedure NewMailbox ( Command )
	
	OpenForm ( "Catalog.Mailboxes.ObjectForm" );
	
EndProcedure

// *****************************************
// *********** Group Pages

&AtClient
Procedure CreateLabel ( Command )
	
	label = Items.Labels.CurrentData;
	if ( label = undefined ) then
		return;
	endif; 
	openNewLabel ();
	
EndProcedure

&AtClient
Procedure openNewLabel ()
	
	values = new Structure ( "FillingValues" );
	label = Items.Labels.CurrentData;
	values.Insert ( "Owner", label.Mailbox );
	values.Insert ( "Parent", getFolder () );
	if ( label.RowType = Enum.MailboxLabelsBox ()
		or label.RowType = Enum.MailboxLabelsIncoming ()
		or label.RowType = Enum.MailboxLabelsIncomingLabel ()
		or label.RowType = Enum.MailboxLabelsIncomingIMAPLabel () ) then
		values.Insert ( "LabelType", PredefinedValue ( "Enum.LabelTypes.Incoming" ) );
	else
		values.Insert ( "LabelType", PredefinedValue ( "Enum.LabelTypes.Outgoing" ) );
	endif; 
	OpenForm ( "Catalog.MailLabels.ObjectForm", new Structure ( "FillingValues", values ) );
	
EndProcedure 

&AtClient
Function getFolder ()
	
	label = Items.Labels.CurrentData;
	if ( label.RowType = Enum.MailboxLabelsBox () ) then
		return label.GetItems () [ 0 ].Label;
	elsif ( label.RowType = Enum.MailboxLabelsIncomingIMAPLabel () ) then
		return getMyMailLabel ();
	else
		return label.Label;
	endif; 
	
EndFunction 

&AtClient
Function getMyMailLabel ()
	
	label = Items.Labels.CurrentData;
	rows = label.GetParent ().GetItems ();
	label = undefined;
	for each row in rows do
		if ( row.RowType = Enum.MailboxLabelsIncoming () ) then
			label = row.Label;
			break;
		endif; 
	enddo; 
	return label;
	
EndFunction 

&AtClient
Procedure OpenProperties ( Command )
	
	label = Items.Labels.CurrentData;
	if ( label = undefined ) then
		return;
	endif; 
	openLabel ();
	
EndProcedure

&AtClient
Procedure RemoveLabel ( Command )
	
	label = Items.Labels.CurrentData;
	if ( label = undefined ) then
		return;
	endif; 
	if ( label.RowType = Enum.MailboxLabelsBox () ) then
		Output.RemoveMailboxConfirmation ( ThisObject, label.Mailbox );
	else
		Output.RemoveLabelConfirmation ( ThisObject, label.Label );
	endif; 
	
EndProcedure

&AtClient
Procedure RemoveMailboxConfirmation ( Answer, Ref ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	removeMailbox ( Ref );
	refreshIncoming ();
	findUserProfile ();
	
EndProcedure 

&AtClient
Procedure RemoveLabelConfirmation ( Answer, Ref ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	setDeletionMark ( Ref );
	deleteRow ();
	
EndProcedure 

&AtServer
Procedure removeMailbox ( val Mailbox )
	
	if ( MailChecking.AlreadyStarted () ) then
		Output.CannotRemoveMailbox ();
		return;
	endif; 
	setDeletionMark ( Mailbox );
	deleteNewMail ( Mailbox );
	
EndProcedure 

&AtServerNoContext
Procedure setDeletionMark ( val Ref )
	
	obj = Ref.GetObject ();
	obj.SetDeletionMark ( true );
	
EndProcedure 

&AtClient
Procedure deleteRow ( Rows = undefined )
	
	if ( Rows = undefined ) then
		Rows = Labels.GetItems ();
	endif; 
	label = Items.Labels.CurrentData;
	for each row in Rows do
		if ( row = label ) then
			Rows.Delete ( row );
			return;
		else
			deleteRow ( row.GetItems () );
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure RefreshLabels ( Command )
	
	refreshIncoming ();
	
EndProcedure

&AtClient
Procedure ShowHiddenLabels ( Command )
	
	applyShowHiddenLabels ();
	
EndProcedure

&AtClient
Procedure applyShowHiddenLabels ()
	
	ShowHiddenLabels = not ShowHiddenLabels;
	refreshIncoming ();
	Appearance.Apply ( ThisObject, "ShowHiddenLabels" );
	
EndProcedure 

// *****************************************
// *********** Page Incoming

&AtClient
Procedure GotoInbox ( Command )
	
	activateInbox ();
	
EndProcedure

&AtClient
Procedure GotoOutbox ( Command )
	
	activateOutbox ();
	
EndProcedure

&AtClient
Procedure SetLabel ( Command )
	
	label = Items.Labels.CurrentData;
	if ( label = undefined ) then
		return;
	endif; 
	openLabels ();
	
EndProcedure

&AtClient
Procedure openLabels ()
	
	label = Items.Labels.CurrentData;
	currentPage = Items.Pages.CurrentPage;
	if ( currentPage = Items.IncomingPage ) then
		set = Items.Incoming.SelectedRows;
		labelType = PredefinedValue ( "Enum.LabelTypes.Incoming" );
		fromTrash = label.RowType = Enum.MailboxLabelsTrash ();
	elsif ( currentPage = Items.IncomingPagePreview ) then
		set = Items.IncomingPreview.SelectedRows;
		labelType = PredefinedValue ( "Enum.LabelTypes.Incoming" );
		fromTrash = label.RowType = Enum.MailboxLabelsTrash ();
	elsif ( currentPage = Items.OutgoingPage ) then
		set = Items.Outgoing.SelectedRows;
		labelType = PredefinedValue ( "Enum.LabelTypes.Outgoing" );
		fromTrash = false;
	elsif ( currentPage = Items.OutgoingPagePreview ) then
		set = Items.OutgoingPreview.SelectedRows;
		labelType = PredefinedValue ( "Enum.LabelTypes.Outgoing" );
		fromTrash = false;
	endif; 
	if ( set.Count () = 0 ) then
		return;
	endif; 
	p = new Structure ( "Filter", new Structure () );
	filter = p.Filter;
	filter.Insert ( "Owner", label.Mailbox );
	filter.Insert ( "LabelType", labelType );
	callbackParams = new Structure ();
	callbackParams.Insert ( "Documents", set );
	callbackParams.Insert ( "Mailbox", label.Mailbox );
	callbackParams.Insert ( "LabelType", labelType );
	callbackParams.Insert ( "FromTrash", fromTrash );
	OpenForm ( "Catalog.MailLabels.ChoiceForm", p, , , , , new NotifyDescription ( "ChooseLabel", ThisObject, callbackParams ) );
	
EndProcedure 

&AtClient
Procedure ChooseLabel ( Label, Params ) export
	
	if ( Label = undefined ) then
		return;
	endif; 
	Target = Label;
	if ( Params.LabelType = PredefinedValue ( "Enum.LabelTypes.Incoming" ) ) then
		TargetType = Enum.MailboxLabelsIncomingLabel ();
	else
		TargetType = Enum.MailboxLabelsOutgoingLabel ();
	endif; 
	jobKey = "MarkEmails" + UserName ();
	startEmailsMarking ( Params.Documents, Label, Params.FromTrash, jobKey );
	Progress.Open ( jobKey, ThisObject, new NotifyDescription ( "EmailsWereDragged", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure Preview ( Command )
	
	enablePreview ();
	
EndProcedure

&AtServer
Procedure enablePreview ()
	
	Preview = true;
	LoginsSrv.SaveSettings ( Enum.SettingsEmailsPreview (), , true );
	Appearance.Apply ( ThisObject, "Preview" );
		
EndProcedure 

&AtClient
Procedure IncomingDragStart ( Item, DragParameters, Perform )
	
	IncomingDragStarted = true;
	
EndProcedure

&AtClient
Procedure IncomingDragEnd ( Item, DragParameters, StandardProcessing )
	
	IncomingDragStarted = false;
	
EndProcedure

&AtClient
Procedure IncomingBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	openNewEmail ();
	
EndProcedure

&AtClient
Procedure IncomingSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( clickOnMemo ( Item ) ) then
		StandardProcessing = false;
		ShowValue ( , Item.CurrentData.Task );
	endif; 
	
EndProcedure

&AtClient
Function clickOnMemo ( Item )
	
	column = Item.CurrentItem.Name;
	return ( column = "IncomingPicture" or column = "IncomingPreviewPicture" 
		or column = "OutgoingPicture" or column = "OutgoingPreviewPicture"
		or column = "IncomingTaskPicture" or column = "IncomingMemo"
		or column = "OutgoingTaskPicture" or column = "OutgoingMemo" )
	and not Item.CurrentData.Task.IsEmpty ();
	
EndFunction 

// *****************************************
// *********** Page Outgoing

&AtClient
Procedure OutgoingDragStart ( Item, DragParameters, Perform )
	
	OutgoingDragStarted = true;
	
EndProcedure

&AtClient
Procedure OutgoingDragEnd ( Item, DragParameters, StandardProcessing )
	
	OutgoingDragStarted = false;
	
EndProcedure

// *****************************************
// *********** Page IncomingPreview

&AtClient
Procedure ToList ( Command )
	
	disablePreview ();
	
EndProcedure

&AtServer
Procedure disablePreview ()
	
	Preview = false;
	LoginsSrv.SaveSettings ( Enum.SettingsEmailsPreview (), , false );
	Appearance.Apply ( ThisObject, "Preview" );
		
EndProcedure 

&AtClient
Procedure OpenFilter ( Command )
	
	resetSearch ();
	showFilters ();
	activateFilter ();
	
EndProcedure

&AtClient
Procedure resetSearch ()
	
	if ( SearchStarted
		or SearchString <> "" ) then
		detachSeach ();
		cancelSearch ();
		completeSearching ();
		SearchString = "";
	endif; 
	
EndProcedure 

&AtServer
Procedure showFilters ()
	
	QuickFilter = true;
	deleteFilters ( getTable ( ThisObject ) );
	Appearance.Apply ( ThisObject, "QuickFilter" );
	
EndProcedure 

&AtClient
Procedure activateFilter ()
	
	if ( Items.Pages.CurrentPage = Items.IncomingPagePreview ) then
		CurrentItem = Items.From;
	elsif ( Items.Pages.CurrentPage = Items.OutgoingPagePreview ) then
		CurrentItem = Items.From3;
	elsif ( Items.Pages.CurrentPage = Items.IncomingPage ) then
		CurrentItem = Items.From1;
	elsif ( Items.Pages.CurrentPage = Items.OutgoingPage ) then
		CurrentItem = Items.From2;
	endif; 
	
EndProcedure 

&AtClient
Procedure HideFilter ( Command )
	
	hideFilters ();
	FilterIsChanged = true;
	
EndProcedure

&AtServer
Procedure hideFilters ()
	
	QuickFilter = false;
	resetFilters ();
	filterBySender ();
	filterByReceiver ();
	filterByText ();
	filterByTasks ();
	Appearance.Apply ( ThisObject, "QuickFilter" );
	
EndProcedure 

&AtServer
Procedure resetFilters ()
	
	From = "";
	Receiver = "";
	TextFilter = "";
	TasksFilter = undefined;
	
EndProcedure 

&AtClient
Procedure SearchStringEditTextChange ( Item, Text, StandardProcessing )
	
	scheduleSearch ( Item, Text );
	
EndProcedure

&AtClient
Procedure scheduleSearch ( Item, Text )
	
	detachSeach ();
	SearchItem = Item;
	SearchItem.ChoiceButton = true;
	SearchString = Text;
	SearchStarted = true;
	AttachIdleHandler ( "startSearch", 0.5, true );
	
EndProcedure 

&AtClient
Procedure detachSeach ()
	
	DetachIdleHandler ( "checkSearch" );
	DetachIdleHandler ( "startSearch" );
	
EndProcedure 

&AtClient
Procedure startSearch ()
	
	table = getTable ( ThisObject );
	if ( IsBlankString ( SearchString ) ) then
		cancelSearch ();
		completeSearching ();
	else
		if ( table = Incoming ) then
			label = Items.Labels.CurrentData;
			if ( label = undefined
				or label.RowType = Enum.MailboxLabelsBox () ) then
				scope = PredefinedValue ( "Enum.Search.Mail" );
			else
				scope = PredefinedValue ( "Enum.Search.Incoming" );
			endif;
		else
			scope = PredefinedValue ( "Enum.Search.Outgoing" );
		endif; 
		SearchJob = runSearch ( SearchString, scope, UUID, SearchJob, SearchResult );
		AttachIdleHandler ( "checkSearch", 1, true );
	endif;
	
EndProcedure

&AtClient
Procedure completeSearching ()
	
	SearchStarted = false;
	SearchItem.ChoiceButton = false;
	
EndProcedure 

&AtClient
Procedure checkSearch () export
	
	if ( searchCompleted ( SearchJob ) ) then
		table = getTable ( ThisObject );
		refs = GetFromTempStorage ( SearchResult );
		DC.ChangeFilter ( table, "Ref", refs, true );
		completeSearching ();
	else
		AttachIdleHandler ( "checkSearch", 1, true );
	endif; 
	
EndProcedure 

&AtServerNoContext
Function searchCompleted ( val ID )
	
	return Jobs.GetByID ( ID ) = undefined;
	
EndFunction 

&AtServerNoContext
Function runSearch ( val SearchString, val Scope, val UUID, val SearchJob, SearchResult )
	
	SearchResult = PutToTempStorage ( undefined, UUID );
	params = new Array ();
	params.Add ( SearchString );
	params.Add ( Scope );
	params.Add ( SearchResult );
	params.Add ( SearchJob );
	return Jobs.Run ( "FullSearch.Background", params ).UUID;
	
EndFunction 

&AtClient
Procedure SearchStringStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure SearchStringClearing ( Item, StandardProcessing )
	
	scheduleSearch ( Item, "" );
	
EndProcedure

&AtClient
Procedure FromOnChange ( Item )
	
	filterBySender ();
	FilterIsChanged = true;
	
EndProcedure

&AtClient
Procedure FromAutoComplete ( Item, Text, ChoiceData, Parameters, Wait, StandardProcessing )
	
	EmailsTip.ShowShort ( Text, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ReceiverOnChange ( Item )
	
	filterByReceiver ();
	FilterIsChanged = true;
	
EndProcedure

&AtClient
Procedure ReceiverAutoComplete ( Item, Text, ChoiceData, Parameters, Wait, StandardProcessing )
	
	EmailsTip.ShowShort ( Text, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure TextFilterOnChange ( Item )
	
	filterByText ();
	FilterIsChanged = true;
	
EndProcedure

&AtClient
Procedure TasksFilterOnChange ( Item )
	
	filterByTasks ();
	FilterIsChanged = true;
	
EndProcedure

&AtClient
Procedure IncomingPreviewOnActivateRow ( Item )
	
	CurrentEmail = Items.IncomingPreview.CurrentData;
	AttachIdleHandler ( "showEmail", 0.1, true );
	
EndProcedure

&AtClient
Procedure showEmail () export
	
	if ( CurrentEmail = undefined ) then
		IncomingBody = "";
		return;
	endif; 
	if ( CurrentEmail.Ref = OldEmail ) then
		return;
	endif; 
	OldEmail = CurrentEmail.Ref;
	if ( CurrentEmail.Unread ) then
		downloadEmail ();
		incomingTable ( ThisObject ).Refresh ();
		setAppTitle ();
	endif; 
	IncomingBody = fetchBody ( OldEmail, adjustText ( getSearchText ( ThisObject ) ) );
	
EndProcedure 

&AtClientAtServerNoContext
Function getSearchText ( Form )
	
	return ? ( Form.QuickFilter, Form.TextFilter, Form.SearchString );

EndFunction 

&AtClientAtServerNoContext
Function adjustText ( Text )
	
	if ( IsBlankString ( Text ) ) then
		return "";
	endif; 
	parts = Conversion.StringToArray ( Lower ( Text ), " " );
	s = "";
	for each part in parts do
		if ( part = "" ) then
			continue;
		endif; 
		s = s + " " + part;
	enddo; 
	return Mid ( s, 2 );
	
EndFunction 

&AtServer
Procedure downloadEmail ()
	
	Documents.IncomingEmail.MarkAsRead ( OldEmail );
	loadLabels ();
	
EndProcedure

&AtServerNoContext
Function getBody ( val Email, val Highlighting )
	
	fields = DF.Values ( Email, "MessageID, Mailbox" );
	return EmailsSrv.GetHTML ( Email, fields.MessageID, fields.Mailbox, true, , Highlighting );
	
EndFunction 

&AtClient
Function fetchBody ( Email, Highlighting )
	
	#if ( WebClient ) then
		p = new Structure ();
		p.Insert ( "ID", Email.UUID () );
		p.Insert ( "Incoming", ? ( TypeOf ( Email ) = Type ( "DocumentRef.IncomingEmail" ), "1", "0" ) );
		searching = Highlighting <> "";
		if ( searching ) then
			p.Insert ( "Highlighting", Highlighting );
		endif;
		s = "
		|<!DOCTYPE html>
		|<html lang='ru'>
		|<head>
		|	<meta charset='UTF-8'>
		|	<script>
		|";
		if ( searching ) then
			s = s + EmailsSrv.GetFunctions ();
		endif; 
		s = s + "
		|		function inject ( element ) {
		|		var xhr = new XMLHttpRequest ();
		|		xhr.onreadystatechange = function () {
		|			if ( xhr.readyState == 4 ) {
		|				if ( (xhr.status >= 200 && xhr.status < 300) || xhr.status == 304 ) {
		|					element.innerHTML = xhr.responseText;
		|";
		if ( searching  ) then
			s = s + "highlightWord('%Highlighting');";
		endif; 
		s = s + "
		|				} else {
		|					element.innerHTML = 'Request was unsuccessful: ' + xhr.status;
		|				}
		|			}
		|		};
		|	xhr.open ( 'get', '" + MailService + "/hs/Email?ID=%ID&Incoming=%Incoming', true );
		|	xhr.send ( null );
		|}
		|	</script>
		|</head>
		|<body onload='inject(document.getElementById(""content""))'>
		|<div id='content'></div>
		|</body>
		|</html>
		|";
		return Output.FormatStr ( s, p );
	#else
		return getBody ( Email, Highlighting );
	#endif 
		
EndFunction

&AtClient
Procedure IncomingBodyOnClick ( Item, EventData, StandardProcessing )
	
	openLink ( EventData, StandardProcessing );

EndProcedure

&AtClient
Procedure openLink ( EventData, StandardProcessing )
	
	label = Items.Labels.CurrentData;
	mailbox = ? ( label = undefined, PredefinedValue ( "Catalog.Mailboxes.EmptyRef" ), label.Mailbox );
	Emails.OpenLink ( EventData, StandardProcessing, mailbox, OldEmail );
	
EndProcedure 

// *****************************************
// *********** Page OutgoingPreview

&AtClient
Procedure OutgoingPreviewOnActivateRow ( Item )
	
	CurrentOutgoingEmail = Items.OutgoingPreview.CurrentData;
	AttachIdleHandler ( "showCurrentOutgoingEmail", 0.1, true );
	
EndProcedure

&AtClient
Procedure showCurrentOutgoingEmail () export
	
	if ( CurrentOutgoingEmail = undefined ) then
		OutgoingBody = "";
		return;
	endif; 
	if ( CurrentOutgoingEmail.Ref = OldEmail ) then
		return;
	endif; 
	OldEmail = CurrentOutgoingEmail.Ref;
	OutgoingBody = fetchBody ( OldEmail, adjustText ( getSearchText ( ThisObject ) ) );
	
EndProcedure 

// *****************************************
// *********** Variables Initialization

#if ( not Server ) then
	IncomingDragStarted = false;
	OutgoingDragStarted = false;
#endif