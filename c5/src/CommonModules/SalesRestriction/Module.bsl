
Procedure Show ( Form ) export
	
	data = getData ( Form.Object );
	if ( data = undefined ) then
		return;
	endif;
	hideAll ( Form );
	position = 1;
	if ( customerBanned ( data ) ) then
		subject = Output.RestrictionSalesBanned ();
		highlight ( Form, data, Enums.RestrictionReasons.SaleBanned, subject, position );
		position = position + 1;
	endif;
	if ( contractRequired ( data ) ) then
		subject = Output.RestrictionNoContract ();
		highlight ( Form, data, Enums.RestrictionReasons.NoContract, subject, position );
		position = position + 1;
	endif;
	if ( creditExceeded ( data ) ) then
		p = new Structure ( "Amount", Conversion.NumberToMoney ( data.Sales.Debt - data.Sales.Limit ) );
		subject = Output.RestrictionCreditExceeded ( p );
		highlight ( Form, data, Enums.RestrictionReasons.CreditLimit, subject, position );
		position = position + 1;
	endif;
	if ( invoiceRequired ( data ) ) then
		p = new Structure ( "Invoice", data.InvoiceOnHand.Invoice );
		subject = Output.RestrictionInvoiceRequired ( p );
		highlight ( Form, data, Enums.RestrictionReasons.NoInvoice, subject, position );
		position = position + 1;
	endif;

EndProcedure

Procedure hideAll ( Form )
	
	for each item in Form.Items.Restrictions.ChildItems do
		if ( StrStartsWith ( item.Name, "RestrictionGroup" ) ) then
			item.Visible = false;
		endif;
	enddo;

EndProcedure

Function getData ( Object )

	ref = Object.Ref;
	contract = ? ( TypeOf ( ref ) = Type ( "DocumentRef.Invoice" ),
		Object.Contract, Catalogs.Contracts.EmptyRef () );
	return getInfo ( Object.Customer, Object.Company, contract, ref );

EndFunction

Function getInfo ( Customer, Company, Contract, Document )
	
	if ( Customer.IsEmpty ()
		or Company.IsEmpty () ) then
		return undefined;
	endif;
	controlCredit = Options.ControlCredit ();
	controlContracts = Options.ControlContracts ();
	controlReturn = Options.ControlTaxInvoices ();
	control = controlCredit or controlContracts or controlReturn;
	if ( not control ) then
		return undefined;
	endif;
	selection = new Array ();
	selection.Add ( "
	|// #Approved
	|select Restrictions.Reason as Reason, Restrictions.Ref as Permission,
	|	case
	|		when Restrictions.Ref.Resolution = value ( Enum.AllowDeny.Allow ) then
	|			case when &Today between Restrictions.Ref.Date and Restrictions.Ref.Expired
	|				then value ( Enum.AllowDeny.Allow )
	|				else value ( Enum.AllowDeny.EmptyRef )
	|			end
	|		else Restrictions.Ref.Resolution
	|	end as Resolution
	|from Document.Permission.Restrictions as Restrictions
	|where Restrictions.Ref.Document = &Ref
	|and Restrictions.Ref.Customer = &Customer
	|and not Restrictions.Ref.DeletionMark" );
	if ( controlCredit or controlContracts ) then
		selection.Add ( "
		|;
		|// Debts
		|select Debts.Contract.Currency as Currency, Debts.AmountBalance as Debt
		|into Debts
		|from AccumulationRegister.Debts.Balance ( , Contract.Owner = &Customer ) as Debts
		|where Debts.AmountBalance > 0
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
	|select sum ( Debts.Debt ) as Debt, max ( Debts.Limit ) as Limit,
	|	1 = max ( Debts.Ban ) as Ban, 1 = max ( Debts.Signed ) as Signed
	|from (
	|	select 0 as Debt, 0 as Limit, 0 as Ban, 0 as Signed
	|	union all
	|	select 0, 0, case when Restrictions.Ban then 1 else 0 end, 0
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
		|select case when Rates.Rate is null then Debts.Debt else Debts.Debt * Rates.Rate / Rates.Factor end, 0, 0, 0
		|	from Debts as Debts
		|		//
		|		// Rates
		|		//
		|		left join Rates as Rates
		|		on Rates.Currency = Debts.Currency
		|	union all
		|	select 0, Credits.Amount, 0, 0
		|	from (
		|		select top 1 Credits.Amount as Amount
		|		from Document.CreditLimit as Credits
		|		where not Credits.DeletionMark
		|		and Credits.Customer = &Customer
		|		and Credits.Company = &Company
		|		order by Credits.Date desc
		|		) as Credits" );
	endif;
	if ( controlContracts ) then
		selection.Add ( "
		|	union all
		|	select 0, 0, 0, 1
		|	from Catalog.Contracts as Contracts
		|	where not Contracts.DeletionMark
		|	and Contracts.Ref = &Contract
		|	and Contracts.Company = &Company
		|	and Contracts.Signed
		|	and &Today between Contracts.DateStart
		|		and case Contracts.DateEnd when datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Contracts.DateEnd end
		|	union all
		|	select top 1 0, 0, 0, 1
		|	from Catalog.Contracts as Contracts
		|	where not Contracts.DeletionMark
		|	and Contracts.Owner = &Customer
		|	and &Contract = value ( Catalog.Contracts.EmptyRef )
		|	and Contracts.Company = &Company
		|	and Contracts.Signed
		|	and &Today between Contracts.DateStart
		|		and case Contracts.DateEnd when datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Contracts.DateEnd end" );
	endif;
	selection.Add ( " ) as Debts" );
	if ( controlReturn ) then
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
	q.SetParameter ( "Customer", Customer );
	q.SetParameter ( "Company", Company );
	q.SetParameter ( "Contract", Contract );
	q.SetParameter ( "Ref", Document );
	q.SetParameter ( "Today", CurrentSessionDate () );
	data = SQL.Exec ( q, false );
	result = new Structure ( "ControlContracts, ControlCredit, ControlReturn, Sales, InvoiceOnHand, Approved" );
	FillPropertyValues ( result, data );
	result.ControlContracts = controlContracts;
	result.ControlCredit = controlCredit;
	result.ControlReturn = controlReturn;
	return result;

EndFunction

Function customerBanned ( Data )
	
	return Data.Sales.Ban;
		
EndFunction

Function contractRequired ( Data )
	
	return Data.ControlContracts
		and Data.Sales.Debt > 0
		and not Data.Sales.Signed;
		
EndFunction

Function creditExceeded ( Data )
	
	return Data.ControlCredit
		and Data.Sales.Debt > Data.Sales.Limit;
		
EndFunction

Function invoiceRequired ( Data )
	
	return Data.ControlReturn
		and Data.InvoiceOnHand <> undefined;
		
EndFunction

Procedure highlight ( Form, Data, Restriction, Subject, Position )
	
	parts = new Array ();
	request = requestStatus ( Data, Restriction );
	if ( request = undefined ) then
		parts.Add ( Subject );
		parts.Add ( ". " );
		parts.Add ( authorize ( Form, Restriction ) );
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
			parts.Add ( permissionUrl ( Output.RestrictionRequestDenied ( request ), request ) );
			picture = PictureLib.Forbidden;
		endif;
	endif;
	items = Form.Items;
	items [ "RestrictionPicture" + Position ].Picture = picture;
	items [ "RestrictionLabel" + Position ].Title = new FormattedString ( parts );
	items [ "RestrictionGroup" + Position ].Visible = true;

EndProcedure

Function requestStatus ( Data, Reason )
	
	row = Data.Approved.Find ( Reason, "Reason" );
	if ( row = undefined ) then
		return undefined;
	else
		result = new Structure ( "Reason, Resolution, Permission" );
		FillPropertyValues ( result, row );
		return result;
	endif;

EndFunction

Function authorize ( Form, Reason )

	p = new Structure ( "Reason, Form", Reason, Form.UUID );
	command = GetUrl ( Metadata.CommonCommands.Authorize, , " ", p );
	return new FormattedString ( Output.RestrictionSendRequest (), , , , command );

EndFunction

Function wait ( Request )
	
	link = GetUrl ( Request.Permission );
	return new FormattedString ( Output.RequestAlreadySent (), , , , link );

EndFunction

Function permissionUrl ( Text, Request )
	
	link = GetUrl ( Request.Permission );
	return new FormattedString ( Text, , , , link );

EndFunction

Function Check ( Object ) export
	
	data = getData ( Object );
	if ( data = undefined ) then
		return true;
	endif;
	errors = new Array ();
	if ( customerBanned ( data ) ) then
		error = getError ( data, Enums.RestrictionReasons.SaleBanned, Output.RestrictionSalesBanned () );
		errors.Add ( error );
	endif;
	if ( contractRequired ( data ) ) then
		error = getError ( data, Enums.RestrictionReasons.NoContract, Output.RestrictionNoContract () );
		errors.Add ( error );
	endif;
	if ( creditExceeded ( data ) ) then
		p = new Structure ( "Amount", Conversion.NumberToMoney ( data.Sales.Debt - data.Sales.Limit ) );
		subject = Output.RestrictionCreditExceeded ( p );
		error = getError ( data, Enums.RestrictionReasons.CreditLimit, subject );
		errors.Add ( error );
	endif;
	if ( invoiceRequired ( data ) ) then
		p = new Structure ( "Invoice", data.InvoiceOnHand.Invoice );
		subject = Output.RestrictionInvoiceRequired ( p );
		error = getError ( data, Enums.RestrictionReasons.NoInvoice, subject );
		errors.Add ( error );
	endif;
	ok = true;
	for each error in errors do
		if ( error <> undefined ) then
			Output.PutMessage ( error, , , Object.Ref );
			ok = false;
		endif;
	enddo;
	return ok;

EndFunction

Function getError ( Data, Restriction, Subject )
	
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
