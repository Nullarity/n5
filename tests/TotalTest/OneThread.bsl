// Test cost-sensitive scenarios
while ( stillWorking ( _.Job ) ) do
	Pause ( 30 );
enddo;
_.Folder = "DataProcessors.Cost";
list = Call ( "Tester.Scenarios", _ );
NewJob ( "Tester", list, , , , , , _.Job );

// Disconnect all after testing
for i = 1 to _.Agents do
	NewJob ( "tester", "TotalTest.DisconnectClients", , , "tc" + i );
enddo;

&AtServer
Function stillWorking ( Job )
	
	s = "
	|select top 1 1
	|from Document.Job as Jobs
	|	//
	|	// AgentJobs
	|	//
	|	join InformationRegister.AgentJobs as AgentJobs
	|	on AgentJobs.Job = Jobs.Ref
	|	and AgentJobs.Status in ( value ( Enum.JobStatuses.Pending ), value ( Enum.JobStatuses.Running ) )
	|where Jobs.Job = &Job
	|and not Jobs.DeletionMark
	|order by Jobs.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Job", Job );
	return not q.Execute ().IsEmpty ();
	
EndFunction
