Function VersionLess ( val Version ) export
	
	#if ( Server or ExternalConnection ) then
		si = new SystemInfo ();
		platform = si.AppVersion;
	#else
		platform = FrameworkVersion;
	#endif
	return firstSmaller ( platform, Version );
	
EndFunction

Function firstSmaller ( Platform, Version )
	
	machine = StrSplit ( Platform, "." );
	i = 0;
	for each testing in StrSplit ( Version, "." ) do
		if ( Number ( testing ) > Number ( machine [ i ] ) ) then
			return true;
		endif;
		i = i + 1;
	enddo;
	return false;
	
EndFunction

&AtServer
Function CompatibilityLess ( Version ) export
	
	compatibility = getCompatibility ();
	return firstSmaller ( compatibility, Version );
	
EndFunction

&AtServer
Function getCompatibility ()
	
	compatibility = Metadata.CompatibilityMode;
	if ( compatibility = Metadata.ObjectProperties.CompatibilityMode.DontUse ) then
		si = new SystemInfo ();
		version = si.AppVersion;
	else
		s = String ( compatibility );
		for each item in StrSplit ( s, "0123456789" ) do
			s = StrReplace ( s, item, "." );
		enddo;
		version = Mid ( s, 2 );
	endif;
	return version;
	
EndFunction

&AtClient
Function IsLinux () export
	
	info = new SystemInfo ();
	type = info.PlatformType;
	return type = PlatformType.Linux_x86
	or type = PlatformType.Linux_x86_64;
	
EndFunction

&AtClient
Function IsWindows () export
	
	info = new SystemInfo ();
	type = info.PlatformType;
	return type = PlatformType.Windows_x86
	or type = PlatformType.Windows_x86_64;
	
EndFunction