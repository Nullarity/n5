{1,
{27,
{"Standart",1,0,"",""},
{0,
{"if",0,0,"if","if ( <?""Condition""> ) then
	<?>
endif;"}
},
{0,
{"while",0,0,"while","while ( <?""Condition""> ) do
	<?>
enddo;"}
},
{0,
{"for",0,0,"for","for <?""Counter""> to <?""Bound""> do
	<?>
enddo;"}
},
{0,
{"for each",0,0,"for[ each]","for each <?""Var""> in <?""Collection""> do
	<?>
enddo;"}
},
{0,
{"Procedure",0,0,"proc[edure]","Procedure <?""Name""> ()
	<?>
EndProcedure"}
},
{0,
{"Function",0,0,"func[tion]","Function <?""Name""> ()
	<?>
EndFunction"}
},
{0,
{"Try",0,0,"try","try
	<?>
except

endtry;"}
},
{0,
{"Query",0,1,"","s = ""
|select
|from
|where
|"";
q = new Query ( s );
table = q.Execute ().Unload ();
"}
},
{0,
{"comment all 82",0,0,"****","// *****************************************
// *********** Form events

// *****************************************
// *********** Group

// *****************************************
// *********** Variables Initialization
"}
},
{0,
{"Select Directive",0,1,"&","&<?""Choose a compilation directive"", VariantChoice, ""AtClient"", ""AtClient"", ""AtServer"", ""AtServer"", ""AtServerNoContext"", ""AtServerNoContext"", ""AtClientAtServer"", ""AtClientAtServer"", ""AtClientAtServerNoContext"", ""AtClientAtServerNoContext"">
"}
},
{0,
{"New",0,1,"new","new <?""Choose type"", VariantChoice, ""Structure"", ""Structure ()"", ""Map"", ""Map ()"", ""Array"", ""Array ()"", ""ValueList"", ""ValueList ()"", ""ValueTable"", ""ValueTable ()"", ""NotifyDescription"", ""NotifyDescription ( """", ThisObject )"">"}
},
{0,
{"Processor instruction",0,1,"#","#if ( <?""Choose a preprocessor instruction"", VariantChoice, ""Server"", ""Server"", ""Client"", ""Client"", ""ThinClient"", ""ThinClient"", ""WebClient"", ""WebClient"", ""ExternalConnection"", ""ExternalConnection"", ""ThickClientManagedApplication"", ""ThickClientManagedApplication"", ""ThickClientOrdinaryApplication"", ""ThickClientOrdinaryApplication"", ""MobileAppClient"", ""MobileAppClient""> ) then
	<?>
#endif"}
},
{0,
{"Message",0,1,"","params = new Structure ( ""Table"" );
params.Table = Ref.Metadata ().TabularSections.Items.Presentation ();
Common.Msg ( ""MessageID"", params, ""Items [""+ Format ( row.LineNumber - 1, ""NG=;NZ="" ) + ""].Quantity"", Ref, DataPath = ""Object"" );
"}
},
{0,
{"Decrease Tables",0,1,"","	p = new Structure ();
	p.Insert ( ""FilterColumns"", ""Item"" );
	funcParams = new Structure ( ""Company"", docFields.Company );
	if ( GetFunctionalOption ( ""UseChars"", funcParams ) ) then
		p.FilterColumns = p.FilterColumns + "", Characteristic"";
	endif; 
	if ( GetFunctionalOption ( ""UseSeries"", funcParams ) ) then
		p.FilterColumns = p.FilterColumns + "", Series"";
	endif; 
	p.Insert ( ""KeyColumn"", ""Quantity"" );
	p.Insert ( ""KeyColumnAvailable"", ""QuantityBalance"" );
	p.Insert ( ""DecreasingColumns"", ""Cost"" );
	p.Insert ( ""DecreasingColumns2"", ""Sum"" );
	p.Insert ( ""AddInTable1FromTable2"", ""SalesAccount, CostAccount, Warehouse"" );
	resultTable = Collections.DecreaseTable ( balancesTable, itemsTable, p );
"}
},
{0,
{"Open a report form (with parameters)",0,1,"","params = new Structure ();
params.Insert ( """", );
OpenForm ( ""Report.<?""Choose a report"", Report>.<?""Choose form"", VariantChoice, ""Form"", ""Form"", ""SettingsForm"", ""SettingsForm"", ""VariantForm"", ""VariantForm"", ""Generic"", ""Form."">"", params );"}
},
{0,
{"Open a document form (with parameters)",0,1,"","params = new Structure ();
params.Insert ( ""Owner"", );
OpenForm ( ""Document.<?""Choose a document"", Document>.<?""Choose form"", VariantChoice, ""Item form"", ""ObjectForm"", ""List form"", ""ListForm"", ""Choice form"", ""ChoiceForm"", ""Generic"", ""Form."">"", params );"}
},
{0,
{"Open a catalog form (with parameters)",0,1,"","params = new Structure ();
params.Insert ( ""Owner"", );
OpenForm ( ""Catalog.<?""Choose Catalog"", Catalog>.<?""Choose form"", VariantChoice, ""Item form"", ""ObjectForm"", ""List form"", ""ListForm"", ""Choice form"", ""ChoiceForm"", ""Group form"", ""FolderForm"", ""Group choice form"", ""FolderChoiceForm"", ""Generic"", ""Form."">"", params );"}
},
{0,
{"Type check",0,1,"","if ( TypeOf ( <?""Expression for type check""> ) = Type ( ""<?""Choose type"", TypeChoice>"" ) then

	<?>

endif;
"}
},
{0,
{"Format",0,1,"Format","Format ( <?>, ""<?, FormatString>"" )"}
},
{0,
{"++",0,0,"++","<?""Variable""> = <?""Variable""> + 1;
"}
},
{0,
{"--",0,0,"--","<?""Variable""> = <?""Variable""> - 1;
"}
},
{0,
{"Accounting movement",0,1,"","params = AccountingRegisters.General.GetStructure ();
params.Date = ;
params.Company = ;
params.Account = ;
params.RecordType = AccountingRecordType.Debit;
params.OperationType = Enums.OperationTypesAccounting.AdditionalExpenses;
params.Content = ;
params.Sum = ;
params.Quantity = ;
params.Currency = ;
params.SumCurrency = ;
params.ExtDim1 = ;
params.ExtDim1Type = ;
params.ExtDim2 = ;
params.ExtDim2Type = ;
params.ExtDim3 = ;
params.ExtDim3Type = ;
params.LinkedDocument = ;
params.Recordset = This.RegisterRecords.General;
AccountingRegisters.General.AddRecord ( params );"}
},
{0,
{"CombineTables",0,1,"","	params = new Structure ();
	params.Insert ( ""FilterColumns"", ""Item"" );
	funcParams = new Structure ( ""Company"", docFields.Company );
	if ( GetFunctionalOption ( ""UseChars"", funcParams ) ) then
		params.FilterColumns = params.FilterColumns + "", Characteristic"";
	endif; 
	if ( GetFunctionalOption ( ""UseSeries"", funcParams ) ) then
		params.FilterColumns = params.FilterColumns + "", Series"";
	endif; 
	params.Insert ( ""DistribColumnsTable1"", ""Amount, AmountVAT"" );
	params.Insert ( ""DistribColumnsTable2"", ""Cost"" ); // Optional
	params.Insert ( ""KeyColumn"", ""Quantity"" ); // Quantity must be in Table2
	params.Insert ( ""AssignСоlumnsTаble1"", ""Expense, Division"" ); // Optional
	params.Insert ( ""AssignColumnsTable2"", ""Item"" ); // Optional
	params.Insert ( ""DistributeTables"" ); // Optional
	params.Insert ( ""IncludeUndistributedTable"" ); // Optional
	// The ""expenses"" will include to ""items"".
	// After executing this process, the ""expenses"" will contain undistributed rows
	unresolvedRound = new ValueTable ();
	resultTable = Collections.CombineTables ( expenses, items, params, unresolvedRound );
	// Trace unresolvedRound...
	"}
},
{0,
{"Get Data in Object",0,1,"","var Env;

Procedure getData ()
	
	SQL.Init ( Env );
	selectXXX ();
	SQL.Prepare ( Env );
	Env.Query.SetParameter ( ""Ref"", Env.Ref );
	SQL.Unload ( Env, Env.Query.ExecuteBatch () );

EndProcedure 

Procedure selectXXX ()
	
	str = ""
	|// ^XXX
	|select null
	|"";
	Env.Selection.Add ( str );
	
EndProcedure
"}
},
{0,
{"Get Data in Module",0,1,"","Procedure someProcedure ()
	
	env = new Structure ( ""Ref"", Ref );
	getData ( env );
	
EndProcedure

Procedure getData ( Env )
	
	SQL.Init ( Env );
	selectXXX ( Env );
	SQL.Prepare ( Env );
	Env.Query.SetParameter ( ""Ref"", Env.Ref );
	SQL.Unload ( Env, Env.Query.ExecuteBatch () );

EndProcedure 

Procedure selectXXX ( Env )
	
	str = ""
	|// ^XXX
	|select null
	|"";
	Env.Selection.Add ( str );
	
EndProcedure
"}
},
{0,
{"Posting",0,1,"","	env = new Structure ();
	env.Insert ( ""Ref"", Ref );
	env.Insert ( ""RegisterRecords"", RegisterRecords );
	env.Insert ( ""AdditionalProperties"", AdditionalProperties );
	Cancel = not Documents.XXXXXXXX.MakeMovements ( env );
"}
},
{0,
{"Printing",0,1,"","#region PickList

Function Print ( Params, Env ) export
	
	////if ( not CanPrint ( Params.PrintObject ) ) then
	////	Output.InternalOrderPrintError ();
	////	return false;
	////endif; 
	////if ( Params.FormName = ""Request"" ) then
	////	return printRequest ( Params, Env );
	////else
	////	return printMRN ( Params, Env );
	////endif; 
	
	
	PrintSrv.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	initPrint ( Env );
	putHeader ( Params, Env );
	putTable ( Params, Env );
	putFooter ( Params, Env );
	return true;
	
EndFunction

Procedure setPageSettings ( Params )
	
	Params.TabDoc.PageOrientation = PageOrientation.Portrait;
	Params.TabDoc.FitToPage = true;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	Env.Q.Text = getDataSql ();
	Env.Q.SetParameter ( ""Ref"", Params.PrintObject );
	Env.Insert ( ""Data"", Env.Q.ExecuteBatch () );
	PostingDocuments.UnloadQueryResults ( Env, Env.Data, Env.Q );

EndProcedure 

Function getDataSql ()
	
	str = ""
	|// ~Fields
	|select Documents.Number as Number
	|from Document.InternalOrder as Documents
	|where Documents.Ref = &Ref
	|;
	|// ^Items
	|select 0 as Table, Items.LineNumber as LineNumber, Items.Amount as Amount, Items.Item.Description as Item, Items.Package.Description as Measure, Items.QuantityPack as Quantity,
	|	Items.Standard as Standard, Items.Note as Note, Items.Price as Price
	|from Document.InternalOrder.Inventory as Items
	|where Items.Ref = &Ref
	|union all
	|select 1, Services.LineNumber, Services.Amount, Services.Description, null, Services.Quantity, """""""", Services.Note, Services.Price
	|from Document.InternalOrder.Services as Services
	|where Services.Ref = &Ref
	|order by Table, LineNumber
	|"";
	return str;
	
EndFunction 

Procedure initPrint ( Env )
	
	Env.Insert ( ""Header"", Env.T.GetArea ( ""Header"" ) );
	Env.Insert ( ""Row"", Env.T.GetArea ( ""Row"" ) );
	Env.Insert ( ""Footer"", Env.T.GetArea ( ""Footer"" ) );

EndProcedure 

Procedure putHeader ( Params, Env )
	
	Env.Header.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( Env.Header );
	PrintSrv.RepeatOnRowPrint ( Params.TabDoc );
	
EndProcedure 

Procedure putTable ( Params, Env )
	
	area = Env.Row;
	ln = 0;
	for each row in Env.Items do
		ln = ln + 1;
		area.Parameters.Fill ( row );
		area.Parameters.Description = getDescription ( row );
		area.Parameters.LN = ln;
		Params.TabDoc.Put ( area );
	enddo; 
	
EndProcedure 

Function getDescription ( Row )
	
	str = row.Item;
	if ( row.Standard <> """" ) then
		str = str + "", Standard / Стандарт:"" + row.Standard;
	endif; 
	if ( row.Note <> """" ) then
		str = str + "", Note / Примечание:"" + row.Note;
	endif; 
	return str;
	
EndFunction 

Procedure putFooter ( Params, Env )
	
	footer = Env.Footer;
	footer.Parameters.Amount = Env.Items.Total ( ""Amount"" );
	Params.TabDoc.Put ( footer );
	
EndProcedure 

#endregion
"}
}
}
}