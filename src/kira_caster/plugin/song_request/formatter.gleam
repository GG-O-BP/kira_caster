import kira_caster/plugin/plugin.{type Event}
import kira_caster/storage/repository.{type SongData}
import kira_caster/util/youtube

pub fn format_song(s: SongData) -> String {
  s.title
  <> " ("
  <> youtube.format_duration(s.duration_seconds)
  <> ") - "
  <> s.requested_by
}

pub fn resp(msg: String) -> Event {
  plugin.PluginResponse(plugin: "song_request", message: msg)
}
