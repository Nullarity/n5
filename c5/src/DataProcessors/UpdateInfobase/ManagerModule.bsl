#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

#region Help
// Intermediate release means that the following updates must be generated based on the last intermediate release.
// Explanation. Let’s say we have these changes in our application:
// Release 1.0.0.1. We create Catalog1 with Delivery string field.
// Release 1.0.1.1. We decide to change type of Delivery field from string to number.
// 					Thus, we rename Delivery to DeliveryRemove and create a new field Delivery as number type.
//					We also have to provide an update procedure in order to convert data
//					from DeliveryRemove to Delivery.
// Release 1.0.2.1. We remove DeliveryRemove field from the Catalog1.
//
// A couple of concerns here.
// An update 1.0.2.1 has to be formed on 1.0.1.1, otherwise user’s data will be lost.
// The direct update from 1.0.0.1 to 1.0.2.1 will instantly delete Delivery string field and create
// new Delivery number field. Therefore, updating procedures will give errors because of missing
// DeliveryRemove field from update 1.0.1.1.
//
// In order to make everything right, we should:
// Produce 1.0.2.1 release based on 1.0.1.1
// Declare 1.0.1.1 release as an intermediate: list.Add ( entry ( "1.0.1.1", true ) );
//
// Besides, take into account that before last Intermediate Update all entries exist for history only.
// Which means that actual update procedures are not required. Updates for such releases will never be executed.
//
// For more information please visit https://apps.rdbcode.com/time/6126BF58EE/#e1cib/data/Document.Document?ref=a0b23d9ac6d0cf84411392c61018ad17
#endregion
	
Procedure Exec ( Params, JobKey ) export
	
	SetPrivilegedMode ( true );
	obj = Create ();
	obj.Parameters = Params;
	obj.JobKey = JobKey;
	obj.Exec ();
	
EndProcedure 

Function GetReleases () export
	
	list = new Array ();
	list.Add ( entry ( "5.0.28.1", true ) );
	return list;
	
EndFunction

Function entry ( Release, Intermediate )
	
	return new Structure ( "Release, Version, Intermediate", Release, CoreLibrary.VersionToNumber ( Release ), Intermediate );
	
EndFunction

Function Required () export
	
	myVersion = MyVersion ();
	releases = GetReleases ();
	i = releases.Ubound ();
	if ( i = -1 ) then
		return false;
	else
		return myVersion < releases [ i ].Version;
	endif;
	
EndFunction

Function MyVersion () export
	
	release = Constants.Release.Get ();
	if ( release = "" ) then
		release = Metadata.Version;
		SetPrivilegedMode ( true );
		Constants.Release.Set ( release );
	endif;
	return CoreLibrary.VersionToNumber ( release );
	
EndFunction

Function TryStart () export
	
	BeginTransaction ();
	lock = new DataLock ();
	item = lock.Add ( "Constant.Updating" );
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	running = Constants.Updating.Get ();
	if ( running ) then
		RollbackTransaction ();
	else
		Constants.Updating.Set ( true );
		CommitTransaction ();
	endif;
	return not running;
	
EndFunction

#endif
