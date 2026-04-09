import gleam/dict.{type Dict}
import gleam/list
import kira_caster/core/permission.{type Role}
import kira_caster/logger
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/platform/cime/types.{type StreamingRole}

pub type RoleCache {
  RoleCache(
    roles: Dict(String, Role),
    subscribers: Dict(String, Bool),
    last_updated: Int,
  )
}

pub fn empty_cache() -> RoleCache {
  RoleCache(roles: dict.new(), subscribers: dict.new(), last_updated: 0)
}

/// Refresh the role cache from the API
pub fn refresh(
  cache: RoleCache,
  api: CimeApi,
  token: String,
  now: Int,
) -> RoleCache {
  let roles = case api.get_streaming_roles(token) {
    Ok(role_list) -> build_role_map(role_list)
    Error(_) -> {
      logger.warn("Failed to refresh streaming roles")
      cache.roles
    }
  }

  let subscribers = case api.get_subscribers(token, 0, 50) {
    Ok(sub_list) ->
      list.fold(sub_list, dict.new(), fn(acc, sub) {
        dict.insert(acc, sub.channel_id, True)
      })
    Error(_) -> {
      logger.warn("Failed to refresh subscribers")
      cache.subscribers
    }
  }

  RoleCache(roles:, subscribers:, last_updated: now)
}

/// Resolve a channel ID to a permission Role
pub fn resolve_role(cache: RoleCache, channel_id: String) -> Role {
  case dict.get(cache.roles, channel_id) {
    Ok(role) -> role
    Error(_) -> {
      case dict.get(cache.subscribers, channel_id) {
        Ok(True) -> permission.Subscriber
        _ -> permission.Viewer
      }
    }
  }
}

/// Check if cache needs refresh (older than 5 minutes)
pub fn needs_refresh(cache: RoleCache, now: Int) -> Bool {
  now - cache.last_updated > 300_000
}

fn build_role_map(roles: List(StreamingRole)) -> Dict(String, Role) {
  list.fold(roles, dict.new(), fn(acc, role) {
    let mapped = map_role(role.user_role)
    dict.insert(acc, role.manager_channel_id, mapped)
  })
}

fn map_role(user_role: String) -> Role {
  case user_role {
    "STREAMING_CHANNEL_OWNER" -> permission.Broadcaster
    "STREAMING_CHANNEL_MANAGER" -> permission.Moderator
    "STREAMING_CHAT_MANAGER" -> permission.Moderator
    "STREAMING_SETTLEMENT_MANAGER" -> permission.Moderator
    _ -> permission.Viewer
  }
}
