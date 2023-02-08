&AtServer
Function Exists ( Name ) export
	
	file = new File ( Name );
	return file.Exist ();
	
EndFunction 

Function GetFileName ( Path ) export

	separator = GetPathSeparator ();
	a = StrFind ( Path, separator, SearchDirection.FromEnd );
	return ? ( a = 0, Path, Mid ( Path, a + 1 ) );
	
EndFunction

Function GetExtensionIndex ( File ) export
	
	if ( File = "" ) then
		return 0;
	endif;
	ext = "." + Lower ( FileSystem.GetExtension ( File ) ) + ";";
	if Find ( ".dt;.1cd;.cf;.cfu;", ext) <> 0 then
		return 6;
	elsif ext = ".mxl;" then
		return 8;
	elsif Find ( ".txt;.log;.ini;", ext) <> 0 then
		return 10;
	elsif ext = ".epf;" then
		return 12;
	elsif Find ( ".ico;.wmf;.emf;",ext ) <> 0 then
		return 14;
	elsif Find ( ".htm;.html;.url;.mht;.mhtml;",ext ) <> 0 then
		return 16;
	elsif Find ( ".doc;.dot;.rtf;",ext ) <> 0 then
		return 18;
	elsif Find ( ".xls;.xlw;",ext ) <> 0 then
		return 20;
	elsif Find ( ".ppt;.pps;",ext ) <> 0 then
		return 22;
	elsif Find ( ".vsd;",ext ) <> 0 then
		return 24;
	elsif Find ( ".mpp;",ext ) <> 0 then
		return 26;
	elsif Find ( ".mdb;.adp;.mda;.mde;.ade;",ext ) <> 0 then
		return 28;
	elsif Find ( ".xml;",ext ) <> 0 then
		return 30;
	elsif Find ( ".msg;",ext ) <> 0 then
		return 32;
	elsif Find ( ".zip;.rar;.arj;.cab;.lzh;.ace;",ext ) <> 0 then
		return 34;
	elsif Find ( ".exe;.com;.bat;.cmd;",ext ) <> 0 then
		return 36;
	elsif Find ( ".grs;",ext ) <> 0 then
		return 38;
	elsif Find ( ".geo;",ext ) <> 0 then
		return 40;
	elsif Find ( ".jpg;.jpeg;.jp2;.jpe;",ext ) <> 0 then
		return 42;
	elsif Find ( ".bmp;.dib;",ext ) <> 0 then
		return 44;
	elsif Find ( ".tif;.tiff;",ext ) <> 0 then
		return 46;
	elsif Find ( ".gif;",ext ) <> 0 then
		return 48;
	elsif Find ( ".png;",ext ) <> 0 then
		return 50;
	elsif Find ( ".pdf;",ext ) <> 0 then
		return 52;
	elsif Find ( ".odt;",ext ) <> 0 then
		return 54;
	elsif Find ( ".odf;",ext ) <> 0 then
		return 56;
	elsif Find ( ".odp;",ext ) <> 0 then
		return 58;
	elsif Find ( ".odg;",ext ) <> 0 then
		return 60;
	elsif Find ( ".ods;",ext ) <> 0 then
		return 62;
	elsif Find ( ".mp3;",ext ) <> 0 then
		return 64;
	elsif Find ( ".erf;",ext ) <> 0 then
		return 66;
	elsif Find ( ".docx;",ext ) <> 0 then
		return 68;
	elsif Find ( ".xlsx;",ext ) <> 0 then
		return 70;
	elsif Find ( ".pptx;",ext ) <> 0 then
		return 72;
	elsif Find ( ".p7s;",ext ) <> 0 then
		return 74;
	elsif Find ( ".p7m;",ext ) <> 0 then
		return 76;
	else
		return 4;
	endif;
	
EndFunction

Function GetBaseName ( File ) export

	dot = StrFind ( File, ".", SearchDirection.FromEnd );
	return ? ( dot = 0, File, Mid ( File, 1, dot - 1 ) );

EndFunction

Function GetFolder ( Path ) export

	// Do not use GetPathSeparator () bacause we do not know from where files come
	dot = StrFind ( Path, "/", SearchDirection.FromEnd );
	if ( dot = 0 ) then
		dot = StrFind ( Path, "\", SearchDirection.FromEnd );
	endif; 
	return ? ( dot = 0, Path, Mid ( Path, 1, dot - 1 ) );

EndFunction

&AtServer
Function SpreadsheetType ( TableType ) export
	
	if ( TableType = Enums.TableTypes.PDF ) then
		return SpreadsheetDocumentFileType.PDF;
	elsif ( TableType = Enums.TableTypes.XLS ) then
		return SpreadsheetDocumentFileType.XLS;
	elsif ( TableType = Enums.TableTypes.XLSX ) then
		return SpreadsheetDocumentFileType.XLSX;
	elsif ( TableType = Enums.TableTypes.DOCX ) then
		return SpreadsheetDocumentFileType.DOCX;
	elsif ( TableType = Enums.TableTypes.ODS ) then
		return SpreadsheetDocumentFileType.ODS;
	elsif ( TableType = Enums.TableTypes.MXL ) then
		return SpreadsheetDocumentFileType.MXL;
	endif; 
	
EndFunction 

&AtServer
Procedure CopyFolder ( Folder, Folder2, Subfolders = false ) export
	
	if ( not FileSystem.Exists ( Folder2 ) ) then
		CreateDirectory ( Folder2 );
	endif; 
	files = FindFiles ( Folder, "*", Subfolders );
	for each file in files do
		path = file.FullName;
		path2 = Folder2 + cutFolder ( path, Folder );
		if ( file.IsDirectory () ) then
			if ( Subfolders and not FileSystem.Exists ( path2 ) ) then
				CreateDirectory ( path2 );
			endif; 
			continue;
		else
			CopyFile ( path, path2 );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Function cutFolder ( Path, Folder )
	
	return Mid ( Path, StrLen ( Folder ) + 1 );
	
EndFunction 

&AtServer
Procedure ClearFolder ( Folder, All = false ) export
	
	if ( All ) then
		DeleteFiles ( Folder, "*" );
	else
		files = FindFiles ( Folder, "*" );
		for each file in files do
			path = file.FullName;
			if ( file.IsDirectory () ) then
				continue;
			else
				DeleteFiles ( path );
			endif; 
		enddo; 
	endif; 
	
EndProcedure 

Function GetExtension ( File ) export

	pos = 0;
	ext = File;
	while ( true ) do
		pos = Find ( ext, "." );
		if ( not pos ) then
			break;
		else
			ext = Mid ( ext, pos + 1 );
		endif;
	enddo;
	return ?( ext = File, "", Lower ( ext ) );

EndFunction

Function Printable ( File ) export
	
	s = "." + FileSystem.GetExtension ( File ) + ";";
	return Find ( ".m3u;.m4a;.mid;.midi;.mp2;.mp3;.mpa;.rmi;.wav;.wma;
	|3g2;.3gp;.3gp2;.3gpp;.asf;.asx;.avi;.m1v;.m2t;.m2ts;.m2v;.m4v;
	|mkv;.mov;.mp2v;.mp4;.mp4v;.mpe;.mpeg;.mts;.vob;.wm;.wmv;.wmx;.wvx;
	|7z;.zip;.rar;.arc;.arh;.arj;.ark;.p7m;.pak;.package;
	|app;.com;.exe;.jar;.dll;.res;.iso;.isz;.mdf;.mds;
	|cf;.dt;.epf;.erf;", s ) = 0;

EndFunction 

Function Picture ( File ) export
	
	if ( TypeOf ( File ) = Type ( "File" ) ) then
		ext = File.Extension;
	elsif ( File = "" ) then
		return false;
	else
		ext = FileSystem.GetExtension ( File );
	endif;
	s = ext + ";";
	return Find ( ".jpg;.jpeg;.jp2;.jpe;.bmp;.dib;.tif;.tiff;.gif;.png;", s ) > 0;

EndFunction 

Function OfficeDoc ( File ) export
	
	s = "." + FileSystem.GetExtension ( File ) + ";";
	return Find ( ".doc;.docx;.xls;.xlsx;.xlt;.xlsm;.xltm;.xlam;.ppt;.pptx;", s ) > 0;

EndFunction 

Function GoogleDoc ( File ) export
	
	s = "." + FileSystem.GetExtension ( File ) + ";";
	return Find ( ".pdf;", s ) > 0;

EndFunction 

Function HyperText ( File ) export
	
	s = "." + FileSystem.GetExtension ( File ) + ";";
	return Find ( ".htm;.html;", s ) > 0;

EndFunction 

Function PlainText ( File ) export
	
	s = "." + FileSystem.GetExtension ( File ) + ";";
	return Find ( ".txt;.bat;.cmd;.cpp;.cs;.css;.xml;.log;.ini;", s ) > 0;

EndFunction 

&AtServer
Function TableExtension ( TableType ) export
	
	if ( TableType = Enums.TableTypes.DOCX ) then
		return "docx";
	elsif ( TableType = Enums.TableTypes.PDF ) then
		return "pdf";
	elsif ( TableType = Enums.TableTypes.XLS ) then
		return "xls";
	elsif ( TableType = Enums.TableTypes.XLSX ) then
		return "xlsx";
	elsif ( TableType = Enums.TableTypes.MXL ) then
		return "mxl";
	elsif ( TableType = Enums.TableTypes.ODS ) then
		return "ods";
	endif; 
	
EndFunction 

&AtServer
Function DBFTempFile () export
	
	// File name should not exceed 8 characters
	value = Int ( ( CurrentUniversalDateInMilliseconds () / 1000 ) % 1000000000 );
	// Upper () is mandatory to keep consistency between xnix and windows.
	// because XBase.CreateFile will capitalize a name of the file anyway.
	return Upper ( Conversion.DecToHex ( value ) + ".dbf" );
	
EndFunction