StandardProcessing = false;

// Unload metatada for preparing initial image
// Set Russian script language setting in the source configuration before use this scenario

cmd = """C:\Program Files (x86)\1cv8\common\1cestart.exe"" /S""localhost:1641\cont5init"" /N""Администратор"" /Z""0123456789""";
cmd = cmd + " /TESTCLIENT -TPort" + Format ( AppData.Port, "NG=" ) + " /Execute ""C:\Exchange\MD83Exp.epf""";
RunApp ( cmd );
Pause ( 5 );
Connect ();
With ( "Выгрузка описания *" );
Set ( "#ИмяФайлаВыгрузки", "c:\Users\Dmitry\desktop\cont5meta.xml" );

if ( Fetch ( "#ВыгружатьДвиженияДокументов" ) = "False" ) then
	Click ( "#ВыгружатьДвиженияДокументов" );
endif;

Click ( "#Выгрузить" );
