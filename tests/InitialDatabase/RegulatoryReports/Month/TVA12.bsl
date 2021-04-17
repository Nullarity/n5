Procedure Make ()

	commonVatFields = "
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end as VAT, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end as Amount, 
	|	Table.VATCode.Rate as Rate, Table.VATCode.Type as Type, case when Table.Ref.VATUse = 0 or Table.VATCode.Type = value ( Enum.VAT.None ) then false else true end as VATUse
	|";
	invoiceRecordsFields = commonVatFields + ", Table.Ref.Series as Series, Table.Ref.FormNumber as Number";
	vendorInvoiceFields = commonVatFields + ", Table.Ref.Series as Series, Table.Ref.Reference as Number, Table.Ref.ReferenceDate as Date";
	conditions = "
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|";
	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, Accountant.Name as Accountant, Accountant.HomePhone as HomePhone,
	|	Director.Name as Director, Accountant.Email as Email, Companies.VATCode as VATCode, Addresses.Presentation as Address
	|from Catalog.Companies as Companies
	|	//
	|	// Accountant
	|	//
	|	left join (
	|		select top 1 Roles.User.Employee.Individual.Description as Name, Roles.User.Employee.HomePhone as HomePhone, Roles.User.Employee.Email as Email
	|		from Document.Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.AccountantChief )
	|		and not Roles.DeletionMark
	|		and Roles.Action = value ( Enum.AssignRoles.Assign )
	|		and Roles.Company = &Company
	|		order by Roles.Date desc
	|		) as Accountant
	|	on true
	|	//
	|	// Director
	|	//
	|	left join (
	|		select top 1 Roles.User.Employee.Individual.Description as Name
	|		from Document.Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.GeneralManager )
	|		and not Roles.DeletionMark
	|		and Roles.Action = value ( Enum.AssignRoles.Assign )
	|		and Roles.Company = &Company
	|		order by Roles.Date desc
	|			) as Director
	|	on true
	|	//
	|	// Addresses
	|	//
	|	left join Catalog.Addresses as Addresses
	|	on Addresses.Owner = Companies.Ref
	|	and not Addresses.DeletionMark
	|where Companies.Ref = &Company
	|;
	|// VATS
	|" + invoiceRecordsFields + ", Table.Ref.DeliveryDate as Date, 0 as Operation, Table.Ref.Customer.CodeFiscal as CodeFiscal
	|into VATS
	|from Document.InvoiceRecord.Items as Table
	|" + conditions + "
	|union all
	|" + invoiceRecordsFields + ", Table.Ref.DeliveryDate as Date, 0, Table.Ref.Customer.CodeFiscal as CodeFiscal
	|from Document.InvoiceRecord.Services as Table
	|" + conditions + "
	|union all
	|" + vendorInvoiceFields + ", 1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.Accounts as Table
	|" + conditions + "
	|union all
	|" + vendorInvoiceFields + ", 1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.FixedAssets as Table
	|" + conditions + "
	|union all
	|" + vendorInvoiceFields + ", 1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.IntangibleAssets as Table
	|" + conditions + "
	|union all
	|" + vendorInvoiceFields + ", 1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.Items as Table
	|" + conditions + "
	|union all
	|" + vendorInvoiceFields + ", 1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.Services as Table
	|" + conditions + "
	|union all
	|select Charges.VAT, Charges.Amount + Groups.Base, Table.Charge.VAT.Rate, Table.Charge.VAT.Type, case when Table.Charge.VAT.Type = value ( Enum.VAT.None ) then false else true end,
	|	"""", """", """", 2, """"
	|from Document.CustomsDeclaration.Charges as Table
	|	//
	|	// Custom Groups
	|	//
	|	left join Document.CustomsDeclaration.CustomsGroups as Groups
	|	on Groups.Ref = Table.Ref
	|	and Groups.CustomsGroup = Table.CustomsGroup
	|	//
	|	// VAT
	|	//
	|	left join (
	|		select sum ( case when Table.VAT then Table.Amount else 0 end ) as VAT, sum ( case when Table.VAT then 0 else Table.Amount end ) as Amount, Table.Ref as Ref,
	|			Table.CustomsGroup as CustomsGroup
	|		from Document.CustomsDeclaration.Charges as Table
	|		" + conditions + "
	|		group by Table.Ref, Table.CustomsGroup
	|		) as Charges
	|	on Charges.Ref = Table.Ref
	|	and Charges.CustomsGroup = Table.CustomsGroup
	|" + conditions + "
	|and Table.VAT
	|union all
	|select Table.VAT, Table.Total - Table.VAT,	Table.VATCode.Rate, Table.VATCode.Type, case when Table.VATUse = 0 or Table.VATCode.Type = value ( Enum.VAT.None ) then false else true end, 
	|	Table.Series, Table.FormNumber, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.VATPurchases as Table
	|where not Table.Ref.DeletionMark
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|union all
	|select Table.VAT, Table.Total - Table.VAT,	Table.VATCode.Rate, Table.VATCode.Type, case when Table.VATUse = 0 or Table.VATCode.Type = value ( Enum.VAT.None ) then false else true end, 
	|	Table.Series, Table.FormNumber, Table.Date, 0, Table.Customer.CodeFiscal
	|from Document.VATSales as Table
	|where not Table.Ref.DeletionMark
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end, 
	|	Table.VATCode.Rate, Table.VATCode.Type, case when Table.Ref.VATUse = 0 or Table.VATCode.Type = value ( Enum.VAT.None ) then false else true end,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.Items as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end, 
	|	Table.VATCode.Rate, Table.VATCode.Type, case when Table.Ref.VATUse = 0 or Table.VATCode.Type = value ( Enum.VAT.None ) then false else true end,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.Services as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end, 
	|	Table.VATCode.Rate, Table.VATCode.Type, case when Table.Ref.VATUse = 0 or Table.VATCode.Type = value ( Enum.VAT.None ) then false else true end,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.FixedAssets as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end, 
	|	Table.VATCode.Rate, Table.VATCode.Type, case when Table.Ref.VATUse = 0 or Table.VATCode.Type = value ( Enum.VAT.None ) then false else true end,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.IntangibleAssets as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end, 
	|	Table.VATCode.Rate, Table.VATCode.Type, case when Table.Ref.VATUse = 0 or Table.VATCode.Type = value ( Enum.VAT.None ) then false else true end,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.Accounts as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|;
	|// #VATs
	|select sum ( VATs.Amount ), sum ( VATs.VAT ) as VAT, VATs.Rate as Rate, VATs.Type as Type, VATs.VATUse as VATUse, VATs.Operation as Operation,
	|	VATs.Series as Series, VATs.Number as Number, VATs.Date as Date, VATs.CodeFiscal as CodeFiscal
	|from VATs as VATs
	|group by VATs.Rate, VATs.Type, VATs.VATUse, VATs.Operation, VATs.Date, VATs.Number, VATs.Series, VATs.CodeFiscal
	|order by VATs.Date
	|;
	|// @Advances
	|select General.AmountTurnoverDr as Amount
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account.Code in hierarchy ( ""2252"" ), , Company = &Company, , ) as General
	|";
	Env.Selection.Add ( str );	
	Env.Q.SetParameter ( "Currency", Constants.Currency.Get () );
	getData ();

	area = getArea ();
	
	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;
	
	FieldsValues [ "Period" ] = "L/" + Format ( DateEnd, "DF='MM/yyyy'" );
	
	//*********** standard rate
	//*************************
	vats = Env.VATs;
	vat = Enums.VAT;
	table = vats.Copy ( new Structure ( "Type, Operation, VATUse", vat.Standart, 0, true ) );
	FieldsValues [ "A21" ] = table.Total ( "Amount" );
	FieldsValues [ "B21" ] = table.Total ( "VAT" );
	
	//************ reduced rate
	//*************************
	table = vats.Copy ( new Structure ( "Type, Operation, VATUse", vat.Reduced, 0, true ) );
	FieldsValues [ "A23" ] = table.Total ( "Amount" );
	FieldsValues [ "B23" ] = table.Total ( "VAT" );
	
	//******************** zero
	//*************************
	table = vats.Copy ( new Structure ( "Type, Operation, VATUse", vat.Zero, 0, true ) );
	FieldsValues [ "A24" ] = table.Total ( "Amount" );
	
	//****************** no VAT
	//*************************
	table = vats.Copy ( new Structure ( "VATUse, Operation", false, 0 ) );
	FieldsValues [ "A25" ] = table.Total ( "Amount" );
	
	//****************** Advances
	//*************************
	FieldsValues [ "B29" ] = Env.Advances.Amount;
	
	//****************** Receipt
	//*************************
	receipt = vats.Copy ( new Structure ( "VATUse, Operation", true, 1 ) );
	FieldsValues [ "A30" ] = receipt.Total ( "Amount" );
	FieldsValues [ "B30" ] = receipt.Total ( "VAT" );
	
	//****************** Import
	//*************************
	table = vats.Copy ( new Structure ( "VATUse, Operation", true, 2 ) );
	FieldsValues [ "A31" ] = table.Total ( "Amount" );
	FieldsValues [ "B31" ] = table.Total ( "VAT" );
	
	//****************** Annex1
	//*************************
	receipt.GroupBy ( "CodeFiscal, Date, Series, Number", "Amount, VAT" );
	i = 102;
	line = 1;
	for each row in receipt do
		if ( i > 137 ) then
	    	break;
	    endif;
		FieldsValues [ "A" + i ] = line;
	    FieldsValues [ "B" + i ] = row.CodeFiscal;
	    FieldsValues [ "C" + i ] = row.Date;
	    FieldsValues [ "D" + i ] = row.Series;	
	    FieldsValues [ "E" + i ] = row.Number;	
	    FieldsValues [ "F" + i ] = row.Amount;	
	    FieldsValues [ "G" + i ] = row.VAT;	
	    i = i + 1;
	    line = line + 1;
	enddo;
	FieldsValues [ "Rows1" ] = receipt.Count ();
	
	//****************** Annex2
	//*************************
	sale = vats.Copy ( new Structure ( "VATUse, Operation", true, 0 ) );
	sale.GroupBy ( "CodeFiscal, Date, Series, Number", "Amount, VAT" );
	i = 171;
	line = 1;
	for each row in sale do
		if ( i > 206 ) then
	    	break;
	    endif;
		FieldsValues [ "A" + i ] = line;
	    FieldsValues [ "B" + i ] = row.CodeFiscal;
	    FieldsValues [ "C" + i ] = row.Date;
	    FieldsValues [ "D" + i ] = row.Series;	
	    FieldsValues [ "E" + i ] = row.Number;	
	    FieldsValues [ "F" + i ] = row.Amount;	
	    FieldsValues [ "G" + i ] = row.VAT;	
	    i = i + 1;
	    line = line + 1;
	enddo;
	FieldsValues [ "Rows2" ] = sale.Count ();
	
	draw ();
	
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure

Procedure A28 ()

	result = get ( "A21" ) + sum ( "A23:A25" );

EndProcedure

Procedure B28 ()

	result = get ( "B21" ) + sum ( "B23:B25" );

EndProcedure

Procedure B34 ()

	result = sum ( "B30:B33" );

EndProcedure

Procedure B35 ()

	result = get ( "B28" ) - get ( "B34" );

EndProcedure

Procedure B37 ()

	result = get ( "B34" ) - get ( "B28" ) - get ( "B38" );

EndProcedure

Procedure F138 ()

	result = sum ( "F102:F137" );

EndProcedure

Procedure G138 ()

	result = sum ( "G102:G137" );

EndProcedure

Procedure F139 ()

	result = get ( "F138" );

EndProcedure

Procedure G139 ()

	result = get ( "G138" );

EndProcedure

Procedure F207 ()

	result = sum ( "F171:F206" );

EndProcedure

Procedure G207 ()

	result = sum ( "G171:G206" );

EndProcedure

Procedure F208 ()

	result = get ( "F207" );

EndProcedure

Procedure G208 ()

	result = get ( "G207" );

EndProcedure

