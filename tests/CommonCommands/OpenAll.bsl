// Open All Objects

Call ( "Common.Init" );
CloseAll ();

interface = MainWindow.GetCommandInterface ();
sections = interface.FindObject ( , "Sections panel");
if sections = undefined then
    Stop ( "Please, set command interface in order to show sections panel!" );
endif;

tested = new Map ();
sections = sections.GetChildObjects ();
group = Type ( "TestedCommandInterfaceGroup" );
IgnoreErrors = true;
for each section in sections do
    section.Click ();
    menu = interface.FindObject ( , "Functions menu" );
    commands = menu.FindObjects ();    
    for each command in commands do
        if Type ( command ) = group then
            continue;
        endif;    
        ref = command.URL;
        if true = tested [ ref ] then
            continue;
        endif;
        tested [ ref ] = true;
        try
            command.Click ();
            error = App.GetCurrentErrorInfo ();
		except
            error = ErrorInfo ();
		endtry;
        if ( error <> undefined ) then
            LogError ( "" + section + " / " + command.TitleText + ":" + error.Description );
        endif;
        CloseAll ();
        section.Click ();
    enddo;
enddo;
section.Click ();
IgnoreErrors = false;