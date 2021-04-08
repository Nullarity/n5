
Function Attach () export
	
	completed = AttachAddIn ( Constants.BarcodesLibrary.Get (), "КартинкаШтрихкода", AddInType.Native );
	if ( completed ) then
		library = new ( "AddIn.КартинкаШтрихкода.Barcode" );
		if ( not library.ГрафикаУстановлена ) then
			return undefined;
		endif;
	else
		return undefined;
	endif;
	if ( library.НайтиШрифт ( "Tahoma" ) = true ) then
		library.Шрифт = "Tahoma";
	else
		count = library.КоличествоШрифтов - 1;
		for i = 0 to count do
			font = library.ШрифтПоИндексу ( i );
			if ( font <> undefined ) then
				library.Шрифт = font;
				break;
			endif;
		enddo;
	endif;
	library.РазмерШрифта = 12;
	return library;
	
EndFunction
