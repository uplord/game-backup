extends Node
## Non-owning lookup. Register nodes owned by the scene tree.
var _services: Dictionary = {}

func register_service(service_id: StringName, service: Node) -> bool:
    if service_id == &"" or not is_instance_valid(service):
        push_error("ServiceRegistry: invalid service registration")
        return false
    if _services.has(service_id) and is_instance_valid(_services[service_id]):
        push_warning("ServiceRegistry: duplicate service %s" % service_id)
        return false
    _services[service_id] = service
    EventBus.service_registered.emit(service_id)
    return true

func get_service(service_id: StringName) -> Node:
    var service: Node = _services.get(service_id) as Node
    if not is_instance_valid(service):
        _services.erase(service_id)
        return null
    return service

func unregister_service(service_id: StringName, service: Node = null) -> void:
    if not _services.has(service_id):
        return
    if service != null and _services[service_id] != service:
        return
    _services.erase(service_id)
    EventBus.service_unregistered.emit(service_id)

func clear_services() -> void:
    for service_id in _services.keys():
        unregister_service(service_id)
