#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var IsNew;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not HiringForm.CheckDoubles ( ThisObject ) ) then
		Cancel = true;
		return;
	endif;
	if ( outdated () ) then
		Cancel = true;
		return;
	endif;
	
EndProcedure

Function outdated ()
	
	if ( Date > CurrentSessionDate () ) then
		return false;
	endif;
	Output.SendingPayslipsIsOutdated ( , "Date", Ref );
	return true;
	
EndFunction

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	IsNew = IsNew ();
	removeTask ();
	if ( DataExchange.Load
		or DeletionMark ) then
		return;
	endif;
	
EndProcedure

Procedure removeTask ()
	
	if ( IsNew ) then
		return;
	endif; 
	Jobs.Remove ( Ref );
	
EndProcedure 
	
Procedure Posting ( Cancel, PostingMode )

	p = new Array ();
	p.Add ( Ref );
	job = ScheduledJobs.CreateScheduledJob ( Metadata.ScheduledJobs.SendingPayslips );
	job.UserName = DF.Pick ( Creator, "Description" );
	job.Parameters = p;
	job.Key = Ref.UUID ();
	sessionDate = CurrentSessionDate ();
	timeOffset = sessionDate - CurrentDate ();
	jobDate = Date - timeOffset;
	schedule = job.Schedule;
	schedule.BeginDate = jobDate;
	schedule.BeginTime = jobDate;
	job.Write ();
	
EndProcedure

#endif