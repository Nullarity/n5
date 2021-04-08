#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Make ( TabDoc, Document ) export
	
	SetPrivilegedMode ( true );
	env = getEnv ( TabDoc, Document );
	prepareAreas ( Env );
	prepareLines ( Env );
	prepareRegisterTypesTable ( Env );
	prepareTableMovements ( Env );
	putMovements ( Env );
	SetPrivilegedMode ( false );

EndProcedure

Function getEnv ( TabDoc, Document )
	
	return new Structure ( "TabDoc, Object", TabDoc, Document.GetObject () );
	
EndFunction 

Procedure prepareAreas ( Env )
	
	Env.Insert ( "Template", Reports.Records.GetTemplate ( "Records" ) );
	template = Env.Template;
	Env.Insert ( "RegisterNameArea", template.GetArea ( "RegisterName" ) );
	Env.Insert ( "DocHeaderArea", template.GetArea ( "DocumentHeader" ) );
	Env.Insert ( "DocAttributeArea", template.GetArea ( "DocumentAttribute" ) );
	Env.Insert ( "DocTabularPartNameArea", template.GetArea ( "DocumentTabularSectionName" ) );
	Env.Insert ( "DocTableAttributePresentationArea", template.GetArea ( "DocumentTableAttributePresentation|vDocumentTableAttributePresentation" ) );
	Env.Insert ( "DocTableAttributeValueArea", template.GetArea ( "DocumentTableAttributeValue|vDocumentTableAttributePresentation" ) );
	Env.Insert ( "DocTableLNPresentationArea", template.GetArea ( "DocumentTableAttributePresentation|vDocumentLineNumber" ) );
	Env.Insert ( "DocTableLNValueArea", template.GetArea ( "DocumentTableAttributeValue|vDocumentLineNumber" ) );
	Env.Insert ( "AccumulationRegisterTableHeader", template.GetArea ( "AccumulationRegisterHeader" ) );
	Env.Insert ( "AccumulationRegisterRowArea", template.GetArea ( "AccumulationRegisterRow" ) );
	Env.Insert ( "AccumulationRegisterRowAreaPicture", template.GetArea ( "AccumulationRegisterRowPicture" ) );
	Env.Insert ( "AccountingRegisterTableHeader", template.GetArea ( "AccountingRegisterHeader" ) );
	Env.Insert ( "AccountingRegisterRowArea", template.GetArea ( "AccountingRegisterRow" ) );
	Env.Insert ( "AccountingRegisterHeaderDependency", template.GetArea ( "AccountingRegisterHeaderDependency" ) );
	Env.Insert ( "AccountingRegisterRowDependency", template.GetArea ( "AccountingRegisterRowDependency" ) );
	
EndProcedure 

Procedure prepareLines ( Env )
	
	Env.Insert ( "DoubleLine", new Line ( SpreadsheetDocumentCellLineType.Double ) );
	Env.Insert ( "DottedLine", new Line ( SpreadsheetDocumentCellLineType.Dotted ) );
	Env.Insert ( "SolidLine", new Line ( SpreadsheetDocumentCellLineType.Solid ) );
	
EndProcedure 

Procedure prepareRegisterTypesTable ( Env )
	
	Env.Insert ( "RegisterTypesTable", new ValueTable () );
	table = Env.RegisterTypesTable;
	table.Columns.Add ( "Order" );
	table.Columns.Add ( "RegisterType" );
	table.Columns.Add ( "MetadataObject" );
	for each movement in Env.Object.RegisterRecords do
		metadataObject = movement.Metadata ();
		registerRow = table.Add ();
		registerRow.MetadataObject = metadataObject;
		if ( Metadata.AccountingRegisters.Contains ( metadataObject ) ) then
			registerRow.Order = 0;
			registerRow.RegisterType = "Accounting";
		elsif ( Metadata.InformationRegisters.Contains ( metadataObject ) ) then
			registerRow.Order = 1;
			registerRow.RegisterType = "Information";
		elsif ( Metadata.AccumulationRegisters.Contains ( metadataObject ) ) then
			registerRow.Order = 2;
			registerRow.RegisterType = "Accumulation";
		elsif ( Metadata.CalculationRegisters.Contains ( metadataObject ) ) then
			registerRow.Order = 3;
			registerRow.RegisterType = "Calculation";
		else
			registerRow.Order = 100;
		endif;
	enddo;
	table.Sort ( "Order" );
	
EndProcedure 

Procedure prepareTableMovements ( Env )
	
	Env.Insert ( "TableMovements", new ValueTable () );
	table = Env.TableMovements;
	table.Columns.Add ( "MovementDirection" );
	table.Columns.Add ( "DimensionIndex" );
	table.Columns.Add ( "DimensionPresentation" );
	table.Columns.Add ( "DimensionValue" );
	table.Columns.Add ( "ResourceIndex" );
	table.Columns.Add ( "ResourcePresentation" );
	table.Columns.Add ( "ResourceValue" );
	table.Columns.Add ( "AttributeIndex" );
	table.Columns.Add ( "AttributePresentation" );
	table.Columns.Add ( "AttributeValue" );
	
EndProcedure 
	
Procedure putMovements ( Env )
	
	Env.TabDoc.Clear ();
	for each register in Env.RegisterTypesTable do
		if ( register.RegisterType = "Accounting" ) then
			putAccountingMovements ( Env, register );
		elsif ( register.RegisterType = "Information" ) or
			( register.RegisterType = "Accumulation" ) or
			( register.RegisterType = "Calculation" ) then
			putRegisterMovements ( Env, register );
		endif;
	enddo; 
	putDocumentAttributes ( Env );
	
EndProcedure 

Function getPresentation ( Value, ShowEmpty )
	
	if ( ShowEmpty ) then
		return Conversion.ValueToString ( Value );
	else
		return Value;
	endif; 
	
EndFunction 

Procedure putRegisterMovements ( Env, Register )
	
	Env.Object.RegisterRecords [ register.MetadataObject.Name ].Read ();
	recordsCounter = Env.Object.RegisterRecords [ Register.MetadataObject.Name ].Count ();
	if ( recordsCounter = 0 ) then
		return;
	endif; 
	
	optionalDimensions = new Array;
	//
	// Obligatory dimensions for all registers
	//
	optionalDimensions.Add ( new Structure ( "Name, Presentation", "Active", Output.RecordActive () ) );
	//
	// Complete register presentation
	//
	if ( Register.RegisterType = "Information" ) then
		registerTypePresentation = Output.CutInformationRegister ();
		Env.RegisterNameArea.Drawings.RegisterPicture.Picture = PictureLib.InformationRegister;
		if ( Register.MetadataObject.InformationRegisterPeriodicity <> undefined ) then
			optionalDimensions.Add ( new Structure ( "Name, Presentation", "Period", Output.Period () ) );
		endif; 
	elsif ( Register.RegisterType = "Accumulation" ) then
		optionalDimensions.Add ( new Structure ( "Name, Presentation", "Period", Output.Period () ) );
		registerTypePresentation = Output.CutAccumulationRegister ();
		Env.RegisterNameArea.Drawings.RegisterPicture.Picture = PictureLib.AccumulationRegister;
	elsif ( Register.RegisterType = "Calculation" ) then
		optionalDimensions.Add ( new Structure ( "Name, Presentation", "RegistrationPeriod", Output.RegistrationPeriod () ) );
		if ( Register.MetadataObject.ActionPeriod ) then
			optionalDimensions.Add ( new Structure ( "Name, Presentation", "BegOfActionPeriod", Output.BegOfActionPeriod () ) );
			optionalDimensions.Add ( new Structure ( "Name, Presentation", "EndOfActionPeriod", Output.EndOfActionPeriod () ) );
		endif; 
		if ( Register.MetadataObject.BasePeriod ) then
			optionalDimensions.Add ( new Structure ( "Name, Presentation", "BegOfBasePeriod", Output.BegOfBasePeriod () ) );
			optionalDimensions.Add ( new Structure ( "Name, Presentation", "EndOfBasePeriod", Output.EndOfBasePeriod () ) );
		endif;
		optionalDimensions.Add ( new Structure ( "Name, Presentation", "CalculationType", Output.CalculationType () ) );
		registerTypePresentation = Output.CutCalculationRegister ();
		Env.RegisterNameArea.Drawings.RegisterPicture.Picture = PictureLib.CalculationRegister;
	endif;
	registerPresentation = Output.RegisterTypeAndPresentation ( new Structure ( "RegisterType, RegisterPresentation", registerTypePresentation, Register.MetadataObject.Presentation () ) );
	if ( Register.RegisterType = "Accumulation" ) then
		if ( Register.MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance ) then
			registerPresentation = registerPresentation + " " + Output.CutBalancesAndTurnovers ();
		else
			registerPresentation = registerPresentation + " " + Output.CutTurnovers ();
		endif; 
	endif; 
	Env.RegisterNameArea.Parameters.ObjectPresentation = registerPresentation;
	Env.TabDoc.Put ( Env.RegisterNameArea );
	
	Env.TabDoc.StartRowGroup ();
	
	Env.TabDoc.Put ( Env.AccumulationRegisterTableHeader );
	//
	// Incease table for put each movement
	//
	maxAttributes = Max ( 0, Register.MetadataObject.Dimensions.Count () + optionalDimensions.Count () );
	maxAttributes = Max ( maxAttributes, Register.MetadataObject.Resources.Count () );
	maxAttributes = Max ( maxAttributes, Register.MetadataObject.Attributes.Count () );
	Env.TableMovements.Clear ();
	for i = 0 to maxAttributes - 1 do
		Env.TableMovements.Add ();
	enddo;
	
	tableCounter = Env.TableMovements.Count () - 1;
	movementCounter= 1;
	
	for each movement in Env.Object.RegisterRecords [ Register.MetadataObject.Name ] do
		
		Env.TableMovements.FillValues ( undefined );
		//
		// Collect optional dimensions
		//
		i = 0;
		for each attribute in optionalDimensions do
			dimensionPresentation = attribute.Presentation;
			Env.TableMovements [ i ].DimensionPresentation = dimensionPresentation;
			Env.TableMovements [ i ].DimensionValue= movement [ attribute.Name ];
			
			i = i + 1;
		enddo; 
		//
		// Collect dimensions
		//
		for each attribute in Register.MetadataObject.Dimensions do
			dimensionPresentation = attribute.Presentation ();
			Env.TableMovements [ i ].DimensionIndex = attribute;
			Env.TableMovements [ i ].DimensionPresentation = dimensionPresentation;
			Env.TableMovements [ i ].DimensionValue = movement [ attribute.Name ];
			
			i = i + 1;
		enddo;
		//
		// Collect resources
		//
		i = 0;
		for each attribute in Register.MetadataObject.Resources do
			Env.TableMovements [ i ].ResourceIndex = attribute;
			Env.TableMovements [ i ].ResourcePresentation = attribute.Presentation ();
			Env.TableMovements [ i ].ResourceValue = movement [ attribute.Name ];
			
			i = i + 1;
		enddo;
		//
		// Collect attributes
		//
		i = 0;
		for each attribute in Register.MetadataObject.Attributes do
			Env.TableMovements [ i ].AttributeIndex = attribute;
			Env.TableMovements [ i ].AttributePresentation = attribute.Presentation ();
			Env.TableMovements [ i ].AttributeValue = movement [ attribute.Name ];
			
			i = i + 1;
		enddo; 
		//
		// Put table
		//
		for i = 0 to tableCounter do
			
			if // for first dimension - set direction
				( i = 0 ) and
				( Register.RegisterType = "Accumulation" ) then
				
				accumulationRegisterRow = Env.AccumulationRegisterRowAreaPicture;
				if ( Register.MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers ) then
					accumulationRegisterRow.Drawings.MovementPicture.Picture = PictureLib.Turnover;
				else
					if ( movement.RecordType = AccumulationRecordType.Expense ) then
						accumulationRegisterRow.Drawings.MovementPicture.Picture = PictureLib.Minus;
					else
						accumulationRegisterRow.Drawings.MovementPicture.Picture = PictureLib.Plus;
					endif; 
				endif; 
			else
				accumulationRegisterRow = Env.AccumulationRegisterRowArea;
			endif; 
			
			accumulationRegisterRow.Parameters.Fill ( Env.TableMovements [ i ] );
			//
			// Set appearance
			//
			bottomArea = accumulationRegisterRow.Area ( "C1:C19" );
			if ( i = tableCounter ) then
				if ( recordsCounter = movementCounter ) then
					bottomArea.BottomBorder = Env.SolidLine;
				else 
					bottomArea.BottomBorder = Env.DoubleLine;
				endif;
			else
				bottomArea.BottomBorder = Env.DottedLine;
			endif; 
			
			Env.TabDoc.Put ( accumulationRegisterRow );
		enddo; 
		
		movementCounter = movementCounter + 1;
		
	enddo;
	Env.TabDoc.EndRowGroup ();
	
EndProcedure 

Procedure putDocumentAttributes ( Env )
	//
	// Put document attributes
	//
	Env.RegisterNameArea.Drawings.RegisterPicture.Picture = PictureLib.Document;
	Env.RegisterNameArea.Parameters.ObjectPresentation = Env.Object;
	Env.TabDoc.Put ( Env.RegisterNameArea );
	Env.TabDoc.StartRowGroup ();
	Env.TabDoc.Put ( Env.DocHeaderArea );
	//
	// Put header
	//
	i = 1;
	attributesCount = Env.Object.Metadata ().Attributes.Count ();
	for each attribute in Env.Object.Metadata ().Attributes do
		Env.DocAttributeArea.Parameters.AttributePresentation = attribute.Presentation ();
		Env.DocAttributeArea.Parameters.AttributeValue = Env.Object [ attribute.Name ];
		if ( i = attributesCount ) then
			bottomArea = Env.DocAttributeArea.Area ( "C1:C" + Env.DocAttributeArea.TableWidth );
			bottomArea.BottomBorder = Env.SolidLine;
		endif; 
		Env.TabDoc.Put ( Env.DocAttributeArea );
		i = i + 1;
	enddo; 
	//
	// Put tabular parts
	//
	for each tabularPart in Env.Object.Metadata ().TabularSections do
		Env.DocTabularPartNameArea.Parameters.TabularSectionName = tabularPart.Presentation ();
		
		Env.TabDoc.Put ( Env.DocTabularPartNameArea );
		firstColumn = true;
		//
		// Put columns
		//
		if ( tabularPart.Attributes.Count () = 0 ) then
			continue;
		endif; 
		for each tabularColumn in tabularPart.Attributes do
			if ( firstColumn ) then
				firstColumn = false;
				Env.TabDoc.Put ( Env.DocTableLNPresentationArea );
			endif;
			Env.DocTableAttributePresentationArea.Parameters.TableAttributePresentation = tabularColumn.Presentation ();
			Env.TabDoc.Join ( Env.DocTableAttributePresentationArea );
		enddo;
		//
		// Put data
		//
		lineNumber = 1;
		for each documentRow in Env.Object [ tabularPart.Name ] do
			firstColumn = true;
			Env.DocTableLNValueArea.Parameters.LineNumber = lineNumber;
			for each tabularColumn in tabularPart.Attributes do
				if ( firstColumn ) then
					firstColumn = false;
					Env.TabDoc.Put ( Env.DocTableLNValueArea );
				endif;
				Env.DocTableAttributeValueArea.Parameters.TableAttributeValue = documentRow [ tabularColumn.Name ];
				Env.TabDoc.Join ( Env.DocTableAttributeValueArea );
			enddo; 
			lineNumber = lineNumber + 1;
		enddo; 
	enddo; 
	
	Env.TabDoc.EndRowGroup ();
	
EndProcedure 

Procedure putAccountingMovements ( Env, Register )
	
	if ( Register.MetadataObject = Metadata.AccountingRegisters.General ) then
		description = ? ( Options.Russian (), "DescriptionRu", "Description" );;
		s = "
		|select 1 as Part, General.Recorder as Recorder, General.AccountDr as AccountDr,
		|	General.AccountCr as AccountCr, General.AccountDr.Code as AccountDrCode,
		|	General.AccountCr.Code as AccountCrCode, General.AccountDr." + description + " as AccountDrDescription,
		|	General.AccountCr." + description + " as AccountCrDescription, General.Company as Company,
		|	presentation ( General.Company ) as CompanyPresentation, General.Content as Content,
		|	presentation ( General.CurrencyDr ) as CurrencyDrPresentation, presentation ( General.CurrencyCr ) as CurrencyCrPresentation,
		|	presentation ( General.ExtDimensionDr1 ) as DimDr1, presentation ( General.ExtDimensionDr2 ) as DimDr2,
		|	presentation ( General.ExtDimensionDr3 ) as DimDr3, General.ExtDimensionDr1 as DimDr1Value,
		|	General.ExtDimensionDr2 as DimDr2Value, General.ExtDimensionDr3 as DimDr3Value,
		|	presentation ( General.ExtDimensionCr1 ) as DimCr1, presentation ( General.ExtDimensionCr2 ) as DimCr2,
		|	presentation ( General.ExtDimensionCr3 ) as DimCr3, General.ExtDimensionCr1 as DimCr1Value,
		|	General.ExtDimensionCr2 as DimCr2Value, General.ExtDimensionCr3 as DimCr3Value,
		|	General.LineNumber as LineNumber, General.Period as Period, General.QuantityDr as QuantityDr, General.QuantityCr as QuantityCr,
		|	General.Amount as Amount, General.CurrencyAmountDr as CurrencyAmountDr, General.CurrencyAmountCr as CurrencyAmountCr
		|from AccountingRegister.General.RecordsWithExtDimensions ( , , Recorder = &Ref ) as General
		|";
		if ( Env.Object.Posted ) then
			s = s + "
			|union all
			|select 2, General.Recorder, General.AccountDr, General.AccountCr, General.AccountDr.Code,
			|	General.AccountCr.Code, General.AccountDr." + description + ",
			|	General.AccountCr." + description + ", General.Company,
			|	presentation ( General.Company ), General.Content,
			|	presentation ( General.CurrencyDr ), presentation ( General.CurrencyCr ),
			|	presentation ( General.ExtDimensionDr1 ), presentation ( General.ExtDimensionDr2 ),
			|	presentation ( General.ExtDimensionDr3 ), General.ExtDimensionDr1,
			|	General.ExtDimensionDr2, General.ExtDimensionDr3,
			|	presentation ( General.ExtDimensionCr1 ), presentation ( General.ExtDimensionCr2 ),
			|	presentation ( General.ExtDimensionCr3 ), General.ExtDimensionCr1,
			|	General.ExtDimensionCr2, General.ExtDimensionCr3,
			|	General.LineNumber, General.Period, General.QuantityDr, General.QuantityCr,
			|	General.Amount, General.CurrencyAmountDr, General.CurrencyAmountCr
			|from AccountingRegister.General.RecordsWithExtDimensions ( , , Dependency = &Ref ) as General
			|order by Part, Recorder, LineNumber
			|";
		endif;
		q = new Query ( s );
		q.SetParameter ( "Ref", Env.Object.Ref );
		table = q.Execute ().Unload ();
		if ( table.Count () = 0 ) then
			return;
		endif; 
		registerPresentation = Output.AccountingRegisterTypeAndPresentation ( new Structure ( "RegisterPresentation", Register.MetadataObject.Presentation () ) );
		Env.RegisterNameArea.Parameters.ObjectPresentation = registerPresentation;
		Env.RegisterNameArea.Drawings.RegisterPicture.Picture = PictureLib.DebitCredit;
		Env.TabDoc.Put ( Env.RegisterNameArea );
		Env.TabDoc.StartRowGroup ();
		Env.TabDoc.Put ( Env.AccountingRegisterTableHeader );
		area1 = Env.AccountingRegisterRowArea;
		area2 = Env.AccountingRegisterRowDependency;
		dependencyArea = Env.AccountingRegisterHeaderDependency;
		lastDependency = undefined;
		q = Output.ShortQuantity ();
		for each row in table do
			if ( row.Part = 1 ) then
				area = area1;
			else
				area = area2;
				if ( row.Recorder <> lastDependency ) then
					lastDependency = row.Recorder;
					dependencyArea.Parameters.Fill ( row );
					Env.TabDoc.Put ( dependencyArea );
				endif;
			endif;
			p = area.Parameters;
			FillPropertyValues ( p, row );
			accountDr = ServerCache.AccountData ( row.AccountDr ).Fields;
			accountCr = ServerCache.AccountData ( row.AccountCr ).Fields;
			p.CurrencyDrPresentation = getPresentation ( row.CurrencyDrPresentation, accountDr.Currency );
			p.CurrencyCrPresentation = getPresentation ( row.CurrencyCrPresentation, accountCr.Currency );
			p.DimDr1 = getPresentation ( row.DimDr1, accountDr.Level > 0 );
			p.DimDr2 = getPresentation ( row.DimDr2, accountDr.Level > 1 );
			p.DimDr3 = getPresentation ( row.DimDr3, accountDr.Level > 2 );
			p.DimCr1 = getPresentation ( row.DimCr1, accountCr.Level > 0 );
			p.DimCr2 = getPresentation ( row.DimCr2, accountCr.Level > 1 );
			p.DimCr3 = getPresentation ( row.DimCr3, accountCr.Level > 2 );
			Env.TabDoc.Put ( area );
		enddo;
		Env.TabDoc.EndRowGroup ();
	endif;
			
EndProcedure 

#endif