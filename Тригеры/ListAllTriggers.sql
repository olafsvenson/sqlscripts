select OBJECT_NAME(triggers.parent_id) as [object_name],
	triggers.name,
	triggers.parent_class_desc,
	triggers.type_desc,
	triggers.is_disabled,
	triggers.is_instead_of_trigger,
	OBJECT_DEFINITION(triggers.object_id)
	as trigger_definition
	from sys.triggers