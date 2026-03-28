import kira_caster/core/permission

pub fn broadcaster_has_all_permissions_test() {
  assert permission.has_permission(permission.Broadcaster, permission.Viewer)
    == True
  assert permission.has_permission(permission.Broadcaster, permission.Moderator)
    == True
}

pub fn moderator_has_viewer_permission_test() {
  assert permission.has_permission(permission.Moderator, permission.Viewer)
    == True
}

pub fn viewer_lacks_moderator_test() {
  assert permission.has_permission(permission.Viewer, permission.Moderator)
    == False
}

pub fn same_role_has_permission_test() {
  assert permission.has_permission(permission.Subscriber, permission.Subscriber)
    == True
}

pub fn check_returns_ok_test() {
  let assert Ok(Nil) = permission.check(permission.Moderator, permission.Viewer)
}

pub fn check_returns_error_test() {
  let assert Error(permission.Unauthorized(
    required: permission.Moderator,
    actual: permission.Viewer,
  )) = permission.check(permission.Viewer, permission.Moderator)
}
