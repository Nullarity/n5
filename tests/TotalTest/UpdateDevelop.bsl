// Updates c5, develop configuration

PinApplication ( "c5" );
SetVersion ( "Develop" );
p = Call ( "Tester.Execute.Params" );
p.Insert ( "Application", "c5" );
p.Insert ( "Version", "Develop" );
p.Insert ( "Server", "TestServer" );
p.Insert ( "ServerIBName", "c5" );
p.Insert ( "IBName", "c5, develop" );
p.Insert ( "IBUser", "root" );
p.Restore = "C:\Users\Administrator\Desktop\Testc5\init.dt";
p.Insert ( "RepoUser", "tester" );
p.Insert ( "RepoPassword", "e1egance" );
p.Insert ( "RepoAddress", "tcp://server:1742/c5Develop" );
p.UpdateOnly = true;
Call ( "Tester.Execute", p );
