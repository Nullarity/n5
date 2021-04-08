Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "Width", 0 );
	p.Insert ( "Height", 0 );
	p.Insert ( "ShowText", true );
	p.Insert ( "FontSize", 12 );
	p.Insert ( "Angle", 0 );
	p.Insert ( "Type", 1 );
	p.Insert ( "Pixelation", GetCommonTemplate ( "BarcodeBox" ).Drawings.Box100px.Height / 100 );
	p.Insert ( "Barcode" );
	return p;
	
EndFunction 

Function GetPicture ( P ) export
	
	library = BarcodeLibrary.Attach ();
	if ( library = undefined ) then
		raise Output.BarcodeAttachError ();
	endif;
	setType ( library, P );
	library.Width = Round ( P.Width / P.Pixelation );
	library.Height = Round ( P.Height / P.Pixelation );
	library.ПрозрачныйФон = true;
	library.ОтображатьТекст = P.ShowText;
	library.ЗначениеКода = P.Barcode;
	library.УголПоворота = 0;
	if ( library.Ширина < library.МинимальнаяШиринаКода ) then
		library.Ширина = library.МинимальнаяШиринаКода;
	endif;
	if ( library.Высота < library.МинимальнаяВысотаКода ) then
		library.Высота = library.МинимальнаяВысотаКода;
	endif;
	if ( P.ShowText
		and P.FontSize > 0
		and P.FontSize <> library.РазмерШрифта ) then
		library.РазмерШрифта = P.FontSize;
	endif;
	data = library.ПолучитьШтрихкод ();
	if ( data = undefined ) then
		return undefined;
	else
		return new Picture ( data );
	endif;

EndFunction

Procedure setType ( Library, P )
	
	if ( P.Type = 99 ) then
		type = getType ( P.Barcode );
		if ( type = "EAN8" ) then
			Library.ТипКода = 0;
		elsif ( type = "EAN13" ) then
			Library.ТипКода = 1;
			Library.СодержитКС = StrLen ( P.Barcode ) = 13;
		elsif ( type = "EAN128" ) then
			Library.ТипКода = 2;
		elsif ( type = "CODE39" ) then
			Library.ТипКода = 3;
		elsif ( type = "CODE128" ) then
			Library.ТипКода = 4;
		elsif ( type = "ITF14" ) then
			Library.ТипКода = 11;
		else
			Library.АвтоТип = true;
		endif;
	else
		Library.АвтоТип = false;
		Library.ТипКода = P.Type;
	endif;
	
EndProcedure 

Function getType ( Barcode )
	
	type = "";	
	len = StrLen ( Barcode );
	if ( len = 0 ) then
		return type;
	endif;
	amount = 0;
	if ( len = 14 ) then // ITF14
		coef = 1; 
		for i = 1 По 13 do
			code = CharCode ( Barcode, i );
			if ( code < 48 or code > 57 ) then
				break;
			endif;
			amount = amount + coef * ( code - 48 );
			coef = 4 - coef;
		enddo;
		amount = ( 10 - amount % 10 ) % 10;
		if ( CharCode ( Barcode, 14 ) = amount + 48 ) then
			type = "ITF14";
 		endif;
	elsif ( len = 13 ) then // EAN13
		EAN13 = true;
		coef = 1;
		for i = 1 to 12 do
			code = CharCode ( Barcode, i );
			if ( code < 48 or code > 57 ) then
				EAN13 = false;
				break;
			endif;
			amount = amount + coef * ( code - 48 );
			coef = 4 - coef;
		enddo;
		amount = ( 10 - amount % 10 ) % 10;
		control = Char ( amount + 48 );
		if ( EAN13
			and ( control = Right ( Barcode, 1 ) ) ) then
			type = "EAN13";
		endif;
	elsif ( len = 8 ) then // EAN8
		EAN8 = true;
		coef = 3;
		for i = 1 to 7 do
			code = CharCode ( Barcode, i );
			if ( code < 48 or code > 57 ) then
				EAN8 = false;
				break;
			endif;
			amount = amount + coef * (code - 48);
			coef = 4 - coef;
		enddo;
		amount = ( 10 - amount % 10 ) % 10;
		if ( EAN8
			and ( CharCode ( Barcode, 8 ) = amount + 48 ) ) then
			type = "EAN8";
		endif;
	endif;
	if ( type= "" ) then // CODE39
		CODE39 = true;
		for i = 1 to len do
			code = CharCode ( Barcode, i );
			if ( code <> 32
				and ( code < 36 or code > 37 )
				and ( code <> 43 )
				and ( code < 45 or code > 57 )
				and ( code < 65 or code > 90 ) ) then
				CODE39 = false;
				break;
			endif;
		enddo;
		if ( CODE39 ) then
			type = "CODE39";
		endif                                                     
	endif;
	if ( type = "" ) then // CODE128
		CODE128 = true;
		for i = 1 to len do
			code = CharCode ( Barcode, i );
			if ( code > 127 ) then
				CODE128 = false;
				break;
			endif;
		enddo;
		if ( CODE128 ) then
			type = "CODE128";
		endif                                                     
	endif;
	if ( type= "CODE128" ) then // EAN128
		if ( CharCode ( Barcode, 1 ) = 40 ) then
			type = "EAN128";
		endif;
	endif;
	return type;
	
EndFunction
