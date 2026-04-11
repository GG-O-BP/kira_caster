import gleam/int
import gleam/list
import gleam/option.{None}
import gleam/string
import kira_caster/admin/dashboard/effects
import kira_caster/admin/dashboard/model.{type Model, type Msg, Model}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // --- Navigation & General ---
    model.SwitchTab(tab) -> #(
      Model(..model, active_tab: tab, loading: True),
      effects.load_tab(tab, model.ctx),
    )

    model.RefreshTick -> #(
      model,
      effect.batch([
        effects.load_tab(model.active_tab, model.ctx),
        effects.schedule_refresh(),
      ]),
    )

    // --- Toast ---
    model.ShowToast(message, toast_type) -> {
      let id = model.next_toast_id
      let toast = model.Toast(id, message, toast_type)
      #(
        Model(
          ..model,
          toasts: list.append(model.toasts, [toast]),
          next_toast_id: id + 1,
        ),
        effects.dismiss_toast_after(id),
      )
    }

    model.DismissToast(id) -> #(
      Model(..model, toasts: list.filter(model.toasts, fn(t) { t.id != id })),
      effect.none(),
    )

    // --- Connection status ---
    model.ConnectionStateLoaded(state) -> #(
      Model(..model, connection_state: state),
      effect.none(),
    )

    // --- Status ---
    model.StatusLoaded(uptime) -> #(
      Model(..model, uptime_seconds: uptime, loading: False),
      effect.none(),
    )

    // --- Users ---
    model.UsersLoaded(users) -> #(
      Model(..model, users: users, loading: False),
      effect.none(),
    )

    model.UpdateUserFilter(q) -> #(
      Model(..model, user_filter: q),
      effect.none(),
    )

    // --- Words ---
    model.WordsLoaded(words) -> #(
      Model(..model, words: words, loading: False),
      effect.none(),
    )

    model.UpdateNewWord(w) -> #(Model(..model, new_word: w), effect.none())

    model.AddWord -> {
      case model.new_word {
        "" -> #(model, effect.none())
        w -> #(
          Model(..model, new_word: ""),
          effects.add_word(model.ctx.repo, w),
        )
      }
    }

    model.DeleteWord(w) -> #(model, effects.delete_word(model.ctx.repo, w))

    model.OpDone(_) -> #(model, effects.load_tab(model.active_tab, model.ctx))

    // --- Commands ---
    model.CommandsLoaded(cmds) -> #(
      Model(..model, commands: cmds, loading: False),
      effect.none(),
    )

    model.UpdateCmdName(n) -> #(Model(..model, cmd_name: n), effect.none())

    model.UpdateCmdResponse(r) -> #(
      Model(..model, cmd_response: r),
      effect.none(),
    )

    model.UpdateCmdType(t) -> {
      let ct = case t {
        "gleam" -> model.GleamCmd
        _ -> model.TextCmd
      }
      #(Model(..model, cmd_type: ct), effect.none())
    }

    model.UpdateCmdSource(s) -> #(Model(..model, cmd_source: s), effect.none())

    model.AddTextCmd -> {
      case model.cmd_name, model.cmd_response {
        "", _ -> #(model, effect.none())
        _, "" -> #(model, effect.none())
        n, r -> #(
          Model(..model, cmd_name: "", cmd_response: ""),
          effects.add_command(model.ctx.repo, n, r),
        )
      }
    }

    model.AddGleamCmd -> {
      case model.cmd_name, model.cmd_source {
        "", _ -> #(model, effect.none())
        _, "" -> #(model, effect.none())
        n, s -> #(
          Model(..model, cmd_name: "", cmd_source: ""),
          effects.add_advanced_command(model.ctx.repo, n, s),
        )
      }
    }

    model.DeleteCmd(n) -> #(model, effects.delete_command(model.ctx.repo, n))

    // TODO: compile support
    model.CompileCmd(_n) -> #(model, effect.none())

    model.CmdOpDone(_) -> #(model, effects.load_tab(model.Commands, model.ctx))

    // --- Quizzes ---
    model.QuizzesLoaded(q) -> #(
      Model(..model, quizzes: q, loading: False),
      effect.none(),
    )

    model.UpdateQuizQ(q) -> #(Model(..model, quiz_question: q), effect.none())

    model.UpdateQuizA(a) -> #(Model(..model, quiz_answer: a), effect.none())

    model.UpdateQuizR(r) -> #(Model(..model, quiz_reward: r), effect.none())

    model.AddQuiz -> {
      case model.quiz_question, model.quiz_answer {
        "", _ -> #(model, effect.none())
        _, "" -> #(model, effect.none())
        q, a -> {
          let reward = case int.parse(model.quiz_reward) {
            Ok(r) -> r
            Error(_) -> 10
          }
          #(
            Model(..model, quiz_question: "", quiz_answer: ""),
            effects.add_quiz(model.ctx.repo, q, a, reward),
          )
        }
      }
    }

    model.DeleteQuiz(q) -> #(model, effects.delete_quiz(model.ctx.repo, q))

    // --- Votes ---
    model.VoteLoaded(active, topic, results) -> #(
      Model(
        ..model,
        vote_active: active,
        vote_topic_display: topic,
        vote_results: results,
        loading: False,
      ),
      effect.none(),
    )

    model.UpdateVoteTopic(t) -> #(Model(..model, vote_topic: t), effect.none())

    model.UpdateVoteOptions(o) -> #(
      Model(..model, vote_options: o),
      effect.none(),
    )

    model.StartVote -> {
      let options =
        string.split(model.vote_options, ",")
        |> list.map(string.trim)
        |> list.filter(fn(s) { s != "" })
      case model.vote_topic, list.length(options) >= 2 {
        "", _ -> #(model, effect.none())
        _, False -> #(model, effect.none())
        t, True -> #(
          Model(..model, vote_topic: "", vote_options: ""),
          effects.start_vote(model.ctx.repo, t, options),
        )
      }
    }

    model.EndVote -> #(model, effects.end_vote(model.ctx.repo))

    // --- Plugins ---
    model.PluginsLoaded(p) -> #(
      Model(..model, plugins: p, loading: False),
      effect.none(),
    )

    model.TogglePlugin(name, enabled) -> #(
      model,
      effects.toggle_plugin(model.ctx.repo, name, enabled, model.ctx.bus),
    )

    // --- Settings ---
    model.SettingsLoaded(s) -> #(
      Model(..model, settings: s, editing_settings: s, loading: False),
      effect.none(),
    )

    model.UpdateSettingEdit(key, value) -> {
      let updated = case
        list.find(model.editing_settings, fn(s) { s.0 == key })
      {
        Ok(_) ->
          list.map(model.editing_settings, fn(s) {
            case s.0 == key {
              True -> #(key, value)
              False -> s
            }
          })
        Error(_) -> list.append(model.editing_settings, [#(key, value)])
      }
      #(Model(..model, editing_settings: updated), effect.none())
    }

    model.SaveSetting(key, value) -> #(
      model,
      effects.save_setting(model.ctx.repo, key, value, model.ctx.bus),
    )

    model.RestartApp -> #(model, effects.restart_app())

    // --- Songs ---
    model.SongsLoaded(songs, current, version) -> #(
      Model(
        ..model,
        songs: songs,
        current_song: current,
        song_version: version,
        loading: False,
      ),
      effect.none(),
    )

    model.UpdateSongUrl(u) -> #(Model(..model, song_url: u), effect.none())

    model.AddSong -> {
      case model.song_url {
        "" -> #(model, effect.none())
        url -> #(
          Model(..model, song_url: ""),
          effects.add_song(model.ctx.repo, url),
        )
      }
    }

    model.DeleteSong(id) -> #(model, effects.delete_song(model.ctx.repo, id))

    model.SongPrev -> #(model, effects.song_prev(model.ctx.repo))

    model.SongNext -> #(model, effects.song_next(model.ctx.repo))

    model.SongReplay -> #(model, effects.song_replay(model.ctx.repo))

    model.SongMove(id, pos) -> #(
      model,
      effects.reorder_song(model.ctx.repo, id, pos),
    )

    model.SongSettingsLoaded(s) -> #(
      Model(..model, song_settings: s),
      effect.none(),
    )

    model.SaveSongSetting(key, value) -> #(
      model,
      effects.save_setting(model.ctx.repo, key, value, None),
    )

    // --- CIME Auth ---
    model.AuthStatusLoaded(auth, expires, ch) -> #(
      Model(
        ..model,
        cime_authenticated: auth,
        cime_expires_at: expires,
        cime_channel_name: ch,
        loading: False,
      ),
      effect.none(),
    )

    // TODO: disconnect
    model.CimeDisconnect -> #(model, effect.none())

    // --- Broadcast ---
    model.BroadcastLoaded(title, tags, cat) -> #(
      Model(
        ..model,
        bc_title: title,
        bc_tags: tags,
        bc_category_name: cat,
        loading: False,
      ),
      effect.none(),
    )

    model.UpdateBcTitle(t) -> #(Model(..model, bc_title: t), effect.none())

    // TODO: save via CIME API
    model.SaveBcTitle -> #(model, effect.none())

    model.UpdateBcNewTag(t) -> #(Model(..model, bc_new_tag: t), effect.none())

    // TODO
    model.AddBcTag -> #(model, effect.none())

    // TODO
    model.RemoveBcTag(_t) -> #(model, effect.none())

    // TODO: trigger search
    model.UpdateBcCatSearch(s) -> #(
      Model(..model, bc_cat_search: s),
      effect.none(),
    )

    model.CategoriesLoaded(cats) -> #(
      Model(..model, bc_categories: cats),
      effect.none(),
    )

    // TODO
    model.SelectCategory(_id, _name) -> #(model, effect.none())

    // --- Chat Settings ---
    model.ChatSettingsLoaded(slow, sec, follower) -> #(
      Model(
        ..model,
        cs_slow_mode: slow,
        cs_slow_seconds: sec,
        cs_follower_only: follower,
        loading: False,
      ),
      effect.none(),
    )

    model.UpdateSlowMode(b) -> #(Model(..model, cs_slow_mode: b), effect.none())

    model.UpdateSlowSeconds(s) -> {
      let sec = case int.parse(s) {
        Ok(n) -> n
        Error(_) -> model.cs_slow_seconds
      }
      #(Model(..model, cs_slow_seconds: sec), effect.none())
    }

    model.UpdateFollowerOnly(b) -> #(
      Model(..model, cs_follower_only: b),
      effect.none(),
    )

    // TODO: save via CIME API
    model.SaveChatSettings -> #(model, effect.none())

    // --- Block Manage ---
    model.BlockedUsersLoaded(users) -> #(
      Model(..model, blocked_users: users, loading: False),
      effect.none(),
    )

    model.UpdateBlockTarget(t) -> #(
      Model(..model, block_target: t),
      effect.none(),
    )

    // TODO
    model.AddBlock -> #(model, effect.none())

    // TODO
    model.RemoveBlock(_id) -> #(model, effect.none())

    // --- Channel Info ---
    model.ChannelInfoLoaded(name, handle, img) -> #(
      Model(
        ..model,
        ch_name: name,
        ch_handle: handle,
        ch_image_url: img,
        loading: False,
      ),
      effect.none(),
    )

    model.LiveStatusLoaded(live, title, viewers) -> #(
      Model(
        ..model,
        ch_live: live,
        ch_live_title: title,
        ch_viewer_count: viewers,
      ),
      effect.none(),
    )

    model.StreamKeyLoaded(key) -> #(
      Model(..model, stream_key: key),
      effect.none(),
    )

    model.ToggleStreamKey -> #(
      Model(..model, stream_key_visible: !model.stream_key_visible),
      effect.none(),
    )
  }
}
