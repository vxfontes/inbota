package handler

// APIHandlers groups HTTP handlers for the API.
type APIHandlers struct {
	Flags         *FlagsHandler
	Subflags      *SubflagsHandler
	ContextRules  *ContextRulesHandler
	Inbox         *InboxHandler
	Tasks         *TasksHandler
	Reminders     *RemindersHandler
	Events        *EventsHandler
	ShoppingLists *ShoppingListsHandler
	ShoppingItems *ShoppingItemsHandler
}
