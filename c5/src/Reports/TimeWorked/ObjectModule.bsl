#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure AfterOutput () export
	
	highlightLabels ();

EndProcedure

Procedure highlightLabels ()
	
	drawings = Params.Result.Drawings;
	contrastColor = new Color ( 255, 255, 255 );
	for each draw in drawings do
		draw.Object.LabelTextColor = contrastColor;
	enddo; 
	
EndProcedure 

#endif