import gleam/option
import kira_caster/core/permission
import kira_caster/platform/cime/api
import kira_caster/plugin/block
import kira_caster/plugin/plugin

fn mock_get_token() -> Result(String, String) {
  Ok("mock_token")
}

pub fn moderator_block_user_test() {
  let p = block.new(mock_get_token, api.mock_api())
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "차단",
        args: ["target_id"],
        role: permission.Moderator,
      ),
    )
  let assert [plugin.PluginResponse(plugin: "block", message: msg)] = events
  let assert True = msg == "target_id 차단했당!"
}

pub fn viewer_block_denied_test() {
  let p = block.new(mock_get_token, api.mock_api())
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "viewer",
        name: "차단",
        args: ["target_id"],
        role: permission.Viewer,
      ),
    )
  let assert [plugin.PluginResponse(plugin: "block", message: msg)] = events
  let assert True = msg == "헐 이건 관리자만 할 수 있어용 ㅠ"
}

pub fn moderator_unblock_user_test() {
  let p = block.new(mock_get_token, api.mock_api())
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "차단해제",
        args: ["target_id"],
        role: permission.Moderator,
      ),
    )
  let assert [plugin.PluginResponse(plugin: "block", message: msg)] = events
  let assert True = msg == "target_id 차단 풀어줬당!"
}

pub fn moderator_block_list_empty_test() {
  let p = block.new(mock_get_token, api.mock_api())
  let events =
    plugin.handle(
      p,
      plugin.Command(
        user: "mod",
        name: "차단목록",
        args: [],
        role: permission.Moderator,
      ),
    )
  let assert [plugin.PluginResponse(plugin: "block", message: msg)] = events
  let assert True = msg == "차단된 유저가 없당"
}

pub fn auto_block_system_event_test() {
  let p = block.new(mock_get_token, api.mock_api())
  let events =
    plugin.handle(p, plugin.SystemEvent(kind: "auto_block", data: "ch789"))
  let assert [plugin.PluginResponse(plugin: "block", message: msg)] = events
  let assert True = msg == "필터 위반이라 자동으로 차단했당!"
}

pub fn unrelated_event_ignored_test() {
  let p = block.new(mock_get_token, api.mock_api())
  let events =
    plugin.handle(
      p,
      plugin.ChatMessage(
        user: "alice",
        content: "hello",
        channel: "main",
        channel_id: option.None,
      ),
    )
  let assert [] = events
}
