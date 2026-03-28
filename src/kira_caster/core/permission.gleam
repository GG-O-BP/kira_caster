pub type Role {
  Broadcaster
  Moderator
  Subscriber
  Viewer
}

pub type Permission {
  UseCommand(name: String)
  ModerateChat
  ManagePlugins
}

pub type PermissionError {
  Unauthorized(required: Role, actual: Role)
}

pub fn role_level(role: Role) -> Int {
  case role {
    Broadcaster -> 100
    Moderator -> 50
    Subscriber -> 20
    Viewer -> 10
  }
}

pub fn has_permission(user_role: Role, required_role: Role) -> Bool {
  role_level(user_role) >= role_level(required_role)
}

pub fn check(
  user_role: Role,
  required_role: Role,
) -> Result(Nil, PermissionError) {
  case has_permission(user_role, required_role) {
    True -> Ok(Nil)
    False -> Error(Unauthorized(required: required_role, actual: user_role))
  }
}
