#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Print(Params, Env) export
	
	Print.SetFooter(Params.TabDoc);
	setPageSettings(Params);
	setContext(Params, Env);
	getData(Params, Env);
	putHeader(Params, Env);
	putTable(Params, Env);
	putTotals(Params, Env);
	putFooter(Params, Env);
	return true;
	
EndFunction

Procedure setPageSettings(Params)
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure

Procedure setContext(Params, Env)
	
	if (TypeOf(Params.Reference) = Type("DocumentRef.Quote")) then
		document = "Quote";
	else
		document = "SalesOrder";
	endif;
	Env.Insert("Document", document);
	
EndProcedure

Procedure getData(Params, Env)
	
	sqlFields(Env);
	getFields(Params, Env);
	defineAmount(Env);
	sqlItems(Env);
	getTables(Env);
	
EndProcedure

Procedure sqlFields(Env)
	
	s = "
		|select Documents.Number as Number, Documents.Company.FullDescription as Company, Documents.Company.CodeFiscal as CodeFiscal,
		|	Documents.Currency as Currency, Constants.Currency as LocalCurrency, Documents.Date as Date, Documents.Factor as Factor,
		|	Documents.Rate as Rate, Documents.Customer.FullDescription as Customer, Documents.Company.PaymentAddress.Presentation as Address,
		|	Documents.Company.BankAccount.AccountNumber as AccountNumber, Documents.Company.BankAccount.Bank.Description as Bank,
		|	Documents.Company.BankAccount.Bank.Code as BankCode, Documents.Company as CompanyRef, Documents.Company.Discounts as Discounts
		|into Documents
		|from Document." + Env.Document + " as Documents
		|	//
		|	// Constants
		|	//
		|	join Constants as Constants
		|	on true
		|where Documents.Ref = &Ref 
		|;
		|// Documents
		|select Roles.Ref as Ref, Roles.Role as Role
		|into DocumentsRoles
		|from Document.Roles as Roles
		|where not Roles.DeletionMark
		|and Roles.Action = value ( Enum.AssignRoles.Assign )
		|and Roles.Company in ( select CompanyRef from Documents )
		|and Roles.Role in ( value ( Enum.Roles.AccountantChief ), value ( Enum.Roles.GeneralManager ) )
		|;
		|// Roles
		|select Roles.User.Employee.Individual as Individual, Roles.Role as Role
		|into Roles
		|from Document.Roles as Roles
		|	//
		|	// Last changes
		|	//
		|	join (
		|		select Roles.Role as Role, max ( Roles.Date ) as Date
		|		from Document.Roles as Roles
		|		where Roles.Ref in ( select Ref from DocumentsRoles )
		|		group by Roles.Role
		|	) as LastChanges
		|	on LastChanges.Role = Roles.Role
		|	and LastChanges.Date = Roles.Date
		|where Roles.Ref in ( select Ref from DocumentsRoles )
		|;
		|// @Fields
		|select Documents.Number as Number, Documents.Company as Company, Documents.CodeFiscal as CodeFiscal, Documents.Discounts as Discounts,
		|	Documents.Currency as Currency, Documents.LocalCurrency as LocalCurrency, Documents.Date as Date, Documents.Factor as Factor,
		|	Documents.Rate as Rate, Documents.Customer as Customer, Documents.Address as Address, RolesDirector.Director as Director,
		|	Documents.AccountNumber as AccountNumber, Documents.Bank as Bank, RolesAccountant.Accountant as Accountant, 
		|	Documents.BankCode as BankCode, Documents.LocalCurrency.OptionsRu as OptionsRu, Documents.LocalCurrency.OptionsRo as OptionsRo
		|from Documents as Documents
		|	//
		|	// Accountant
		|	//
		|	left join ( 
		|		select Roles.Individual.Description as Accountant
		|		from Roles as Roles
		|		where Roles.Role = value ( Enum.Roles.AccountantChief )
		|		) as RolesAccountant
		|	on true
		|	//
		|	// Director
		|	//
		|	left join ( 
		|		select Roles.Individual.Description as Director
		|		from Roles as Roles
		|		where Roles.Role = value ( Enum.Roles.GeneralManager )
		|		) as RolesDirector
		|	on true
		
		|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure getFields(Params, Env)
	
	Env.Q.SetParameter("Ref", Params.Reference);
	SQL.Perform(Env);
	
EndProcedure

Procedure defineAmount(Env)
	
	list = new Structure();
	Env.Insert("AmountFields", list);
	fields = Env.Fields;
	total = "Total";
	vat = "VAT";
	discount = "Discount";
	price = "Price";
	if (fields.Currency <> fields.LocalCurrency) then
		rate = " * &Rate / &Factor";
		total = total + rate;
		vat = vat + rate;
		price = price + rate;
		discount = discount + rate;
	endif;
	list.Insert("Total", "cast ( " + total + " as Number ( 15, 2 ) )");
	list.Insert("VAT", "cast ( " + vat + " as Number ( 15, 2 ) )");
	list.Insert("Price", "cast ( " + price + " as Number ( 15, 2 ) )");
	list.Insert("Discount", "cast ( " + discount + " as Number ( 15, 2 ) )");
	
EndProcedure

Procedure sqlItems(Env)
	
	amountFields = Env.AmountFields;
	total = amountFields.Total;
	vat = amountFields.VAT;
	discount = amountFields.Discount;
	price = amountFields.Price;
	amount = total + " - " + vat;
	document = Env.Document;
	s = "
		|// Items
		|select presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Unit,
		|	case when Items.Item refs Catalog.Items and Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as Quantity,
		|	" + total + " as Total, " + vat + " as VAT, " + amount + " as Amount, " + discount + " as Discount, " + price + " as Price,
		|	Items.Feature.Description as Feature, Items.Item.FullDescription as Item
		|into Items
		|from Document." + document + ".Items as Items
		|where Items.Ref = &Ref 
		|union all
		|select Services.Item.Unit.Code, Services.Quantity, " + total + ", " + vat + ", " + amount + ", " + discount + ", " + price + ", 
		|	Services.Feature.Description, Services.Description
		|from Document." + document + ".Services as Services
		|where Services.Ref = &Ref 
		|;
		|// #Items
		|select Items.Unit as Unit, Items.Quantity as Quantity, Items.Total as Total, Items.VAT as VAT, Items.Amount as Amount, Items.Feature as Feature,
		|	Items.Price as Price, Items.Item as Item, Items.Discount as Discount
		|from Items as Items
		|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure getTables(Env)
	
	q = Env.Q;
	fields = Env.Fields;
	q.SetParameter("Rate", fields.Rate);
	q.SetParameter("Factor", fields.Factor);
	SQL.Perform(Env);
	
EndProcedure

Procedure putHeader(Params, Env)
	
	area = Env.T.GetArea("Header");
	p = area.Parameters;
	fields = Env.Fields;
	p.Fill(fields);
	p.Date = Format(fields.Date, "DLF=D");
	Params.TabDoc.Put(area);
	
EndProcedure

Procedure putTable(Params, Env)
	
	areas = getAreas(Env);
	tabDoc = Params.TabDoc;
	tabDoc.Put(areas.Header);
	area = areas.Area;
	p = area.Parameters;
	line = 0;
	accuracy = Application.Accuracy();
	for each row in Env.Items do
		line = line + 1;
		p.Fill(row);
		p.Line = line;
		p.Quantity = Format(row.Quantity, accuracy);
		tabDoc.Put(area);
	enddo;
	
EndProcedure

Function getAreas(Env)
	
	header = "Table";
	row = "Row";
	if (Options.Features()) then
		header = header + "Feature";
		row = row + "Feature";
	endif;
	if (Env.Fields.Discounts) then
		header = header + "Discount";
		row = row + "Discount";
	endif;
	t = Env.T;
	return new Structure("Header, Area", t.GetArea(header), t.GetArea(row));
	
EndFunction

Procedure putTotals(Params, Env)
	
	discounts = Env.Fields.Discounts;
	if (discounts) then
		areaName = "TotalsDiscount";
	else
		areaName = "Totals";
	endif;
	area = Env.T.GetArea(areaName);
	p = area.Parameters;
	items = Env.Items;
	p.Amount = items.Total("Amount");
	p.VAT = items.Total("VAT");
	p.Total = items.Total("Total");
	if (discounts) then
		p.Discount = items.Total("Discount");
	endif;
	Params.TabDoc.Put(area);
	
EndProcedure

Procedure putFooter(Params, Env)
	
	area = Env.T.GetArea("Footer");
	p = area.Parameters;
	fields = Env.Fields;
	p.Fill(fields);
	if (Params.Key = "BillRo") then
		format = "L=ro_RO; FS=false";
		numerationOptions = fields.OptionsRo;
	else
		format = "L=ru_RU; FS=false";
		numerationOptions = fields.OptionsRu;
	endif;
	p.TotalInWords = NumberInWords(Env.Items.Total("Total"), format, numerationOptions);
	Params.TabDoc.Put(area);
	
EndProcedure

#endif