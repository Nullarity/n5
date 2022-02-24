Procedure Make ()

	commonVatFields = "
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end as VAT, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end as Amount, 
	|	Table.VATCode.Rate as Rate, Table.VATCode.Type as Type, Table.Ref.VATUse <> 0 as VATUse
	|";
	invoiceRecordsFields = commonVatFields + ", Table.Ref.Series as Series, Table.Ref.FormNumber as Number";
	vendorInvoiceFields = commonVatFields + ", Table.Ref.Series as Series, Table.Ref.Reference as Number,
	|	case Table.Ref.ReferenceDate when datetime (1, 1, 1) then Table.Ref.Date else Table.Ref.ReferenceDate end as Date";
	conditions = "
	|where Table.Ref.Date between &DateStart and &DateEnd
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
	|and not Table.Ref.DeletionMark
	|and not Table.Ref.Base refs Document.Transfer
	|and not Table.Ref.Base refs Document.LVITransfer
	|and Table.Ref.Status in (
	|	value ( Enum.FormStatuses.Unloaded ),
	|	value ( Enum.FormStatuses.Printed ),
	|	value ( Enum.FormStatuses.Submitted )
	|)
	|union all
	|" + invoiceRecordsFields + ", Table.Ref.DeliveryDate as Date, 0, Table.Ref.Customer.CodeFiscal as CodeFiscal
	|from Document.InvoiceRecord.Services as Table
	|" + conditions + "
	|and not Table.Ref.DeletionMark
	|and not Table.Ref.Base refs Document.Transfer
	|and not Table.Ref.Base refs Document.LVITransfer
	|and Table.Ref.Status in (
	|	value ( Enum.FormStatuses.Unloaded ),
	|	value ( Enum.FormStatuses.Printed ),
	|	value ( Enum.FormStatuses.Submitted )
	|)
	|union all
	|" + vendorInvoiceFields + ", 1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.Accounts as Table
	|" + conditions + "
	|and Table.Ref.Posted
	|and not Table.Ref.Import
	|union all
	|" + vendorInvoiceFields + ", 1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.FixedAssets as Table
	|" + conditions + "
	|and Table.Ref.Posted
	|and not Table.Ref.Import
	|union all
	|" + vendorInvoiceFields + ", 1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.IntangibleAssets as Table
	|" + conditions + "
	|and Table.Ref.Posted
	|and not Table.Ref.Import
	|union all
	|" + vendorInvoiceFields + ", 1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.Items as Table
	|" + conditions + "
	|and Table.Ref.Posted
	|and not Table.Ref.Import
	|union all
	|" + vendorInvoiceFields + ", 1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.Services as Table
	|" + conditions + "
	|and Table.Ref.Posted
	|and not Table.Ref.Import
	|union all
	|select Charges.VAT, Charges.Amount + Groups.Base, Table.Charge.VAT.Rate, Table.Charge.VAT.Type, true,
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
	|		and Table.Ref.Posted
	|		group by Table.Ref, Table.CustomsGroup
	|		) as Charges
	|	on Charges.Ref = Table.Ref
	|	and Charges.CustomsGroup = Table.CustomsGroup
	|" + conditions + "
	|and Table.VAT
	|and Table.Ref.Posted
	|union all
	|select Table.VAT, Table.Total - Table.VAT,	Table.VATCode.Rate, Table.VATCode.Type, Table.VATUse <> 0,
	|	Table.Series, Table.FormNumber, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.VATPurchases as Table
	|where not Table.Ref.DeletionMark
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|union all
	|select Table.VAT, Table.Total - Table.VAT,	Table.VATCode.Rate, Table.VATCode.Type, Table.VATUse <> 0,
	|	Table.Series, Table.FormNumber, Table.Date, 0, Table.Customer.CodeFiscal
	|from Document.VATSales as Table
	|where not Table.Ref.DeletionMark
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end, 
	|	Table.VATCode.Rate, Table.VATCode.Type, Table.Ref.VATUse <> 0,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.Items as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end, 
	|	Table.VATCode.Rate, Table.VATCode.Type, Table.Ref.VATUse <> 0,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.Services as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end, 
	|	Table.VATCode.Rate, Table.VATCode.Type, Table.Ref.VATUse <> 0,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.FixedAssets as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end, 
	|	Table.VATCode.Rate, Table.VATCode.Type, Table.Ref.VATUse <> 0,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.IntangibleAssets as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor end, 
	|	Table.VATCode.Rate, Table.VATCode.Type, Table.Ref.VATUse <> 0,
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
	i = 100; // data index
	line = 1;
	pagesStart = T.Area ( "A1" ).Bottom + 1; // r-index
	pageSize = 54; // data rows per page
	nextPage = 200; // data index
	pagestep = 100; // data step (means no more then 100 data rows per page)
	pagesCount = 0;
	pageTableStarts = 5; // r-index from the top of the page (skip table header)
	for each row in receipt do
		FieldsValues [ "A" + i ] = line;
	    FieldsValues [ "B" + i ] = row.CodeFiscal;
	    FieldsValues [ "C" + i ] = row.Date;
		prefix = row.Series;
	    FieldsValues [ "D" + i ] = prefix;
	    FieldsValues [ "E" + i ] = StrReplace ( row.Number, prefix, "" );
	    FieldsValues [ "F" + i ] = row.Amount;	
	    FieldsValues [ "G" + i ] = row.VAT;	
	    line = line + 1;
		if ( i = 135 ) then
	    	i = nextPage;
			elsif ( i = ( nextPage + pageSize ) ) then
			nextPage = nextPage + pageStep;
			i = nextPage;
			newPage = T.GetArea ( "A1" );
			pageHeight = newPage.TableHeight;
			k = nextPage;
			for j = pageTableStarts to pageTableStarts + pageSize do
				id = Format(k, "NG=0");
				a = newPage.Area ( j, 2, j, 2 ); // c-index in the template
				name = "A" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 4, j, 4 );
				name = "B" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 12, j, 12 );
				name = "C" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 19, j, 19 );
				name = "D" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 24, j, 24 );
				name = "E" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 31, j, 31 );
				name = "F" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 39, j, 39 );
				name = "G" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				k = k + 1;
			enddo;
			a = newPage.Area ( j, 31, j, 31 );
			id = Format(k, "NG=0");
			name = "F" + id;
			a.Parameter = name;
			a.DetailsParameter = "_Detail_" + name;
			a = newPage.Area ( j, 39, j, 39 );
			name = "G" + id;
			a.Parameter = name;
			a.DetailsParameter = "_Detail_" + name;
			areaName = "R" + Format ( ( pagesStart + ( pageHeight * pagesCount ) ), "NG=0" );
			T.InsertArea ( newPage.Area (), T.Area ( areaName ), SpreadsheetDocumentShiftType.Vertical, false );
			pagesCount = pagesCount + 1;
		else
			i = i + 1;
		endif;
	enddo;
	FieldsValues [ "Rows1" ] = line - 1;
	
	// Remove unused attachment
	if ( i < 201 ) then
		T.DeleteArea ( T.Area ( "A1" ), SpreadsheetDocumentShiftType.Vertical );
	endif;
	
	//****************** Annex2
	//*************************
	sales = vats.Copy ( new Structure ( "VATUse, Operation", true, 0 ) );
	sales.GroupBy ( "CodeFiscal, Date, Series, Number", "Amount, VAT" );
	
	i = 100; // data index
	line = 1;
	pagesStart = T.Area ( "B1" ).Bottom + 1; // r-index
	pageSize = 58; // data rows per page
	nextPage = 200; // data index
	pagestep = 100; // data step (means no more then 100 data rows per page)
	pagesCount = 0;
	pageTableStarts = 5; // r-index from the top of the page (skip table header)
	attachment = T.GetArea ( "B1" );
	for each row in sales do
		FieldsValues [ "AA" + i ] = line;
	    FieldsValues [ "BA" + i ] = row.CodeFiscal;
	    FieldsValues [ "CA" + i ] = row.Date;
	    FieldsValues [ "DA" + i ] = row.Series;	
		suffix = Format ( row.Number, "NG=0" );
		size = StrLen ( suffix );
	    FieldsValues [ "EA" + i ] = ? ( size < 7, Left ( "0000000", 7 - size ) + suffix, suffix );
	    FieldsValues [ "FA" + i ] = row.Amount;	
	    FieldsValues [ "GA" + i ] = row.VAT;	
	    line = line + 1;
		if ( i = 143 ) then
	    	i = nextPage;
			elsif ( i = ( nextPage + pageSize ) ) then
			nextPage = nextPage + pageStep;
			i = nextPage;
			newPage = attachment.GetArea ();
			pageHeight = newPage.TableHeight;
			k = nextPage;
			for j = pageTableStarts to pageTableStarts + pageSize do
				id = Format(k, "NG=0");
				a = newPage.Area ( j, 2, j, 2 ); // c-index in the template
				name = "AA" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 4, j, 4 );
				name = "BA" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 12, j, 12 );
				name = "CA" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 19, j, 19 );
				name = "DA" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 24, j, 24 );
				name = "EA" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a.Format = undefined;
				a = newPage.Area ( j, 31, j, 31 );
				name = "FA" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				a = newPage.Area ( j, 39, j, 39 );
				name = "GA" + id;
				a.Parameter = name;
				a.DetailsParameter = "_Detail_" + name;
				k = k + 1;
			enddo;
			a = newPage.Area ( j, 31, j, 31 );
			id = Format(k, "NG=0");
			name = "FA" + id;
			a.Parameter = name;
			a.DetailsParameter = "_Detail_" + name;
			a = newPage.Area ( j, 39, j, 39 );
			name = "GA" + id;
			a.Parameter = name;
			a.DetailsParameter = "_Detail_" + name;
			areaName = "R" + Format ( ( pagesStart + ( pageHeight * pagesCount ) ), "NG=0" );
			T.InsertArea ( newPage.Area (), T.Area ( areaName ), SpreadsheetDocumentShiftType.Vertical, false );
			pagesCount = pagesCount + 1;
		else
			i = i + 1;
		endif;
	enddo;
	FieldsValues [ "Rows2" ] = line - 1;
	
	// Remove unused attachment
	if ( i < 201 ) then
		T.DeleteArea ( T.Area ( "B1" ), SpreadsheetDocumentShiftType.Vertical );
	endif;
	
	readTemplateParameters ();
	T.Parameters.Fill ( TemplateParameters );
	TabDoc.Put ( T );
	
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure

Procedure IncomeClass ()

	result = getLast ( "IncomeClass" );

EndProcedure

Procedure IncomeCode ()

	result = getLast ( "IncomeCode" );

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

// Purchases Totals

Procedure F136 ()

	result = sum ( "F100:F135" );

EndProcedure

Procedure G136 ()

	result = sum ( "G100:G135" );

EndProcedure

Procedure F255 ()

	result = sum ( "F200:F254" );

EndProcedure

Procedure G255 ()

	result = sum ( "G200:G254" );

EndProcedure

Procedure F355 ()

	result = sum ( "F300:F354" );
	put ( "F355", result );

EndProcedure

Procedure G355 ()

	result = sum ( "G300:G354" );
	put ( "G355", result );

EndProcedure

Procedure F455 ()

	result = sum ( "F400:F454" );
	put ( "F455", result );

EndProcedure

Procedure G455 ()

	result = sum ( "G400:G454" );
	put ( "G455", result );

EndProcedure

Procedure F555 ()

	result = sum ( "F500:F554" );
	put ( "F555", result );

EndProcedure

Procedure G555 ()

	result = sum ( "G500:G554" );
	put ( "G555", result );

EndProcedure

Procedure F1000 ()

	list = new Array ();
	list.Add ( get ( "F136" ) );
	list.Add ( get ( "F255" ) );
	list.Add ( get ( "F355" ) );
	list.Add ( get ( "F455" ) );
	list.Add ( get ( "F555" ) );
	list.Add ( get ( "F655" ) );
	list.Add ( get ( "F755" ) );
	list.Add ( get ( "F855" ) );
	list.Add ( get ( "F955" ) );
	result = 0;
	for each amount in list do
		if ( amount <> undefined ) then
			result = result + amount;
		endif;
	enddo;
	put ( "F1000", result );

EndProcedure

Procedure G1000 ()

	list = new Array ();
	list.Add ( get ( "G136" ) );
	list.Add ( get ( "G255" ) );
	list.Add ( get ( "G355" ) );
	list.Add ( get ( "G455" ) );
	list.Add ( get ( "G555" ) );
	list.Add ( get ( "G655" ) );
	list.Add ( get ( "G755" ) );
	list.Add ( get ( "G855" ) );
	list.Add ( get ( "G955" ) );
	result = 0;
	for each amount in list do
		if ( amount <> undefined ) then
			result = result + amount;
		endif;
	enddo;
	put ( "G1000", result );

EndProcedure

// Sales Totals

Procedure FA144 ()

	result = sum ( "FA100:FA143" );

EndProcedure

Procedure GA144 ()

	result = sum ( "GA100:GA143" );

EndProcedure

Procedure FA259 ()

	result = sum ( "FA200:FA258" );

EndProcedure

Procedure GA259 ()

	result = sum ( "GA200:GA258" );

EndProcedure

Procedure FA359 ()

	result = sum ( "FA300:FA358" );
	put ( "FA359", result );

EndProcedure

Procedure GA359 ()

	result = sum ( "GA300:GA358" );
	put ( "GA359", result );

EndProcedure

Procedure FA459 ()

	result = sum ( "FA400:FA458" );
	put ( "FA459", result );

EndProcedure

Procedure GA459 ()

	result = sum ( "GA400:GA458" );
	put ( "GA459", result );

EndProcedure

Procedure FA559 ()

	result = sum ( "FA500:FA558" );
	put ( "FA559", result );

EndProcedure

Procedure GA559 ()

	result = sum ( "GA500:G5258" );
	put ( "GA559", result );

EndProcedure

Procedure FA659 ()

	result = sum ( "FA600:FA658" );
	put ( "FA659", result );

EndProcedure

Procedure GA659 ()

	result = sum ( "GA600:GA658" );
	put ( "GA659", result );

EndProcedure

Procedure FA759 ()

	result = sum ( "FA700:FA758" );
	put ( "FA759", result );

EndProcedure

Procedure GA759 ()

	result = sum ( "GA700:GA758" );
	put ( "GA759", result );

EndProcedure

Procedure FA1000 ()

	list = new Array ();
	list.Add ( get ( "FA144" ) );
	list.Add ( get ( "FA259" ) );
	list.Add ( get ( "FA359" ) );
	list.Add ( get ( "FA459" ) );
	list.Add ( get ( "FA559" ) );
	list.Add ( get ( "FA659" ) );
	list.Add ( get ( "FA759" ) );
	list.Add ( get ( "FA859" ) );
	list.Add ( get ( "FA959" ) );
	result = 0;
	for each amount in list do
		if ( amount <> undefined ) then
			result = result + amount;
		endif;
	enddo;
	put ( "FA1000", result );

EndProcedure

Procedure GA1000 ()

	list = new Array ();
	list.Add ( get ( "GA144" ) );
	list.Add ( get ( "GA259" ) );
	list.Add ( get ( "GA359" ) );
	list.Add ( get ( "GA459" ) );
	list.Add ( get ( "GA559" ) );
	list.Add ( get ( "GA659" ) );
	list.Add ( get ( "GA759" ) );
	list.Add ( get ( "GA859" ) );
	list.Add ( get ( "GA959" ) );
	result = 0;
	for each amount in list do
		if ( amount <> undefined ) then
			result = result + amount;
		endif;
	enddo;
	put ( "GA1000", result );

EndProcedure
