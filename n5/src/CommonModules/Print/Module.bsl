&AtClient
Procedure Print ( Params ) export
	
	supportedLanguages = Params.Languages;
	if ( supportedLanguages = undefined ) then
		printForm ( Params );
	else
		form = Params.Key;
		language = PrintSrv.Language ( form );
		if ( language = undefined
			or unsupportedLanguage ( supportedLanguages, language ) ) then
			p = new Structure ( "Languages, Form", supportedLanguages, form );
			callback = new NotifyDescription ( "LanguageSelected", ThisObject, Params );
			OpenForm ( "CommonForm.PrintLanguage", p, , , , , callback );
		else
			printForm ( Params, language );
		endif;
	endif;
	
EndProcedure

&AtClient
Procedure printForm ( Params, Language = undefined )
	
	p = new Structure ( "Params, Language", Params, Language );
	OpenForm ( "CommonForm.Print", p, , true );
	
EndProcedure

&AtClient
Procedure LanguageSelected ( Language, Params ) export
	
	if ( Language = undefined ) then
		return;
	endif;
	printForm ( Params, Language );
	
EndProcedure

&AtClient
Function unsupportedLanguage ( Supported, Language )
	
	return Conversion.StringToArray ( Supported ).Find ( Language ) = -1;
	
EndFunction

Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "Template" );
	p.Insert ( "Caption" );
	p.Insert ( "Key" );
	p.Insert ( "Objects" );
	p.Insert ( "Manager" );
	p.Insert ( "Languages" );
	p.Insert ( "Reference" );
	p.Insert ( "TabDoc" );
	p.Insert ( "SelectedLanguage" );
	return p;
	
EndFunction 

&AtServer
Procedure SetFooter ( TabDoc ) export
	
	TabDoc.Footer.Enabled = true;
	TabDoc.Footer.RightText = Output.PageFooter ();
	
EndProcedure

&AtServer
Procedure Repeat ( TabDoc, RowsCount = 1 ) export
	
	tableHeight = TabDoc.TableHeight;
	repeatArea = "R" + Format ( tableHeight - ( RowsCount - 1 ), "NG=" ) + ":R" + Format ( tableHeight, "NG=" );
	TabDoc.RepeatOnRowPrint = TabDoc.Area ( repeatArea );
	
EndProcedure 

&AtServer
Procedure OutputSchema ( DataSchema, TabDoc, DetailsAddress = undefined, Repeat = undefined ) export
	
	dataProcess = getDataProcessObjects ( DataSchema, DetailsAddress );
	outputProcessing ( TabDoc, dataProcess, Repeat );
	
EndProcedure

&AtServer
Function getDataProcessObjects ( DataSchema, DetailsAddress )
	
	dataProcess = new Structure ();
	dataComposer = new DataCompositionTemplateComposer ();
	if ( DetailsAddress = undefined ) then // Workaround: Explicitly without detailsDataObject. Otherwise platform hangs up
		dataProcess.Insert ( "DataTemplate", dataComposer.Execute ( DataSchema, DataSchema.DefaultSettings ) );
		dataProcess.Insert ( "DataProcessor", new DataCompositionProcessor () );
		dataProcess.DataProcessor.Initialize ( dataProcess.DataTemplate, , , true );
	else
		detailsDataObject = undefined;
		dataProcess.Insert ( "DataTemplate", dataComposer.Execute ( DataSchema, DataSchema.DefaultSettings, detailsDataObject ) );
		dataProcess.Insert ( "DataProcessor", new DataCompositionProcessor () );
		dataProcess.DataProcessor.Initialize ( dataProcess.DataTemplate, , detailsDataObject, true );
	endif; 
	dataProcess.Insert ( "DataOutputProcessor", new DataCompositionResultSpreadsheetDocumentOutputProcessor () );
	dataProcess.Insert ( "TypeOfTemplateGroup", Type ( "DataCompositionTemplateGroup" ) );
	dataProcess.Insert ( "TypeOfTemplateTable", Type ( "DataCompositionTemplateTable" ) );
	dataProcess.Insert ( "TypeOfTemplateRecords", Type ( "DataCompositionTemplateRecords" ) );
	dataProcess.Insert ( "TypeOfTemplateTableGroup", Type ( "DataCompositionTemplateTableGroup" ) );
	dataProcess.Insert ( "TypeOfTemplateTableRecords", Type ( "DataCompositionTemplateTableRecords" ) );
	if ( DetailsAddress <> undefined ) then
		storeDetailsData ( detailsDataObject, DetailsAddress );
	endif; 
	return dataProcess;
	
EndFunction 

&AtServer
Procedure storeDetailsData ( DetailsDataObject, DetailsAddress )
	
	if ( IsTempStorageURL ( DetailsAddress ) ) then
		DeleteFromTempStorage ( DetailsAddress );
		DetailsAddress = "";
	endif; 
	DetailsAddress = PutToTempStorage ( DetailsDataObject, DetailsAddress );
	
EndProcedure 

&AtServer
Procedure outputProcessing ( TabDoc, DataProcess, Repeat )
	
	repeatStart = 0;
	repeatEnd = 0;
	repeatHeader = ( Repeat <> undefined );
	if ( repeatHeader ) then
		repeatTemplate = getRepeatTemplate ( DataProcess, Repeat );
	endif; 
	DataProcess.DataOutputProcessor.SetDocument ( TabDoc );
	DataProcess.DataOutputProcessor.BeginOutput ();
	while ( true ) do
		outputItem = DataProcess.DataProcessor.Next ();
		if ( outputItem = undefined ) then
			break;
		endif;
		if ( repeatHeader ) then
			if ( repeatStart = 0 and outputItem.Template = repeatTemplate ) then
				repeatStart = TabDoc.TableHeight + 1;
			elsif ( repeatStart <> 0 and outputItem.Template <> repeatTemplate ) then
				repeatEnd = TabDoc.TableHeight;
				repeatHeader = false;
			endif; 
		endif; 
		DataProcess.DataOutputProcessor.OutputItem ( outputItem );
	enddo; 
	DataProcess.DataOutputProcessor.EndOutput ();
	if ( repeatStart <> 0 ) then
		rc = "R" + Format ( repeatStart, "NG=" ) + ":R" + Format ( Max ( repeatStart, repeatEnd ), "NG=" );
		TabDoc.RepeatOnRowPrint = TabDoc.Area ( rc );
	endif; 
	
EndProcedure 

&AtServer
Function getRepeatTemplate ( DataProcess, Repeat )
	
	dataTemplate = DataProcess.DataTemplate;
	bound = dataTemplate.Body.Count () - 1;
	for i = 0 to bound do
		item = dataTemplate.Body [ i ];
		typeOfCurrentItem = TypeOf ( item );
		if ( typeOfCurrentItem = DataProcess.TypeOfTemplateTable ) then
			if ( item.Name = Repeat ) then
				return item.HeaderTemplate;
			endif; 
		elsif ( typeOfCurrentItem = DataProcess.TypeOfTemplateGroup
			or typeOfCurrentItem = DataProcess.TypeOfTemplateRecords ) then
			if ( item.Name = Repeat ) then
				return dataTemplate.Body [ i - 1 ].Template;
			endif; 
		endif; 
	enddo; 
	
EndFunction 

&AtServer
Function ShortNumber ( Number ) export
	
	try
		value = Number ( Number );
	except
		return Number;
	endtry;
	return Format ( value, "NG=" );
	
EndFunction

&AtServer
Function NumberWithoutPrefix ( DocumentNumber, DocumentPrefix ) export
	
	number = TrimAll ( DocumentNumber );
	prefix = "";
	px = Application.Prefix ();
	if ( px <> "" ) then
		prefix = px;
	endif;
	prefix = prefix + DocumentPrefix;
	if ( Find ( number, prefix ) = 1 ) then
		number = Mid ( number, StrLen ( prefix ) + 1 );
	endif;
	while ( Left ( number, 1 ) = "0" ) do 
		number = Mid ( number, 2 );
	enddo;
	return number;
		
EndFunction

&AtServer
Function NumberWithoutSeries ( Number, Series ) export
	
	return TrimAll ( Mid ( Number, 1 + StrLen ( Series ) ) );
		
EndFunction

&AtServer
Procedure Entitle ( TabDoc, Title, Keyword = "###" ) export
	
	begin = TabDoc.FindText ( Keyword );
	if ( begin = undefined ) then
		return;
	endif; 
	end = TabDoc.FindText ( Keyword, , , , , false );
	if ( end = undefined ) then
		return;
	endif; 
	area = TabDoc.Area ( begin.Top, begin.Left, end.Bottom, end.Right );
	area.Merge ();
	area.Text = Title;
	
EndProcedure 

Function FormatItem ( Item, Package = undefined, Feature = undefined, Series = undefined, Code = undefined ) export
	
	if ( Code = undefined ) then
		s = "" + Item;
	else
		s = "" + Code + ", " + Item;
	endif; 
	if ( ValueIsFilled ( Package ) ) then
		s = s + ", " + Package;
	endif; 
	if ( ValueIsFilled ( Feature ) ) then
		s = s + ", " + Feature;
	endif; 
	if ( ValueIsFilled ( Series ) ) then
		s = s + ", #" + Series;
	endif; 
	return s;
	
EndFunction

&AtServer
Function VATInfo ( VATUse, Language = undefined ) export
	
	if ( VATUse = 1 ) then
		return Output.PrintVATInfo1 ( Language );
	elsif ( VATUse = 2 ) then
		return Output.PrintVATInfo2 ( Language );
	else
		return Output.PrintVATInfo0 ( Language );
	endif;
	
EndFunction

&AtServer
Function CurrencyInfo ( Currency, Rate, Factor ) export
	
	localCurrency = Application.Currency ();
	if ( LocalCurrency = Currency ) then
		return String ( localCurrency );
	else
		s = "1 " + Currency + " = " + Rate;
		if ( Factor <> 1 ) then
			s = s + " / " + Factor;
		endif;
		return s + " " + localCurrency;
	endif;
	
EndFunction

&AtServer
Procedure InjectLogo ( Logo, Area ) export
	
	drawings = Area.Drawings;
	placeholder = findPlaceholder ( drawings );
	if ( Logo = null ) then
		drawings.Delete ( placeholder );
	else
		placeholder.Picture = new Picture ( Logo.Get (), true );
	endif;
	
EndProcedure

&AtServer
Function findPlaceholder ( Drawings )
	
	for each image in Drawings do
		if ( StrStartsWith ( image.Name, "Logo" ) ) then
			return image;
		endif;
	enddo;
	
EndFunction

&AtServer
Procedure InjectPaid ( Paid, Area ) export
	
	drawings = Area.Drawings;
	if ( not Paid ) then
		drawings.Delete ( drawings.Paid );
	endif;
	
EndProcedure
