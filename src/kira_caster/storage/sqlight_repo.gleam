import gleam/result
import kira_caster/storage/migrations
import kira_caster/storage/repos/command_repo
import kira_caster/storage/repos/donation_repo
import kira_caster/storage/repos/filter_repo
import kira_caster/storage/repos/follower_repo
import kira_caster/storage/repos/plugin_settings_repo
import kira_caster/storage/repos/quiz_repo
import kira_caster/storage/repos/settings_repo
import kira_caster/storage/repos/song_repo
import kira_caster/storage/repos/user_repo
import kira_caster/storage/repos/vote_repo
import kira_caster/storage/repository.{
  type Repository, type StorageError, ConnectionError, Repository,
}
import sqlight

pub fn new(db_path: String) -> Result(Repository, StorageError) {
  use conn <- result.try(
    sqlight.open(db_path)
    |> result.map_error(fn(e) { ConnectionError(e.message) }),
  )
  use _ <- result.try(migrations.run_migrations(conn))
  Ok(
    Repository(
      get_user: fn(user_id) { user_repo.get_user(conn, user_id) },
      save_user: fn(user_data) { user_repo.save_user(conn, user_data) },
      get_all_users: fn() { user_repo.get_all_users(conn) },
      get_banned_words: fn() { filter_repo.get_banned_words(conn) },
      add_banned_word: fn(word) { filter_repo.add_banned_word(conn, word) },
      remove_banned_word: fn(word) {
        filter_repo.remove_banned_word(conn, word)
      },
      get_command: fn(name) { command_repo.get_command(conn, name) },
      set_command: fn(name, response) {
        command_repo.set_command(conn, name, response)
      },
      delete_command: fn(name) { command_repo.delete_command(conn, name) },
      get_all_commands: fn() { command_repo.get_all_commands(conn) },
      start_vote: fn(topic, options) {
        vote_repo.start_vote(conn, topic, options)
      },
      cast_vote: fn(user, choice) { vote_repo.cast_vote(conn, user, choice) },
      get_vote_results: fn() { vote_repo.get_vote_results(conn) },
      get_active_vote: fn() { vote_repo.get_active_vote(conn) },
      end_vote: fn() { vote_repo.end_vote(conn) },
      add_quiz: fn(q, a, r) { quiz_repo.add_quiz(conn, q, a, r) },
      delete_quiz: fn(q) { quiz_repo.delete_quiz(conn, q) },
      get_all_quizzes: fn() { quiz_repo.get_all_quizzes(conn) },
      get_quiz_count: fn() { quiz_repo.get_quiz_count(conn) },
      get_disabled_plugins: fn() {
        plugin_settings_repo.get_disabled_plugins(conn)
      },
      set_plugin_enabled: fn(name, enabled) {
        plugin_settings_repo.set_plugin_enabled(conn, name, enabled)
      },
      get_all_settings: fn() { settings_repo.get_all_settings(conn) },
      get_setting: fn(key) { settings_repo.get_setting(conn, key) },
      set_setting: fn(key, value) {
        settings_repo.set_setting(conn, key, value)
      },
      get_command_with_type: fn(name) {
        command_repo.get_command_with_type(conn, name)
      },
      set_advanced_command: fn(name, source, fallback) {
        command_repo.set_advanced_command(conn, name, source, fallback)
      },
      get_all_commands_detailed: fn() {
        command_repo.get_all_commands_detailed(conn)
      },
      get_song_queue: fn() { song_repo.get_song_queue(conn) },
      add_song: fn(video_id, title, duration, user) {
        song_repo.add_song(conn, video_id, title, duration, user)
      },
      remove_song: fn(id) { song_repo.remove_song(conn, id) },
      clear_song_queue: fn() { song_repo.clear_song_queue(conn) },
      reorder_song: fn(id, new_pos) {
        song_repo.reorder_song(conn, id, new_pos)
      },
      get_songs_by_user: fn(user) { song_repo.get_songs_by_user(conn, user) },
      has_song_with_video_id: fn(vid) {
        song_repo.has_song_with_video_id(conn, vid)
      },
      save_donation: fn(channel_id, nickname, amount, message, dtype, ts) {
        donation_repo.save_donation(
          conn,
          channel_id,
          nickname,
          amount,
          message,
          dtype,
          ts,
        )
      },
      get_donation_ranking: fn(limit) {
        donation_repo.get_donation_ranking(conn, limit)
      },
      get_known_followers: fn() { follower_repo.get_known_followers(conn) },
      add_known_follower: fn(channel_id, name, ts) {
        follower_repo.add_known_follower(conn, channel_id, name, ts)
      },
    ),
  )
}
