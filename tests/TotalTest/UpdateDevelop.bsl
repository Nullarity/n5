// Updates Cont5, develop configuration

PinApplication ( "Cont5" );
SetVersion ( "Develop" );
p = Call ( "Tester.Execute.Params" );
p.Insert ( "Application", "Cont5" );
p.Insert ( "Version", "Develop" );
p.Insert ( "Server", "TestServer" );
p.Insert ( "ServerIBName", "cont5" );
p.Insert ( "IBName", "Cont5, develop" );
p.Insert ( "IBUser", "root" );
p.Restore = "C:\Users\Administrator\Desktop\TestCont5\init.dt";
p.Insert ( "RepoUser", "tester" );
p.Insert ( "RepoPassword", "e1egance" );
p.Insert ( "RepoAddress", "tcp://server:1742/cont5Develop" );
p.UpdateOnly = true;
Call ( "Tester.Execute", p );
