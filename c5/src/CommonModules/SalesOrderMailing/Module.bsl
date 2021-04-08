Procedure Send ( Params ) export

	SetPrivilegedMode ( true );
	env = initEnv ();
	getData ( Params, env );
	profile = MailboxesSrv.SystemProfile ();
	table = Env.Receivers;
	for each row in table do
		message = getMessage ( Params, Env, row );
		try
			MailboxesSrv.Post ( profile, message );
		except
			WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.CommonModules.SalesOrderMailing, Params.Ref, ErrorDescription () );
		endtry
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

Function initEnv ()
	
	env = new Structure ();
	SQL.Init ( env );
	return env;
	
EndFunction

Procedure getData ( Params, Env )
	
	sqlFields ( Env );
	sqlItems ( Env );
	sqlReceivers ( Params, Env );
	Env.Q.SetParameter ( "Ref", Params.Ref );
	Env.Q.SetParameter ( "Process", Params.Process );
	Env.Q.SetParameter ( "Sender", Params.Sender );
	Env.Q.SetParameter ( "Noreply", Cloud.Noreply () );
	Env.Q.SetParameter ( "EmptyMemo", Output.EmptyMemo () );
	SQL.Perform ( Env );
	Env.Insert ( "Discounts", Options.Discounts ( Env.Fields.Company ) );

EndProcedure 

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Number as Number, Documents.Department.Description as Department,
	|	Documents.Creator.Description as Responsible, Documents.Amount as Amount,
	|	Documents.Currency.Description as Currency, Documents.Creator.Email as CreatorEmail,
	|	Documents.Creator.Description as Creator, Senders.Email as SenderEmail, Senders.Description as Sender
	|from Document.SalesOrder as Documents
	|	//
	|	// Senders
	|	//
	|	join Catalog.Users as Senders
	|	on Senders.Ref = &Sender
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|// #Items
	|select Items.LineNumber as LineNumber, Items.Item.Description as Item,
	|	Items.Package.Description as Package, Items.QuantityPkg as Quantity,
	|	Items.Price as Price, Items.Amount as Amount, Items.Discount as Discount
	|from Document.SalesOrder.Items as Items
	|where Items.Ref = &Ref
	|;
	|// #Services
	|select Services.LineNumber as LineNumber, Services.Description as Item,
	|	Services.Item.Unit.Code as Package, Services.Quantity as Quantity,
	|	Services.Price as Price, Services.Amount as Amount, Services.Discount as Discount
	|from Document.SalesOrder.Services as Services
	|where Services.Ref = &Ref
	|";
	Env.Selection.Add ( s );	
	
EndProcedure

Procedure sqlReceivers ( Params, Env )
	
	s = "
	|// #Receivers
	|select Receivers.User as User, Receivers.RoutePoint as RoutePoint, Receivers.Email as Email, isnull ( Memos.Memo, &EmptyMemo ) as Memo
	|from (
	|	select Tasks.User as User, Tasks.RoutePoint as RoutePoint, Tasks.User.Email as Email
	|	from Task.Task as Tasks
	|	where not Tasks.Executed
	|	and not Tasks.DeletionMark
	|	and Tasks.BusinessProcess = &Process
	|	and Tasks.User <> value ( Catalog.Users.EmptyRef )
	|	and Tasks.User.Email <> """"
	|	union
	|	select BPRouter.User, Tasks.RoutePoint, BPRouter.User.Email
	|	from Task.Task as Tasks
	|		//
	|		// BPRouter
	|		//
	|		join InformationRegister.BPRouter as BPRouter
	|		on BPRouter.Activity
	|		and BPRouter.Role = Tasks.Role
	|		and BPRouter.Department = Tasks.Department
	|		and Tasks.RoutePoint = value ( BusinessProcess.SalesOrder.RoutePoint.DepartmentHeadResolution )
	|		and BPRouter.User.Email <> """"
	|	where not Tasks.Executed
	|	and not Tasks.DeletionMark
	|	and Tasks.BusinessProcess = &Process
	|	and Tasks.User = value ( Catalog.Users.EmptyRef )
	|	) as Receivers
	|	//
	|	// Memo
	|	//
	|	left join (
	|		select top 1 Memos.Memo as Memo, Memos.User as User
	|		from InformationRegister.SalesOrderResolutions as Memos
	|		where Memos.Document = &Ref
	|		order by Memos.Date desc
	|	) as Memos
	|	on Memos.User = &Sender
	|where Receivers.RoutePoint in ( value ( BusinessProcess.SalesOrder.RoutePoint.DepartmentHeadResolution ),
	|	value ( BusinessProcess.SalesOrder.RoutePoint.Reject ),
	|	value ( BusinessProcess.SalesOrder.RoutePoint.Rework ),
	|	value ( BusinessProcess.SalesOrder.RoutePoint.Shipping ),
	|	value ( BusinessProcess.SalesOrder.RoutePoint.Invoicing )
	|	)
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Function getMessage ( Params, Env, Receiver )
	
	message = new InternetMailMessage ();
	message.To.Add ( Receiver.Email );
	fillMessage ( Params, Env, Receiver, message );
	return message;
	
EndFunction 

Procedure fillMessage ( Params, Env, Receiver, Message )
	
	routePoint = Receiver.RoutePoint;
	lastRoutePoint = Params.LastRoutePoint;
	parts = new Structure ();
	parts.Insert ( "SalesOrderURL", Conversion.ObjectToURL ( Params.Ref ) );
	parts.Insert ( "Department", Env.Fields.Department );
	parts.Insert ( "Number", Env.Fields.Number );
	parts.Insert ( "Sender", Env.Fields.Sender );
	parts.Insert ( "Creator", Env.Fields.Creator );
	parts.Insert ( "Responsible", Env.Fields.Responsible );
	parts.Insert ( "Memo", Receiver.Memo );
	parts.Insert ( "Amount", Conversion.NumberToMoney ( Env.Fields.Amount, Env.Fields.Currency ) );
	parts.Insert ( "RoutePoint", routePoint );
	parts.Insert ( "Items", getItems ( Env, "Items", Receiver ) );
	parts.Insert ( "Services", getItems ( Env, "Services", Receiver ) );
	routePoints = BusinessProcesses.SalesOrder.RoutePoints;
	if ( rework ( routePoint, lastRoutePoint ) ) then
		Message.Subject = Output.ReworkSubject ( parts );
		Message.Texts.Add ( Output.ReworkBody ( parts ) );
		Message.From = Env.Fields.SenderEmail;
	elsif ( routePoint = routePoints.Reject ) then
		Message.Subject = Output.RejectSubject ( parts );
		Message.Texts.Add ( Output.RejectBody ( parts ) );
		Message.From = Env.Fields.SenderEmail;
	elsif ( routePoint = routePoints.Invoicing ) then
		Message.Subject = Output.InvoicingSubject ( parts );
		Message.Texts.Add ( Output.InvoicingBody ( parts ) );
		Message.From = Env.Fields.SenderEmail;
	elsif ( routePoint = routePoints.DepartmentHeadResolution
		or routePoint = routePoints.Shipping ) then
		if ( lastRoutePoint = Enums.SalesOrderPoints.Rework ) then
			Message.Subject = Output.AgainApprovalSubject ( parts );
			Message.Texts.Add ( Output.AgainApprovalBody ( parts ) );
		else
			if ( lastRoutePoint = Enums.SalesOrderPoints.New ) then
				parts.Insert ( "Performer", "" );
			else
				parts.Insert ( "Performer", Output.PreviousPerformer ( new Structure ( "Performer", Env.Fields.Sender ) ) );
			endif; 
			Message.Subject = Output.ApprovalSubject ( parts );
			Message.Texts.Add ( Output.ApprovalBody ( parts ) );
		endif; 
		Message.From = Env.Fields.CreatorEmail;
	endif; 
	
EndProcedure 

Function rework ( RoutePoint, LastRoutePoint )
	
	routePoints = BusinessProcesses.SalesOrder.RoutePoints;
	return RoutePoint = routePoints.Rework;
		
EndFunction 

Function getItems ( Env, TableName, Receiver )
	
	table = Env [ TableName ];
	if ( table.Count () = 0 ) then
		return "";
	endif; 
	items = new Array ();
	items.Add ( Metadata.Documents.SalesOrder.TabularSections [ TableName ].Presentation () + ":" );
	p = new Structure ( "LineNumber, Item, Quantity, Price, Discount, Amount, Comment" );
	currency = Env.Fields.Currency;
	for each row in table do
		p.LineNumber = row.LineNumber;
		p.Item = row.Item;
		p.Quantity = Conversion.NumberToQuantity ( row.Quantity, row.Package );
		p.Price = Conversion.NumberToMoney ( row.Price, currency );
		if ( Env.Discounts ) then
			p.Discount = ", " + Output.Discount ( new Structure ( "Discount", Conversion.NumberToMoney ( row.Discount, currency ) ) );
		endif; 
		p.Amount = Conversion.NumberToMoney ( row.Amount, currency );
		items.Add ( Output.ItemsRow ( p ) );
	enddo; 
	return Chars.LF + StrConcat ( items, Chars.LF );
	
EndFunction 
