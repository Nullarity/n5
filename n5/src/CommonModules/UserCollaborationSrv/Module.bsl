
Procedure Send ( Reference, Text, Receiver ) export
	
	context = new CollaborationSystemConversationContext ( GetUrl ( Reference ) );
	filter = new CollaborationSystemConversationsFilter ();
	filter.ConversationContext = context;
	filter.ContextConversation = true;
	filter.CurrentUserIsMember = false;
	dialogs = CollaborationSystem.GetConversations ( filter );
	if ( dialogs.Count () = 0 ) then
		dialog = CollaborationSystem.CreateConversation ();
		dialog.ConversationContext = context;
		dialog.Title = Reference;
		dialog.Write ();
	else
		dialog = dialogs [ 0 ];
	endif; 
	message = CollaborationSystem.CreateMessage ( dialog.ID );
	message.Text = Text;
	user = InfoBaseUsers.FindByName ( DF.Pick ( Receiver, "Description" ) );
	id = CollaborationSystem.GetUserID ( user.UUID );
	message.Recipients.Add ( id );
	message.Write ();
	
EndProcedure

