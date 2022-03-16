// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing)
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		Constraints.ShowAccess ( ThisObject );
	endif; 
	Options.Company ( ThisObject, Object.Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Info Range1 Range2 FormShowRecords show filled ( Object.Ref );
	|FormPost GroupR1 GroupR2 show empty ( Object.Ref );
	|NewRanges enable filled ( Object.Range );
	|Range Splitter Number Company Date Memo lock filled ( Object.Ref )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		raise Output.DocumentCannotBeCopied ();
	endif;
	if ( not Object.Range.IsEmpty () ) then
		return;
	endif;
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;;
	
EndProcedure

&AtClientAtServerNoContext
Procedure readStart ( Form )
	
	range = Form.Object.Range;
	if ( range.IsEmpty () ) then
		Form.Start1 = 0;
	else
		Form.Start1 = 1 + getLast ( range );
	endif;
	
EndProcedure

&AtServerNoContext
Function getLast ( val Range )
	
	s = "
	|select isnull ( Ranges.Last, Catalog.Start - 1 ) as Last
	|from Catalog.Ranges as Catalog
	|	left join InformationRegister.Ranges as Ranges
	|	on Ranges.Range = Catalog.Ref
	|where Catalog.Ref = &Range
	|";
	q = new Query ( s );
	q.SetParameter ( "Range", Range );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, 0, table [ 0 ].Last );
	
EndFunction

&AtClientAtServerNoContext
Procedure adjustSplitter ( Form )
	
	object = Form.Object;
	splitter = object.Splitter;
	start1 = Form.Start1;
	finish = DF.Pick ( object.Range, "Finish" ) - 1;
	if ( splitter < start1
		or splitter > finish ) then
		object.Splitter = start1;
		setStart2 ( Form );
	endif;
	item = Form.Items.Splitter;
	item.MinValue = start1;
	item.MaxValue = finish;
	
EndProcedure

&AtClientAtServerNoContext
Procedure setStart2 ( Form )
	
	Form.Start2 = Form.Object.Splitter + 1;
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	initRanges ( CurrentObject );
	
EndProcedure

&AtServer
Procedure initRanges ( CurrentObject )
	
	splitter = Object.Splitter;
	CurrentObject.Range1 = newRange ( Object.Range1, Start1, splitter );
	CurrentObject.Range2 = newRange ( Object.Range2, Start2, DF.Pick ( Object.Range, "Finish" ) );
	
EndProcedure

&AtServer
Function newRange ( Range, Start, Finish )
	
	if ( Range.IsEmpty () ) then
		obj = Catalogs.Ranges.CreateItem ();
	else
		obj = Range.GetObject ();
	endif;
	source = Object.Range;
	FillPropertyValues ( obj, source, , "Code, Description, Parent, Owner" );
	obj.Start = Start;
	obj.Finish = Finish;
	obj.Creator = SessionParameters.User;
	obj.Memo = Output.SplitRangeMemo ();
	obj.Source = source;
	obj.Write ();
	return obj.Ref;
	
EndFunction

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( Modified ) then
		Cancel = true;
		Output.CloseDocumentConfirmation ( ThisObject );
	endif;

EndProcedure

&AtClient
Procedure CloseDocumentConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	Modified = false;
	Close ();
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure Post ( Command )
	
	Output.SplitRangeConfirmation ( ThisObject );
	
EndProcedure

&AtClient
Procedure SplitRangeConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	if ( CheckFilling () ) then
		Write ();
	endif;
	
EndProcedure

&AtClient
Procedure RangeStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	choose ( Item );

EndProcedure

&AtClient
Procedure choose ( Item )
	
	filter = new Structure ();
	filter.Insert ( "Date", Object.Date );
	OpenForm ( "Catalog.Ranges.Form.Balances", new Structure ( "Filter", filter ), Item );
	
EndProcedure

&AtClient
Procedure RangeOnChange ( Item )
	
	readStart ( ThisObject );
	adjustSplitter ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Range" );
	
EndProcedure

&AtClient
Procedure SplitterOnChange ( Item )
	
	setStart2 ( ThisObject );
	
EndProcedure

&AtClient
Procedure UpdateRanges ( Command )
	
	CurrentItem = Items.Splitter;
	
EndProcedure
