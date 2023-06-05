Procedure Make ()

	commonVatFields = "
	|select case when Table.Ref.Currency = &Currency then Table.VAT else cast ( Table.VAT * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end as VAT,
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else cast ( ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end as Amount, 
	|	Table.VATCode.Rate as Rate, Table.VATCode.Type as Type
	|";
	invoiceRecordsFields = commonVatFields + ", Table.Ref.Series as Series, Table.Ref.Number as Number";
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
	|and not Table.Ref.Transfer
	|and Table.Ref.VATUse <> 0
	|and Table.Ref.Status in (
	|	value ( Enum.FormStatuses.Unloaded ),
	|	value ( Enum.FormStatuses.Printed ),
	|	value ( Enum.FormStatuses.Submitted ),
	|	value ( Enum.FormStatuses.Returned )
	|)
	|union all
	|" + invoiceRecordsFields + ", Table.Ref.DeliveryDate as Date, 0, Table.Ref.Customer.CodeFiscal as CodeFiscal
	|from Document.InvoiceRecord.Services as Table
	|" + conditions + "
	|and Table.Ref.VATUse <> 0
	|and not Table.Ref.DeletionMark
	|and not Table.Ref.Transfer
	|and Table.Ref.Status in (
	|	value ( Enum.FormStatuses.Unloaded ),
	|	value ( Enum.FormStatuses.Printed ),
	|	value ( Enum.FormStatuses.Submitted ),
	|	value ( Enum.FormStatuses.Returned )
	|)
	|union all
	|" + vendorInvoiceFields + ", case when Table.Ref.Import then 2 else 1 end, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.Accounts as Table
	|" + conditions + "
	|and ( Table.Ref.VATUse <> 0 or Table.Ref.Import )
	|and Table.Ref.Posted
	|union all
	|" + vendorInvoiceFields + ", case when Table.Ref.Import then 2 else 1 end, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.FixedAssets as Table
	|" + conditions + "
	|and ( Table.Ref.VATUse <> 0 or Table.Ref.Import )
	|and Table.Ref.Posted
	|union all
	|" + vendorInvoiceFields + ", case when Table.Ref.Import then 2 else 1 end, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.IntangibleAssets as Table
	|" + conditions + "
	|and ( Table.Ref.VATUse <> 0 or Table.Ref.Import )
	|and Table.Ref.Posted
	|union all
	|" + vendorInvoiceFields + ", case when Table.Ref.Import then 2 else 1 end, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.Items as Table
	|" + conditions + "
	|and ( Table.Ref.VATUse <> 0 or Table.Ref.Import )
	|and Table.Ref.Posted
	|union all
	|" + vendorInvoiceFields + ", case when Table.Ref.Import then 2 else 1 end, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorInvoice.Services as Table
	|" + conditions + "
	|and ( Table.Ref.VATUse <> 0 or Table.Ref.Import )
	|and Table.Ref.Posted
	|union all
	|select sum ( case when Table.VAT then Table.Amount else 0 end ),
	|	sum ( case when Table.VAT then 0 else Table.Amount end ),
	|	Table.Charge.VAT.Rate, Table.Charge.VAT.Type, """", """", """", 2, """"
	|from Document.CustomsDeclaration.Charges as Table
	|" + conditions + "
	|and Table.Ref.Posted
	|group by Table.Charge.VAT
	|union all
	|select
	|	- case when Table.Ref.Currency = &Currency then Table.VAT else cast ( Table.VAT * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end,
	|	- case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else cast ( ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end,
	|	Table.VATCode.Rate, Table.VATCode.Type, Table.Ref.Series, Table.Ref.Reference,
	|	case Table.Ref.ReferenceDate when datetime (1, 1, 1) then Table.Ref.Date else Table.Ref.ReferenceDate end,
	|	1, Table.Ref.Vendor.CodeFiscal
	|from Document.VendorReturn.Items as Table
	|" + conditions + "
	|and Table.Ref.VATUse <> 0
	|and Table.Ref.Posted
	|union all
	|select Table.VAT, Table.Total - Table.VAT,	Table.VATCode.Rate, Table.VATCode.Type,
	|	Table.Series, Table.Series + Table.FormNumber, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.VATPurchases as Table
	|where not Table.Ref.DeletionMark
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Ref.VATUse <> 0
	|union all
	|select Table.VAT, Table.Total - Table.VAT,	Table.VATCode.Rate, Table.VATCode.Type,
	|	Table.Ref.Series, Table.Ref.Number, Table.Ref.Date, 3, cast ( Table.Ref.Base as Document.WriteOff ).Customer.CodeFiscal
	|from Document.InvoiceRecord.Items as Table
	|" + conditions + "
	|and not Table.Ref.DeletionMark
	|and Table.Ref.Base refs Document.WriteOff
	|and Table.Ref.VATUse <> 0
	|and Table.Ref.Status in (
	|	value ( Enum.FormStatuses.Unloaded ),
	|	value ( Enum.FormStatuses.Printed ),
	|	value ( Enum.FormStatuses.Submitted ),
	|	value ( Enum.FormStatuses.Returned )
	|)
	|union all
	|select Table.VAT, Table.Total - Table.VAT,	Table.VATCode.Rate, Table.VATCode.Type,
	|	Table.Series, Table.Series + Table.FormNumber, Table.Date, 0, Table.Customer.CodeFiscal
	|from Document.VATSales as Table
	|where not Table.Ref.DeletionMark
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Ref.VATUse <> 0
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else cast ( Table.VAT * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else cast ( ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end, 
	|	Table.VATCode.Rate, Table.VATCode.Type,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.Items as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|and Table.Ref.VATUse <> 0
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else cast ( Table.VAT * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else cast ( ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end, 
	|	Table.VATCode.Rate, Table.VATCode.Type,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.Services as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|and Table.Ref.VATUse <> 0
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else cast ( Table.VAT * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else cast ( ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end, 
	|	Table.VATCode.Rate, Table.VATCode.Type,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.FixedAssets as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|and Table.Ref.VATUse <> 0
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else Table.VAT * Table.Ref.Rate / Table.Ref.Factor end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else cast ( ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end, 
	|	Table.VATCode.Rate, Table.VATCode.Type,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.IntangibleAssets as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|and Table.Ref.VATUse <> 0
	|union all
	|select case when Table.Ref.Currency = &Currency then Table.VAT else cast ( Table.VAT * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) )end, 
	|	case when Table.Ref.Currency = &Currency then Table.Total - Table.VAT else cast ( ( Table.Total - Table.VAT ) * Table.Ref.Rate / Table.Ref.Factor as Number ( 15, 2 ) ) end,
	|	Table.VATCode.Rate, Table.VATCode.Type,
	|	Table.DocumentSeries, Table.Number, Table.Date, 1, Table.Vendor.CodeFiscal
	|from Document.ExpenseReport.Accounts as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Type = value ( Enum.DocumentTypes.Invoice )
	|and Table.Ref.VATUse <> 0
	|union all
	|select Table.VATLocal, Table.AmountLocal - Table.VATLocal, Table.VATCode, VATCode.Type, Table.Ref.Series,
	|		Table.Ref.Reference, Table.Ref.ReferenceDate, 1, Table.Ref.Vendor.CodeFiscal
	|from Document.AdjustVendorDebts.Accounting as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Ref.ApplyVAT
	|and Table.VATCode <> value ( Catalog.VAT.EmptyRef )
	|and Table.Ref.Reference <> ""
	|and Table.Ref.ReferenceDate <> datetime ( 1, 1, 1 )
	|and Table.Ref.Option in (
	|	value ( Enum.AdjustmentOptions.CustomAccountDr ),
	|	value ( Enum.AdjustmentOptions.AccountingDr ),
	|	value ( Enum.AdjustmentOptions.AccountingCr )
	|)
	|union all
	|select Table.VATLocal, Table.AmountLocal - Table.VATLocal, Table.VATCode, VATCode.Type, Table.Ref.Series,
	|		Table.Ref.Reference, Table.Ref.ReferenceDate, 1, Table.Ref.Vendor.CodeFiscal
	|from Document.AdjustVendorDebts.Adjustments as Table
	|where Table.Ref.Posted
	|and Table.Ref.Date between &DateStart and &DateEnd
	|and Table.Ref.Company = &Company
	|and Table.Ref.ApplyVAT
	|and Table.VATCode <> value ( Catalog.VAT.EmptyRef )
	|and Table.Ref.Reference <> ""
	|and Table.Ref.ReferenceDate <> datetime ( 1, 1, 1 )
	|and Table.Ref.Option in (
	|	value ( Enum.AdjustmentOptions.CustomAccountDr ),
	|	value ( Enum.AdjustmentOptions.AccountingDr ),
	|	value ( Enum.AdjustmentOptions.AccountingCr )
	|)
	|;
	|// #VATs
	|select sum ( VATs.Amount ), sum ( VATs.VAT ) as VAT, VATs.Rate as Rate, VATs.Type as Type, VATs.Operation as Operation,
	|	VATs.Series as Series, VATs.Number as Number, VATs.Date as Date, VATs.CodeFiscal as CodeFiscal
	|from VATs as VATs
	|group by VATs.Rate, VATs.Type, VATs.Operation, VATs.Date, VATs.Number, VATs.Series, VATs.CodeFiscal
	|order by VATs.Date
	|;
	|// @Advances
	|select sum ( General.Amount) as Amount
	|from AccountingRegister.General as General
	|where General.Period Between &DateStart and &DateEnd
	|and General.AccountDr in hierarchy ( value ( ChartOfAccounts.General._2252 ) )
	|and General.Company = &Company
	|and General.Amount > 0
	|;
	|// @AdvancesTaken
	|select General.AmountTurnoverCr - General.AmountTurnoverDr as Amount
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account in hierarchy ( value ( ChartOfAccounts.General._523 ) ), , Company = &Company, , ) as General
	|;
	|// @VATTaken
	|select General.AmountTurnoverDr as Amount
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, ,
	|	Account = value ( ChartOfAccounts.General._2252 ), , Company = &Company, , ) as General
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
	table = vats.Copy ( new Structure ( "Type, Operation", Enums.VAT.Standart, 0 ) );
	FieldsValues [ "A21" ] = table.Total ( "Amount" ) + Env.AdvancesTaken.Amount - Env.VATTaken.Amount;
	FieldsValues [ "B21" ] = table.Total ( "VAT" ) + Env.VATTaken.Amount;
	
	//************ reduced rate
	//*************************
	table = vats.Copy ( new Structure ( "Type, Operation", Enums.VAT.Reduced, 0 ) );
	FieldsValues [ "A23" ] = table.Total ( "Amount" );
	FieldsValues [ "B23" ] = table.Total ( "VAT" );
	
	//******************** zero
	//*************************
	table = vats.Copy ( new Structure ( "Type, Operation", Enums.VAT.Zero, 0 ) );
	FieldsValues [ "A24" ] = table.Total ( "Amount" );
	
	//****************** no VAT
	//*************************
	table = vats.Copy ( new Structure ( "Type, Operation", Enums.VAT.None, 0 ) );
	FieldsValues [ "A25" ] = table.Total ( "Amount" );
	
	//****************** Advances
	//*************************
	FieldsValues [ "B29" ] = Env.Advances.Amount;
	
	//****************** Receipt
	//*************************
	receipt = vats.Copy ( new Structure ( "Operation", 1 ) );
	FieldsValues [ "A30" ] = receipt.Total ( "Amount" );
	FieldsValues [ "B30" ] = receipt.Total ( "VAT" );
	
	//****************** Import
	//*************************
	table = vats.Copy ( new Structure ( "Operation", 2 ) );
	FieldsValues [ "A31" ] = table.Total ( "Amount" );
	FieldsValues [ "B31" ] = table.Total ( "VAT" );

	//****************** WriteOff
	//***************************
	table = vats.Copy ( new Structure ( "Operation", 3 ) );
	FieldsValues [ "B32" ] = table.Total ( "VAT" );
	
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
		index = Format ( i, "NG=0" );
		FieldsValues [ "A" + index ] = line;
	    FieldsValues [ "B" + index ] = row.CodeFiscal;
	    FieldsValues [ "C" + index ] = row.Date;
		prefix = row.Series;
	    FieldsValues [ "D" + index ] = prefix;
	    FieldsValues [ "E" + index ] = StrReplace ( row.Number, prefix, "" );
	    FieldsValues [ "F" + index ] = row.Amount;	
	    FieldsValues [ "G" + index ] = row.VAT;	
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
				_name = "A" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 4, j, 4 );
				_name = "B" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 12, j, 12 );
				_name = "C" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 19, j, 19 );
				_name = "D" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 24, j, 24 );
				_name = "E" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 31, j, 31 );
				_name = "F" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 39, j, 39 );
				_name = "G" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				k = k + 1;
			enddo;
			a = newPage.Area ( j, 31, j, 31 );
			id = Format(k, "NG=0");
			_name = "F" + id;
			a.Parameter = _name;
			a.DetailsParameter = "_Detail_" + _name;
			a = newPage.Area ( j, 39, j, 39 );
			_name = "G" + id;
			a.Parameter = _name;
			a.DetailsParameter = "_Detail_" + _name;
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
	sales = vats.Copy ( new Structure ( "Operation", 0 ) );
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
		index = Format ( i, "NG=0" );
		FieldsValues [ "AA" + index ] = line;
	    FieldsValues [ "BA" + index ] = row.CodeFiscal;
	    FieldsValues [ "CA" + index ] = row.Date;
	    FieldsValues [ "DA" + index ] = row.Series;	
		size = StrLen ( row.Series );
		number = Mid ( row.Number, size + 1 );
	    FieldsValues [ "EA" + index ] = number;
	    FieldsValues [ "FA" + index ] = row.Amount;	
	    FieldsValues [ "GA" + index ] = row.VAT;	
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
				_name = "AA" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 4, j, 4 );
				_name = "BA" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 12, j, 12 );
				_name = "CA" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 19, j, 19 );
				_name = "DA" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 24, j, 24 );
				_name = "EA" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a.Format = undefined;
				a = newPage.Area ( j, 31, j, 31 );
				_name = "FA" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				a = newPage.Area ( j, 39, j, 39 );
				_name = "GA" + id;
				a.Parameter = _name;
				a.DetailsParameter = "_Detail_" + _name;
				k = k + 1;
			enddo;
			a = newPage.Area ( j, 31, j, 31 );
			id = Format(k, "NG=0");
			_name = "FA" + id;
			a.Parameter = _name;
			a.DetailsParameter = "_Detail_" + _name;
			a = newPage.Area ( j, 39, j, 39 );
			_name = "GA" + id;
			a.Parameter = _name;
			a.DetailsParameter = "_Detail_" + _name;
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
	result = ? ( result < 0, 0, result );

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

Procedure F655 ()

	result = sum ( "F600:F654" );
	put ( "F655", result );

EndProcedure

Procedure G655 ()

	result = sum ( "G600:G654" );
	put ( "G655", result );

EndProcedure

Procedure F755 ()

	result = sum ( "F700:F754" );
	put ( "F755", result );

EndProcedure

Procedure G755 ()

	result = sum ( "G700:G754" );
	put ( "G755", result );

EndProcedure

Procedure F855 ()

	result = sum ( "F800:F854" );
	put ( "F855", result );

EndProcedure

Procedure G855 ()

	result = sum ( "G800:G854" );
	put ( "G855", result );

EndProcedure

Procedure F955 ()

	result = sum ( "F900:F954" );
	put ( "F955", result );

EndProcedure

Procedure G955 ()

	result = sum ( "G900:G954" );
	put ( "G955", result );

EndProcedure

Procedure F1055 ()

	result = sum ( "F1000:F1054" );
	put ( "F1055", result );

EndProcedure

Procedure G1055 ()

	result = sum ( "G1000:G1054" );
	put ( "G1055", result );

EndProcedure

Procedure F1155 ()

	result = sum ( "F1100:F1154" );
	put ( "F1155", result );

EndProcedure

Procedure G1155 ()

	result = sum ( "G1100:G1154" );
	put ( "G1155", result );

EndProcedure

Procedure F1255 ()

	result = sum ( "F1200:F1254" );
	put ( "F1255", result );

EndProcedure

Procedure G1255 ()

	result = sum ( "G1200:G1254" );
	put ( "G1255", result );

EndProcedure

Procedure F1355 ()

	result = sum ( "F1300:F1354" );
	put ( "F1355", result );

EndProcedure

Procedure G1355 ()

	result = sum ( "G1300:G1354" );
	put ( "G1355", result );

EndProcedure

Procedure F1455 ()

	result = sum ( "F1400:F1454" );
	put ( "F1455", result );

EndProcedure

Procedure G1455 ()

	result = sum ( "G1400:G1454" );
	put ( "G1455", result );

EndProcedure

Procedure F1555 ()

	result = sum ( "F1500:F1554" );
	put ( "F1555", result );

EndProcedure

Procedure G1555 ()

	result = sum ( "G1500:G1554" );
	put ( "G1555", result );

EndProcedure

Procedure F1655 ()

	result = sum ( "F1600:F1654" );
	put ( "F1655", result );

EndProcedure

Procedure G1655 ()

	result = sum ( "G1600:G1654" );
	put ( "G1655", result );

EndProcedure

Procedure F1755 ()

	result = sum ( "F1700:F1754" );
	put ( "F1755", result );

EndProcedure

Procedure G1755 ()

	result = sum ( "G1700:G1754" );
	put ( "G1755", result );

EndProcedure

Procedure F1855 ()

	result = sum ( "F1800:F1854" );
	put ( "F1855", result );

EndProcedure

Procedure G1855 ()

	result = sum ( "G1800:G1854" );
	put ( "G1855", result );

EndProcedure

Procedure F1955 ()

	result = sum ( "F1900:F1954" );
	put ( "F1955", result );

EndProcedure

Procedure G1955 ()

	result = sum ( "G1900:G1954" );
	put ( "G1955", result );

EndProcedure

Procedure F2000 ()

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
	list.Add ( get ( "F1055" ) );
	list.Add ( get ( "F1155" ) );
	list.Add ( get ( "F1255" ) );
	list.Add ( get ( "F1355" ) );
	list.Add ( get ( "F1455" ) );
	list.Add ( get ( "F1555" ) );
	list.Add ( get ( "F1655" ) );
	list.Add ( get ( "F1755" ) );
	list.Add ( get ( "F1855" ) );
	list.Add ( get ( "F1955" ) );
	result = 0;
	for each amount in list do
		if ( amount <> undefined ) then
			result = result + amount;
		endif;
	enddo;
	put ( "F2000", result );

EndProcedure

Procedure G2000 ()

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
	list.Add ( get ( "G1055" ) );
	list.Add ( get ( "G1155" ) );
	list.Add ( get ( "G1255" ) );
	list.Add ( get ( "G1355" ) );
	list.Add ( get ( "G1455" ) );
	list.Add ( get ( "G1555" ) );
	list.Add ( get ( "G1655" ) );
	list.Add ( get ( "G1755" ) );
	list.Add ( get ( "G1855" ) );
	list.Add ( get ( "G1955" ) );
	result = 0;
	for each amount in list do
		if ( amount <> undefined ) then
			result = result + amount;
		endif;
	enddo;
	put ( "G2000", result );

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

Procedure GA259 (

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

	result = sum ( "GA500:GA558" );
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

Procedure FA859 ()
	
	result = sum ( "FA800:FA858" );
	put ( "FA859", result );

EndProcedure

Procedure GA859 ()

	result = sum ( "GA800:GA858" );
	put ( "GA859", result );

EndProcedure

Procedure FA959 ()

	result = sum ( "FA900:FA958" );
	put ( "FA959", result );

EndProcedure

Procedure GA959 ()

	result = sum ( "GA900:GA958" );
	put ( "GA959", result );

EndProcedure

Procedure FA1059 ()

	result = sum ( "FA1000:FA1058" );
	put ( "FA1059", result );

EndProcedure

Procedure GA1059 ()

	result = sum ( "GA1000:GA1058" );
	put ( "GA1059", result );

EndProcedure

Procedure FA1159 ()

	result = sum ( "FA1100:FA1158" );
	put ( "FA1159", result );

EndProcedure

Procedure GA1159 ()

	result = sum ( "GA1100:GA1158" );
	put ( "GA1159", result );

EndProcedure

Procedure FA1259 ()

	result = sum ( "FA1200:FA1258" );
	put ( "FA1259", result );

EndProcedure

Procedure GA1259 ()

	result = sum ( "GA1200:GA1258" );
	put ( "GA1259", result );

EndProcedure

Procedure FA1359 ()

	result = sum ( "FA1300:FA1358" );
	put ( "FA1359", result );

EndProcedure

Procedure GA1359 ()

	result = sum ( "GA1300:GA1358" );
	put ( "GA1359", result );

EndProcedure

Procedure FA1459 ()

	result = sum ( "FA1400:FA1458" );
	put ( "FA1459", result );

EndProcedure

Procedure GA1459 ()

	result = sum ( "GA1400:GA1458" );
	put ( "GA1459", result );

EndProcedure

Procedure FA1559 ()

	result = sum ( "FA1500:FA1558" );
	put ( "FA1559", result );

EndProcedure

Procedure GA1559 ()

	result = sum ( "GA1500:GA1558" );
	put ( "GA1559", result );

EndProcedure

Procedure FA1659 ()

	result = sum ( "FA1600:FA1658" );
	put ( "FA1659", result );

EndProcedure

Procedure GA1659 ()

	result = sum ( "GA1600:GA1658" );
	put ( "GA1659", result );

EndProcedure

Procedure FA1759 ()

	result = sum ( "FA1700:FA1758" );
	put ( "FA1759", result );

EndProcedure

Procedure GA1759 ()

	result = sum ( "GA1700:GA1758" );
	put ( "GA1759", result );

EndProcedure

Procedure FA1859 ()

	result = sum ( "FA1800:FA1858" );
	put ( "FA1859", result );

EndProcedure

Procedure GA1859 ()

	result = sum ( "GA1800:GA1858" );
	put ( "GA1859", result );

EndProcedure

Procedure FA1959 ()

	result = sum ( "FA1900:FA1958" );
	put ( "FA1959", result );

EndProcedure

Procedure GA1959 ()

	result = sum ( "GA1900:GA1958" );
	put ( "GA1959", result );

EndProcedure

Procedure FA2059 ()

	result = sum ( "FA2000:FA2058" );
	put ( "FA2059", result );

EndProcedure

Procedure GA2059 ()

	result = sum ( "GA2000:GA2058" );
	put ( "GA2059", result );

EndProcedure

Procedure FA2159 ()

	result = sum ( "FA2100:FA2158" );
	put ( "FA2159", result );

EndProcedure

Procedure GA2159 ()

	result = sum ( "GA2100:GA2158" );
	put ( "GA2159", result );

EndProcedure

Procedure FA2259 ()

	result = sum ( "FA2200:FA2258" );
	put ( "FA2259", result );

EndProcedure

Procedure GA2259 ()

	result = sum ( "GA2200:GA2258" );
	put ( "GA2259", result );

EndProcedure

Procedure FA2359 ()

	result = sum ( "FA2300:FA2358" );
	put ( "FA2359", result );

EndProcedure

Procedure GA2359 ()

	result = sum ( "GA2300:GA2358" );
	put ( "GA2359", result );

EndProcedure

Procedure FA2459 ()

	result = sum ( "FA2400:FA2458" );
	put ( "FA2459", result );

EndProcedure

Procedure GA2459 ()

	result = sum ( "GA2400:GA2458" );
	put ( "GA2459", result );

EndProcedure

Procedure FA2559 ()

	result = sum ( "FA2500:FA2558" );
	put ( "FA2559", result );

EndProcedure

Procedure GA2559 ()

	result = sum ( "GA2500:GA2558" );
	put ( "GA2559", result );

EndProcedure

Procedure FA2659 ()

	result = sum ( "FA2600:FA2658" );
	put ( "FA2659", result );

EndProcedure

Procedure GA2659 ()

	result = sum ( "GA2600:GA2658" );
	put ( "GA2659", result );

EndProcedure

Procedure FA2759 ()

	result = sum ( "FA2700:FA2758" );
	put ( "FA2759", result );

EndProcedure

Procedure GA2759 ()

	result = sum ( "GA2700:GA2758" );
	put ( "GA2759", result );

EndProcedure

Procedure FA2859 ()

	result = sum ( "FA2800:FA2858" );
	put ( "FA2859", result );

EndProcedure

Procedure GA2859 ()

	result = sum ( "GA2800:GA2858" );
	put ( "GA2859", result );

EndProcedure

Procedure FA2959 ()

	result = sum ( "FA2900:FA2958" );
	put ( "FA2959", result );

EndProcedure

Procedure GA2959 ()

	result = sum ( "GA2900:GA2958" );
	put ( "GA2959", result );

EndProcedure

Procedure FA3000 ()

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
	list.Add ( get ( "FA1059" ) );
	list.Add ( get ( "FA1159" ) );
	list.Add ( get ( "FA1259" ) );
	list.Add ( get ( "FA1359" ) );
	list.Add ( get ( "FA1459" ) );
	list.Add ( get ( "FA1559" ) );
	list.Add ( get ( "FA1659" ) );
	list.Add ( get ( "FA1759" ) );
	list.Add ( get ( "FA1859" ) );
	list.Add ( get ( "FA1959" ) );
	list.Add ( get ( "FA2059" ) );
	list.Add ( get ( "FA2159" ) );
	list.Add ( get ( "FA2259" ) );
	list.Add ( get ( "FA2359" ) );
	list.Add ( get ( "FA2459" ) );
	list.Add ( get ( "FA2559" ) );
	list.Add ( get ( "FA2659" ) );
	list.Add ( get ( "FA2759" ) );
	list.Add ( get ( "FA2859" ) );
	list.Add ( get ( "FA2959" ) );
	result = 0;
	for each amount in list do
		if ( amount <> undefined ) then
			result = result + amount;
		endif;
	enddo;
	put ( "FA3000", result );

EndProcedure

Procedure GA3000 ()

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
	list.Add ( get ( "GA1059" ) );
	list.Add ( get ( "GA1159" ) );
	list.Add ( get ( "GA1259" ) );
	list.Add ( get ( "GA1359" ) );
	list.Add ( get ( "GA1459" ) );
	list.Add ( get ( "GA1559" ) );
	list.Add ( get ( "GA1659" ) );
	list.Add ( get ( "GA1759" ) );
	list.Add ( get ( "GA1859" ) );
	list.Add ( get ( "GA1959" ) );
	list.Add ( get ( "GA2059" ) );
	list.Add ( get ( "GA2159" ) );
	list.Add ( get ( "GA2259" ) );
	list.Add ( get ( "GA2359" ) );
	list.Add ( get ( "GA2459" ) );
	list.Add ( get ( "GA2559" ) );
	list.Add ( get ( "GA2659" ) );
	list.Add ( get ( "GA2759" ) );
	list.Add ( get ( "GA2859" ) );
	list.Add ( get ( "GA2959" ) );
	result = 0;
	for each amount in list do
		if ( amount <> undefined ) then
			result = result + amount;
		endif;
	enddo;
	put ( "GA3000", result );

EndProcedure
