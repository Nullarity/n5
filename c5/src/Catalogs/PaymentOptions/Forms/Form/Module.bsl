// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	sortPeriods ( CurrentObject );
	
EndProcedure

&AtServer
Procedure sortPeriods ( CurrentObject )
	
	table = CurrentObject.Discounts;
	table.Sort ( "Edge" );
	i = table.Count () - 1;
	while ( i > 0 ) do
		row = table [ i ];
		row.Begin = 1 + table [ i - 1 ].Edge;
		i = i - 1;
	enddo; 
	if ( i > 0 ) then
		table [ 0 ].Begin = 0;
	endif; 
	
EndProcedure 
