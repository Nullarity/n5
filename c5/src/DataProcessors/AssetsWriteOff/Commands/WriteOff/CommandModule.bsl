
&AtClient
Procedure CommandProcessing ( List, CommandExecuteParameters )
	
	p = Print.GetParams ();
	p.Manager = "DataProcessors.AssetsWriteOff";
	p.Objects = List;
	lang = CurrentLanguage ();
	if ( lang = "en" ) then
		name = "WriteOffEn";
	else
		name = "WriteOff";
	endif;
	p.Key = name;
	p.Name = name;
	Print.Print ( p );
	
EndProcedure
