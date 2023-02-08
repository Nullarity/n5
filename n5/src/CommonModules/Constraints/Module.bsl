
Procedure ShowSales ( Form ) export
	
	data = getSalesData ( Form.Object );
	hideSales ( Form );
	if ( data = undefined ) then
		return;
	endif;
	position = 1;
	if ( customerBanned ( data ) ) then
		subject = Output.RestrictionSalesBanned ();
		displaySales ( Form, data, Enums.RestrictionReasons.SaleBanned, subject, position );
		position = position + 1;
	endif;
	if ( contractRequired ( data ) ) then
		subject = Output.RestrictionNoContract ();
		displaySales ( Form, data, Enums.RestrictionReasons.NoContract, subject, position );
		position = position + 1;
	endif;
	if ( data.ControlCredit  ) then
		if ( creditExceeded ( data ) ) then
			p = new Structure ( "Amount", Conversion.NumberToMoney ( - data.Sales.Limit ) );
			subject = Output.RestrictionCreditExceeded ( p );
			displaySales ( Form, data, Enums.RestrictionReasons.CreditLimit, subject, position );
		else
			displayLimit ( Form, data, position );
		endif;
		position = position + 1;
	endif;
	if ( invoiceRequired ( data ) ) then
		p = new Structure ( "Invoice", data.InvoiceOnHand.Invoice );
		subject = Output.RestrictionInvoiceRequired ( p );
		displaySales ( Form, data, Enums.RestrictionReasons.NoInvoice, subject, position );
		position = position + 1;
	endif;

EndProcedure

Procedure hideSales ( Form )
	
	for each item in Form.Items.Restrictions.ChildItems do
		if ( StrStartsWith ( item.Name, "RestrictionGroup" ) ) then
			item.Visible = false;
		endif;
	enddo;

EndProcedure

Function getSalesData ( Object )

	if ( IsInRole ( Metadata.Roles.ModifyIssuedInvoices ) ) then
		return undefined;
	endif;
	context = getContext ( Object );
	if ( context = undefined ) then
		return undefined;
	endif;
	info = getSalesInfo ( Object, context );
	data = new Structure ( "ControlContracts, ControlCredit, ControlTaxInvoices, Amount, Currency,
	|Sales, InvoiceOnHand, Approved" );
	FillPropertyValues ( data, context );
	FillPropertyValues ( data, info );
	return data;

EndFunction

Function getContext ( Object )

	context = new Structure ( "Customer, Contract, Currency, Amount, Company, ControlContracts,
	|ControlCredit, ControlTaxInvoices, Today" );
	ref = Object.Ref;
	type = TypeOf ( ref );
	if ( type = Type ( "DocumentRef.Invoice" )
		or type = Type ( "DocumentRef.SalesOrder" )
		or type = Type ( "DocumentRef.Quote" )
	) then
		context.Customer = valueOf ( Object.Customer );
		context.Contract = valueOf ( Object.Contract );
		context.Company = valueOf ( Object.Company );
		context.Currency = valueOf ( Object.Currency );
		if ( type = Type ( "DocumentRef.Invoice" ) ) then 
			context.Amount = Object.Amount;
		else
			context.Amount = 0;
		endif;
	elsif ( type = Type ( "DocumentRef.InvoiceRecord" )
		and Documents.InvoiceRecord.Independent ( Object ) ) then
		customer = Object.Customer;
		if ( TypeOf ( customer ) = Type ( "CatalogRef.Organizations" ) ) then
			context.Customer = valueOf ( customer );
			context.Contract = valueOf ( DF.Pick ( customer, "CustomerContract" ) );
			context.Company = valueOf (	Object.Company );
			context.Currency = valueOf ( Object.Currency );
			context.Amount = Object.Amount;
		endif;
	endif;
	if ( context.Customer = undefined
		or context.Company = undefined ) then
		return undefined;
	endif;
	context.ControlCredit = Options.ControlCredit ();
	context.ControlContracts = Options.ControlContracts ();
	context.ControlTaxInvoices = Options.ControlTaxInvoices ();
	control = context.ControlCredit or context.ControlContracts or context.ControlTaxInvoices;
	if ( not control ) then
		return undefined;
	endif;
	context.Today = CurrentSessionDate ();
	return context;

EndFunction

Function valueOf ( Reference )

	return ? ( ValueIsFilled ( Reference ), Reference, undefined );

EndFunction

Function getSalesInfo ( Object, Context )
	
	controlCredit = Context.ControlCredit;
	controlContracts = Context.ControlContracts;
	controlTaxInvoices = Context.ControlTaxInvoices;
	selection = new Array ();
	selection.Add ( "
	|// #Approved
	|select Restrictions.Reason as Reason, Restrictions.Ref as Permission,
	|	Restrictions.Ref.Amount as Amount, Restrictions.Ref.Currency as Currency,
	|	case
	|		when Restrictions.Ref.Resolution = value ( Enum.AllowDeny.Allow ) then
	|			case when &Today between Restrictions.Ref.Date and Restrictions.Ref.Expired
	|				then value ( Enum.AllowDeny.Allow )
	|				else value ( Enum.AllowDeny.EmptyRef )
	|			end
	|		else Restrictions.Ref.Resolution
	|	end as Resolution
	|from Document.SalesPermission.Restrictions as Restrictions
	|where Restrictions.Ref.Document = &Ref
	|and Restrictions.Ref.Customer = &Customer
	|and not Restrictions.Ref.DeletionMark" );
	if ( controlCredit or controlContracts ) then
		selection.Add ( "
		|;
		|// Debts
		|select Debts.Contract.Currency as Currency, ( Debts.AmountBalance - Debts.OverpaymentBalance ) as Debt
		|into Debts
		|from AccumulationRegister.Debts.Balance ( , Contract.Owner = &Customer ) as Debts
		|union all
		|select Debts.Contract.Currency, - ( Debts.AmountBalance - Debts.OverpaymentBalance )
		|from AccumulationRegister.VendorDebts.Balance ( , Contract.Owner = &Customer ) as Debts
		|union all
		|select Debts.Contract.Currency, - ( Debts.Amount + Debts.Overpayment )
		|from AccumulationRegister.Debts as Debts
		|where Debts.Recorder = &Ref
		|union all
		|select &Currency, &Amount
		|;
		|// Exchange Rates
		|select Rates.Currency as Currency, Rates.Rate as Rate, Rates.Factor as Factor
		|into Rates
		|from InformationRegister.ExchangeRates.SliceLast ( ,
		|	Currency in ( select Currency from Debts )
		|) as Rates" );
	endif;
	selection.Add ( "
	|;
	|// @Sales
	|select sum ( Debts.Debt ) as Debt, sum ( Debts.Limit ) - sum ( Debts.Debt ) as Limit,
	|	1 = max ( Debts.NoLimit ) as NoLimit,
	|	1 = max ( Debts.Ban ) as Ban,
	|	1 = max ( Debts.Signed ) as Signed,
	|	0 = max ( Debts.FirstSale ) as FirstSale
	|from (
	|	select 0 as Debt, 0 as Limit, 0 as NoLimit, 0 as Ban, 0 as Signed, 0 as FirstSale
	|	union all
	|	select 0, 0, 0, case when Restrictions.Ban then 1 else 0 end, 0, 0
	|	from (
	|		select top 1 Restrictions.Ban as Ban
	|		from Document.SalesRestriction as Restrictions
	|		where not Restrictions.DeletionMark
	|		and Restrictions.Customer = &Customer
	|		and Restrictions.Company = &Company
	|		order by Restrictions.Date desc
	|		) as Restrictions" );
	if ( controlCredit ) then
		selection.Add ( "
		|union all
		|select case when Rates.Rate is null then Debts.Debt else Debts.Debt * Rates.Rate / Rates.Factor end,
		|	0, 0, 0, 0, 0
		|from Debts as Debts
		|	//
		|	// Rates
		|	//
		|	left join Rates as Rates
		|	on Rates.Currency = Debts.Currency
		|union all
		|select 0, Credits.Amount, Credits.NoLimit, 0, 0, 0
		|from (
		|	select top 1 Credits.Amount as Amount, case when Credits.Disable then 1 else 0 end as NoLimit
		|	from Document.CreditLimit as Credits
		|	where not Credits.DeletionMark
		|	and Credits.Customer = &Customer
		|	and Credits.Company = &Company
		|	order by Credits.Date desc
		|	) as Credits" );
	endif;
	if ( controlContracts ) then
		selection.Add ( "
		|	union all
		|	select 0, 0, 0, 0, 1, 0
		|	from Catalog.Contracts as Contracts
		|	where not Contracts.DeletionMark
		|	and Contracts.Ref = &Contract
		|	and Contracts.Company = &Company
		|	and Contracts.Signed
		|	and &Today between Contracts.DateStart
		|		and case Contracts.DateEnd when datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Contracts.DateEnd end
		|	union all
		|	select top 1 0, 0, 0, 0, 1, 0
		|	from Catalog.Contracts as Contracts
		|	where not Contracts.DeletionMark
		|	and Contracts.Owner = &Customer
		|	and &Contract = value ( Catalog.Contracts.EmptyRef )
		|	and Contracts.Company = &Company
		|	and Contracts.Signed
		|	and &Today between Contracts.DateStart
		|		and case Contracts.DateEnd when datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Contracts.DateEnd end
		|	union all
		|	select top 1 0, 0, 0, 0, 0, 1
		|	from Document.Invoice as Invoices
		|	where Invoices.Ref <> &Ref
		|	and Invoices.Customer = &Customer
		|	and Invoices.Posted" );
	endif;
	selection.Add ( " ) as Debts" );
	if ( controlTaxInvoices ) then
		selection.Add ( "
		|;
		|// @InvoiceOnHand
		|select top 1 Documents.Ref as Invoice, datediff ( Documents.Date, &Today, day ) as Days
		|from Document.InvoiceRecord as Documents
		|	//
		|	// Days
		|	//
		|	join (
		|		select top 1 Returns.Days as Days
		|		from Document.InvoicesReturn as Returns
		|		where not Returns.DeletionMark
		|		and Returns.Customer = &Customer
		|		and Returns.Company = &Company
		|		order by Returns.Date desc
		|	) as ReturnsDay
		|	on ReturnsDay.Days <= datediff ( Documents.Date, &Today, day )
		|where not Documents.DeletionMark
		|and Documents.Customer = &Customer
		|and Documents.Company = &Company
		|and Documents.Status in (
		|	value ( Enum.FormStatuses.Printed ),
		|	value ( Enum.FormStatuses.Submitted )
		|)
		|order by Documents.Date desc" );
	endif;
	q = new Query ( StrConcat ( selection ) );
	q.SetParameter ( "Customer", Context.Customer );
	q.SetParameter ( "Company", Context.Company );
	q.SetParameter ( "Contract", Context.Contract );
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Currency", Context.Currency );
	q.SetParameter ( "Amount", Context.Amount );
	q.SetParameter ( "Today", Context.Today );
	return SQL.Exec ( q );

EndFunction

Function customerBanned ( Data )
	
	return Data.Sales.Ban;
		
EndFunction

Function contractRequired ( Data )
	
	return Data.ControlContracts
		and Data.Sales.Debt > 0
		and not Data.Sales.FirstSale
		and not Data.Sales.Signed;
		
EndFunction

Function creditExceeded ( Data )
		
	return Data.ControlCredit
		and ( not Data.Sales.NoLimit
			and Data.Sales.Limit < 0
		);
		
EndFunction

Function invoiceRequired ( Data )
	
	return Data.ControlTaxInvoices
		and Data.InvoiceOnHand <> undefined;
		
EndFunction

Procedure displaySales ( Form, Data, Restriction, Subject, Position )
	
	if ( permissionIssued ( Form, Data, Restriction, Position ) ) then
		return;
	endif;
	parts = new Array ();
	request = requestStatus ( Data, Restriction );
	if ( request = undefined ) then
		parts.Add ( Subject );
		parts.Add ( ". " );
		parts.Add ( authorize ( Form, Restriction ) );
		parts.Add ( " | " );
		parts.Add ( refresh ( Form ) );
		picture = PictureLib.Warning16;
	else
		parts.Add ( Subject );
		parts.Add ( ". " );
		parts.Add ( wait ( request ) );
		parts.Add ( " | " );
		parts.Add ( refresh ( Form ) );
		picture = PictureLib.Time16;
	endif;
	items = Form.Items;
	items [ "RestrictionPicture" + Position ].Picture = picture;
	items [ "RestrictionLabel" + Position ].Title = new FormattedString ( parts );
	items [ "RestrictionGroup" + Position ].Visible = true;

EndProcedure

Function permissionIssued ( Form, Data, Permission, Position )
	
	request = requestStatus ( Data, Permission );
	if ( request = undefined ) then
		return false;
	endif;
	parts = new Array ();
	resolution = request.Resolution;
	if ( resolution = Enums.AllowDeny.Deny ) then
		parts.Add ( permissionUrl ( Output.RestrictionRequestDenied ( request ), request ) );
		picture = PictureLib.Forbidden;
	elsif ( resolution = Enums.AllowDeny.Allow
		and request.Reason = Permission ) then 
		if ( Data.Amount > request.Amount
			or Data.Currency <> request.Currency ) then
			parts.Add ( Output.RestrictionRequestAmountExceeded () );
			parts.Add ( ". " );
			parts.Add ( authorize ( Form, Permission ) );
			picture = PictureLib.Warning16;
		else
			parts.Add ( permissionUrl ( Output.RestrictionRequestApproved ( request ), request ) );
			picture = PictureLib.Ok16;
		endif;
		parts.Add ( " | " );
		parts.Add ( refresh ( Form ) );
	else
		return false;
	endif;
	items = Form.Items;
	items [ "RestrictionPicture" + Position ].Picture = picture;
	items [ "RestrictionLabel" + Position ].Title = new FormattedString ( parts );
	items [ "RestrictionGroup" + Position ].Visible = true;
	return true;

EndFunction

Function requestStatus ( Data, Reason )
	
	row = Data.Approved.Find ( Reason, "Reason" );
	if ( row = undefined ) then
		return undefined;
	endif;
	result = new Structure ( "Reason, Resolution, Permission, Amount, Currency" );
	FillPropertyValues ( result, row );
	return result;

EndFunction

Function authorize ( Form, Reason )

	p = new Structure ( "Reason, Form", Reason, Form.UUID );
	if ( Reason = Enums.RestrictionReasons.PeriodClosed ) then
		command = GetUrl ( Metadata.CommonCommands.AuthorizeChanges, , " ", p );
	else
		command = GetUrl ( Metadata.CommonCommands.AuthorizeSales, , " ", p );
	endif;
	return new FormattedString ( Output.RestrictionSendRequest (), , , , command );

EndFunction

Function wait ( Request )
	
	link = GetUrl ( Request.Permission );
	return new FormattedString ( Output.RequestAlreadySent (), , , , link );

EndFunction

Function refresh ( Form )
	
	p = new Structure ( "Form", Form.UUID );
	command = GetUrl ( Metadata.CommonCommands.UpdateSalesRestriction, , " ", p );
	return new FormattedString ( Output.ClickToUpdate (), , , , command );

EndFunction

Function permissionUrl ( Text, Request )
	
	link = GetUrl ( Request.Permission );
	return new FormattedString ( Text, , , , link );

EndFunction

Procedure displayLimit ( Form, Data, Position )
	
	parts = new Array ();
	info = Data.Sales;
	if ( info.NoLimit ) then
		subject = Output.RestrictionNoCreditLimit ();
	else
		amount = info.Limit;
		if ( amount = 0 ) then
			subject = Output.RestrictionZeroCredit ();
		else
			p = new Structure ( "Amount", Conversion.NumberToMoney ( amount ) );
			subject = Output.RestrictionCreditLimit ( p );
		endif;
	endif;
	parts.Add ( subject );
	parts.Add ( ". " );
	parts.Add ( refresh ( Form ) );
	items = Form.Items;
	items [ "RestrictionPicture" + Position ].Picture = PictureLib.Info;
	items [ "RestrictionLabel" + Position ].Title = new FormattedString ( parts );
	items [ "RestrictionGroup" + Position ].Visible = true;

EndProcedure

Function CheckSales ( Object ) export
	
	data = getSalesData ( Object );
	if ( data = undefined ) then
		return true;
	endif;
	errors = new Array ();
	if ( customerBanned ( data ) ) then
		error = getSalesError ( data, Enums.RestrictionReasons.SaleBanned, Output.RestrictionSalesBanned () );
		errors.Add ( error );
	endif;
	if ( contractRequired ( data ) ) then
		error = getSalesError ( data, Enums.RestrictionReasons.NoContract, Output.RestrictionNoContract () );
		errors.Add ( error );
	endif;
	if ( creditExceeded ( data ) ) then
		p = new Structure ( "Amount", Conversion.NumberToMoney ( - data.Sales.Limit ) );
		subject = Output.RestrictionCreditExceeded ( p );
		error = getSalesError ( data, Enums.RestrictionReasons.CreditLimit, subject );
		errors.Add ( error );
	endif;
	if ( invoiceRequired ( data ) ) then
		p = new Structure ( "Invoice", data.InvoiceOnHand.Invoice );
		subject = Output.RestrictionInvoiceRequired ( p );
		error = getSalesError ( data, Enums.RestrictionReasons.NoInvoice, subject );
		errors.Add ( error );
	endif;
	ok = true;
	Collections.Group ( errors );
	for each error in errors do
		if ( error <> undefined ) then
			Output.PutMessage ( error, , , Object.Ref );
			ok = false;
		endif;
	enddo;
	return ok;

EndFunction

Function getSalesError ( Data, Restriction, Subject )
	
	parts = new Array ();
	request = requestStatus ( Data, Restriction );
	if ( request = undefined ) then
		parts.Add ( Subject );
	else
		resolution = request.Resolution; 
		if ( resolution.IsEmpty () ) then
			parts.Add ( Subject );
			parts.Add ( ". " );
			parts.Add ( Output.RequestAlreadySent () );
		elsif ( resolution = Enums.AllowDeny.Allow ) then
			if ( Data.Amount > request.Amount
				or Data.Currency <> request.Currency ) then
				parts.Add ( Output.RestrictionRequestAmountExceeded () );
			endif;
		elsif ( resolution = Enums.AllowDeny.Deny ) then
			parts.Add ( Output.RestrictionRequestDenied ( request ) );
		endif;
	endif;
	return ? ( parts.Count () = 0, undefined, StrConcat ( parts ) );

EndFunction

Function CanApprove () export
	
	return Logins.Admin ()
		or IsInRole ( Metadata.Roles.ApproveSales );

EndFunction

Function CanAllow () export
	
	return Logins.Admin ()
		or IsInRole ( Metadata.Roles.RightsEdit );

EndFunction

Procedure ShowAccess ( Form ) export
	
	date = objectDate ( Form );
	if ( date = Date ( 1, 1, 1 ) ) then
		return;
	endif;
	data = getAccessData ( Form.Object.Ref, date );
	access = data.Access;
	if ( access.Allowed ) then
		hideAccessRestrictions ( Form );
	else
		subject = accessMessage ( data );
		displayAccess ( Form, data, subject );
	endif;
	
EndProcedure

Function objectDate ( Form )	
	
	object = Form.Object;
	objectDate = object.Date;
	if ( objectDate = Date ( 1, 1, 1 ) ) then
		if ( object.Ref.IsEmpty () ) then
			objectDate = CurrentSessionDate ();
		endif;
	endif;
	return objectDate;
	
EndFunction

Procedure hideAccessRestrictions ( Form )
	
	Form.Items.AccessGroup.Visible = false;
	
EndProcedure

Function accessMessage ( Data )
	
	action = Data.Access.Action;
	warning = Data.Access.Warning;
	p = new Structure ( "User, Action", SessionParameters.User, action );
	if ( action = undefined ) then
		return Output.RightsUndefined ( p );
	elsif ( action = Enums.AccessRights.Any ) then
		if ( warning ) then
			return Output.AnyModificationIsNotRecommended ( p );
		else
			return Output.AnyModificationIsNotAllowed ( p );
		endif;
	else
		if ( warning ) then
			return Output.ModificationIsNotRecommended ( p );
		else
			return Output.ModificationIsNotAllowed ( p );
		endif;
	endif; 

EndFunction

Procedure displayAccess ( Form, Data, Subject )
	
	parts = new Array ();
	restriction = Enums.RestrictionReasons.PeriodClosed;
	request = requestStatus ( Data, restriction );
	if ( request = undefined ) then
		parts.Add ( Subject );
		parts.Add ( ". " );
		parts.Add ( authorize ( Form, restriction ) );
		picture = PictureLib.Warning16;
	else
		resolution = request.Resolution; 
		if ( resolution.IsEmpty () ) then
			parts.Add ( Subject );
			parts.Add ( ". " );
			parts.Add ( wait ( request ) );
			picture = PictureLib.Time16;
		elsif ( resolution = Enums.AllowDeny.Allow ) then
			parts.Add ( permissionUrl ( Output.RestrictionRequestApproved ( request ), request ) );
			picture = PictureLib.Ok16;
		elsif ( resolution = Enums.AllowDeny.Deny ) then
			parts.Add ( Subject );
			parts.Add ( ". " );
			parts.Add ( permissionUrl ( Output.RestrictionRequestDenied ( request ), request ) );
			picture = PictureLib.Forbidden;
		endif;
	endif;
	items = Form.Items;
	items [ "AccessPicture" ].Picture = picture;
	items [ "AccessLabel" ].Title = new FormattedString ( parts );
	items [ "AccessGroup" ].Visible = true;

EndProcedure

Function getAccessData ( Ref, Date )
	
	rights = getAccessInfo ( Ref, Date );
	map = rights.Map;
	access = new Structure ( "Allowed, Action, Warning", false, undefined, false );
	if ( Ref.IsEmpty () ) then
		//@skip-check module-unused-local-variable
		stub = accessDenied ( map, Enums.AccessRights.Create, access )
		or accessDenied ( map, Enums.AccessRights.Any, access )
		or accessAllowed ( map, Enums.AccessRights.Create, access )
		or accessAllowed ( map, Enums.AccessRights.Any, access );
	else
		stub = accessDenied ( map, Enums.AccessRights.Edit, access )
		or accessDenied ( map, Enums.AccessRights.UndoPosting, access )
		or accessDenied ( map, Enums.AccessRights.Any, access )
		or accessAllowed ( map, Enums.AccessRights.Edit, access )
		or accessAllowed ( map, Enums.AccessRights.UndoPosting, access )
		or accessAllowed ( map, Enums.AccessRights.Any, access );
		if ( access.Allowed ) then
			oldDate = DF.Pick ( Ref, "Date" );
			if ( BegOfDay ( Date ) <> BegOfDay ( oldDate ) ) then
				return getAccessData ( Ref, oldDate );
			endif;
		endif;
	endif;
	return new Structure ( "Approved, Access", rights.Approved, access );
	
EndFunction

Function getAccessInfo ( Ref, Date )
	
	s = "
	|// #Approved
	|select Restrictions.Ref as Permission, value ( Enum.RestrictionReasons.PeriodClosed ) as Reason,
	|	case
	|		when Restrictions.Resolution = value ( Enum.AllowDeny.Allow ) then
	|			case when &Today between Restrictions.Date and Restrictions.Expired
	|				then value ( Enum.AllowDeny.Allow )
	|				else value ( Enum.AllowDeny.EmptyRef )
	|			end
	|		else Restrictions.Resolution
	|	end as Resolution
	|from (
	|	select Restrictions.Ref as Ref, Restrictions.Resolution as Resolution,
	|		Restrictions.Date as Date, Restrictions.Expired as Expired
	|	from Document.ChangesPermission as Restrictions
	|	where Restrictions.Document = &Ref
	|	and Restrictions.Day = &DocumentDay
	|	and not Restrictions.DeletionMark
	|	union all
	|	select Restrictions.Ref, Restrictions.Resolution, Restrictions.Date, Restrictions.Expired
	|	from Document.ChangesPermission as Restrictions
	|	where Restrictions.Document = undefined
	|	and Restrictions.Class = &Document
	|	and Restrictions.Day = &DocumentDay
	|	and Restrictions.Creator = &User
	|	and not Restrictions.DeletionMark
	|	) as Restrictions
	|;
	|select undefined as User
	|into UserAndGroups
	|union
	|select &User
	|union
	|select Users.Membership
	|from InformationRegister.Membership as Users
	|where Users.User = &User
	|and not Users.Membership.DeletionMark
	|;
	|// #Access
	|select Rights.Access as Access, Rights.Action as Action, Rights.Warning as Warning,
	|	case when Rights.Target = undefined then 0
	|			+ case when Rights.Document <> value ( Catalog.Metadata.EmptyRef ) then 5 else 0 end
	|			+ case when Rights.Access = value ( Enum.AllowDeny.Deny ) then 1000 else 0 end
	|		when Rights.Target refs Catalog.Membership then 10
	|			+ case when Rights.Document <> value ( Catalog.Metadata.EmptyRef ) then 5 else 0 end
	|			+ case when Rights.Access = value ( Enum.AllowDeny.Deny ) then 1000 else 0 end
	|		else 100
	|			+ case when Rights.Document <> value ( Catalog.Metadata.EmptyRef ) then 5 else 0 end
	|			+ case when Rights.Access = value ( Enum.AllowDeny.Deny ) then 1000 else 0 end
	|	end as Weight
	|from InformationRegister.Rights as Rights
	|where not Rights.Disabled
	|and Rights.Target in ( select User from UserAndGroups )
	|and Rights.Document in ( value ( Catalog.Metadata.EmptyRef ), &Document )
	|and (
	|	( Rights.Method = value ( Enum.RestrictionMethods.Period )
	|		and &DocumentDate between Rights.DateStart
	|			and ( case Rights.DateEnd when datetime ( 1, 1, 1 ) then datetime ( 3999, 1, 1 ) else Rights.DateEnd end ) )
	|	or
	|	( Rights.Method = value ( Enum.RestrictionMethods.Span )
	|		and Rights.Access = value ( Enum.AllowDeny.Allow )
	|		and &DocumentDate between dateadd ( &Today, day, - Rights.Duration ) and dateadd ( &Today, day, Rights.Duration ) )
	|	or
	|	( Rights.Method = value ( Enum.RestrictionMethods.Span )
	|		and Rights.Access = value ( Enum.AllowDeny.Deny )
	|		and &DocumentDate not between dateadd ( &Today, day, - Rights.Duration ) and dateadd ( &Today, day, Rights.Duration ) )
	|	or
	|	( Rights.Method = value ( Enum.RestrictionMethods.Duration )
	|		and Rights.Access = value ( Enum.AllowDeny.Deny )
	|		and datediff ( &DocumentDate, &Today, day ) >= Rights.Duration )
	|	or
	|	( Rights.Method = value ( Enum.RestrictionMethods.Duration )
	|		and Rights.Access = value ( Enum.AllowDeny.Allow )
	|		and datediff ( &DocumentDate, &Today, day ) <= Rights.Duration )
	|	or
	|		Rights.Method = value ( Enum.RestrictionMethods.EmptyRef )
	|	)
	|and ( &Today < Rights.Expiration or Rights.Expiration = datetime ( 1, 1, 1 ) )
	|order by Weight desc
	|";
	q = new Query ( s );
	q.TempTablesManager = new TempTablesManager ();
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Document", MetadataRef.Get ( Metadata.FindByType ( TypeOf ( Ref ) ).FullName () ) );
	q.SetParameter ( "DocumentDate", Date );
	q.SetParameter ( "DocumentDay", BegOfDay ( Date ) );
	q.SetParameter ( "Today", CurrentSessionDate () );
	data = SQL.Exec ( q );
	result = new Structure ( "Approved, Map", data.Approved, accessMap ( data.Access ) );
	FillPropertyValues ( result, data );
	return result;
	
EndFunction 

Function accessMap ( Table )
	
	map = new Map ();
	for each row in Table do
		if ( map [ row.Action ] = undefined ) then
			map [ row.Action ] = new Structure ( "Access, Warning", row.Access, row.Warning );
		endif; 
	enddo; 
	return map;
	
EndFunction 

Function accessDenied ( Rights, Action, Result )
	
	record = Rights [ Action ];
	if ( record <> undefined
		and record.Access = Enums.AllowDeny.Deny ) then
		Result.Allowed = false;
		Result.Action = Action;
		Result.Warning = record.Warning;
		return true;
	endif;
	return false;
	
EndFunction

Function accessAllowed ( Rights, Action, Result )
	
	record = Rights [ Action ];
	if ( record <> undefined
		and record.Access = Enums.AllowDeny.Allow ) then
		Result.Allowed = true;
		Result.Action = Action;
		return true;
	endif;
	return false;
	
EndFunction

Function CheckAccess ( Object ) export
	
	data = getAccessData ( Object.Ref, Object.Date );
	access = data.Access;
	if ( access.Allowed or access.Warning ) then
		return true;
	endif;
	request = requestStatus ( Data, Enums.RestrictionReasons.PeriodClosed );
	if ( request <> undefined
		and request.Resolution = Enums.AllowDeny.Allow ) then
		return true;
	endif;
	error = new Array ();
	subject = accessMessage ( data );
	if ( request = undefined ) then
		error.Add ( subject );
	else
		resolution = request.Resolution; 
		error.Add ( subject );
		error.Add ( ". " );
		if ( resolution.IsEmpty () ) then
			error.Add ( Output.RequestAlreadySent () );
		else
			error.Add ( Output.RestrictionRequestDenied ( request ) );
		endif;
	endif;
	Output.PutMessage ( StrConcat ( error ), , , Object.Ref );
	return false;

EndFunction
