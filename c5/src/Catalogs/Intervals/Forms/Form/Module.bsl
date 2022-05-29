
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setMaxPeriod ();

EndProcedure

&AtServer
Procedure setMaxPeriod ()
	
	MaxPeriod = Pow ( 10,
		Metadata.Catalogs.Intervals.TabularSections.Intervals.Attributes.Finish.Type.NumberQualifiers.Digits ) - 1;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	sort ( CurrentObject );

EndProcedure

&AtServer
Procedure sort ( CurrentObject )
	
	CurrentObject.Intervals.Sort ( "Start, Finish" );

EndProcedure

// *****************************************
// *********** Intervals

&AtClient
Procedure IntervalsOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow ) then
		initRow ();
		setPresentation ();
	endif;

EndProcedure

&AtClient
Procedure initRow ()

	row = Items.Intervals.CurrentData;
	index = Object.Intervals.IndexOf ( row );
	if ( index = 0 ) then
		row.Start = 1;
		augmentFinish ();
	else
		lastRow = Object.Intervals [ index - 1 ];
		finish = lastRow.Finish;
		row.Start = finish + 1;
		row.Finish = row.Start + ( lastRow.Finish - lastRow.Start );
	endif;

EndProcedure

&AtClient
Procedure augmentFinish ()
	
	row = Items.Intervals.CurrentData;
	if ( row.Finish = 0 ) then
		row.Finish = MaxPeriod;
	endif;

EndProcedure

&AtClient
Procedure IntervalsStartOnChange ( Item )
	
	setPresentation ();

EndProcedure

&AtClient
Procedure setPresentation ()
	
	row = Items.Intervals.CurrentData;
	if ( row.Finish = MaxPeriod ) then
		presentation = "> " + Format ( Max ( row.Start - 1, 0 ), "NZ=;NG=" );
	else
		presentation = Format ( row.Start, "NZ=;NG=" ) + " - " + Format ( row.Finish, "NG=;NZ=" );
	endif;
	row.Presentation = presentation;

EndProcedure

&AtClient
Procedure IntervalsFinishOnChange ( Item )
	
	augmentFinish ();
	setPresentation ();

EndProcedure
