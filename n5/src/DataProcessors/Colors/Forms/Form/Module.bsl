// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	buildColors ();
	
EndProcedure

&AtServer
Procedure buildColors ()
	
	HTML = "
	|<html xmlns=""http://www.w3.org/1999/xhtml"">
	|<head>
	|<style>
	|	*{
	|		font-size: 10pt;
	|		font-family: sans-serif;
	|		overflow-y:auto;
	|	}
	|	.cell {
	|		cursor: pointer;
	|		border-style: solid;
	|		border-width: thin;
	|		border-color: white;
	|		text-align: center;
	|	}
	|		.cell:hover {
	|			border-color: black;
	|			back-color: black;
	|		}
	|</style>
	|</head>
	|<body style=""padding: 0px; margin: 0px;"">
	|" + getColorsTable () + "
	|</body>
	|</html>
	|";
	
EndProcedure 

&AtServer
Function getColorsTable ()
	
	obj = FormAttributeToValue ( "Object" );
	t = obj.GetTemplate ( "Template" );
	cellWidth = String ( Int ( 100 / t.TableWidth ) ) + "%";
	colorNumber = 1;
	twoColors = Parameters.TwoColors;
	currentColorName = Colors.Get ( Parameters.CurrentColor );
	currentColorStyle = "; border-color:red; border-style: dashed; border-width: 2px;";
	Palette = new Structure ();
	s = "
	|<table style=""width: 100%; height: 100%"">";
	for i = 1 to t.TableHeight do
		s = s + "<tr>";
		for j = 1 to t.TableWidth do
			cell = t.Area ( i, j, i, j );
			backColor = Colors.Get ( cell.BackColor );
			Palette.Insert ( backColor, cell.BackColor );
			if ( twoColors ) then
				textColor = Colors.Get ( cell.TextColor );
				s = s + "<td class=""cell"" id=""" + backColor + "#" + textColor + """ style=""width: " + cellWidth + "; background-color: " + backColor + "; color:" + textColor + ? ( backColor = currentColorName, currentColorStyle, "" ) + """>" + colorNumber + "</td>";
				Palette.Insert ( textColor, cell.TextColor );
			else
				s = s + "<td class=""cell"" id=""" + backColor + """ style=""width: " + cellWidth + "; background-color: " + backColor + ? ( backColor = currentColorName, currentColorStyle, "" ) + """>&nbsp;</td>";
			endif; 
			colorNumber = colorNumber + 1;
		enddo; 
		s = s + "</tr>";
	enddo; 
	s = s + "
	|</table>";
	return s;
	
EndFunction 

// *****************************************
// *********** Group Form

&AtClient
Procedure HTMLOnClick ( Item, EventData, StandardProcessing )
	
	StandardProcessing = false;
	colorID = EventData.Element.id;
	if ( colorID = "" ) then
		return;
	endif; 
	chooseColor ( colorID );
	
EndProcedure

&AtClient
Procedure chooseColor ( ColorID )
	
	if ( Parameters.TwoColors ) then
		colorsPare = Conversion.StringToArray ( ColorID, "#" );
		selectedColors = new Structure ( "BackColor, TextColor", getColor ( colorsPare [ 0 ] ), getColor ( colorsPare [ 1 ] ) );
		NotifyChoice ( selectedColors );
	else
		NotifyChoice ( getColor ( ColorID ) );
	endif; 
	
EndProcedure 

&AtClient
Function getColor ( ColorName )
	
	for each item in Palette do
		if ( item.Key = ColorName ) then
			return item.Value;
		endif; 
	enddo; 
	
EndFunction 
