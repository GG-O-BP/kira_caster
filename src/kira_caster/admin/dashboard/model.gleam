import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None}
import kira_caster/core/config.{type Config}
import kira_caster/event_bus.{type EventBusMessage}
import kira_caster/platform/cime/api.{type CimeApi}
import kira_caster/storage/repository.{
  type Repository, type SongData, type UserData,
}

// --- Tabs ---

pub type Tab {
  Status
  Users
  Words
  Commands
  Quizzes
  Votes
  Plugins
  Settings
  Songs
  CimeAuth
  Broadcast
  ChatSettings
  BlockManage
  ChannelInfo
}

// --- Supporting types ---

pub type ToastType {
  SuccessToast
  ErrorToast
}

pub type Toast {
  Toast(id: Int, message: String, toast_type: ToastType)
}

pub type CmdType {
  TextCmd
  GleamCmd
}

pub type PluginInfo {
  PluginInfo(name: String, description: String, enabled: Bool)
}

pub type VoteResult {
  VoteResult(choice: String, count: Int)
}

// --- Context ---

pub type DashboardContext {
  DashboardContext(
    repo: Repository,
    start_time: Int,
    config: Config,
    cime_api: Option(CimeApi),
    get_token: Option(fn() -> Result(String, String)),
    bus: Option(Subject(EventBusMessage)),
  )
}

// --- Model ---

pub type Model {
  Model(
    ctx: DashboardContext,
    active_tab: Tab,
    toasts: List(Toast),
    next_toast_id: Int,
    // Status
    uptime_seconds: Int,
    // Users
    users: List(UserData),
    user_filter: String,
    // Words
    words: List(String),
    new_word: String,
    // Commands
    commands: List(#(String, String, String, Option(String))),
    cmd_name: String,
    cmd_response: String,
    cmd_type: CmdType,
    cmd_source: String,
    // Quizzes
    quizzes: List(#(String, String, Int)),
    quiz_question: String,
    quiz_answer: String,
    quiz_reward: String,
    // Votes
    vote_active: Bool,
    vote_topic_display: String,
    vote_results: List(VoteResult),
    vote_topic: String,
    vote_options: String,
    // Plugins
    plugins: List(PluginInfo),
    // Settings
    settings: List(#(String, String)),
    // Songs
    songs: List(SongData),
    current_song: Option(SongData),
    song_version: String,
    song_url: String,
    song_settings: List(#(String, String)),
    // CIME Auth
    cime_authenticated: Bool,
    cime_expires_at: String,
    cime_channel_name: String,
    // Broadcast
    bc_title: String,
    bc_tags: List(String),
    bc_category_name: String,
    bc_new_tag: String,
    bc_cat_search: String,
    bc_categories: List(#(String, String)),
    // Chat Settings
    cs_slow_mode: Bool,
    cs_slow_seconds: Int,
    cs_follower_only: Bool,
    // Block Manage
    blocked_users: List(#(String, String, String)),
    block_target: String,
    // Channel Info
    ch_name: String,
    ch_handle: String,
    ch_image_url: String,
    ch_live: Bool,
    ch_live_title: String,
    ch_viewer_count: Int,
    stream_key: String,
    stream_key_visible: Bool,
  )
}

// --- Messages ---

pub type Msg {
  // Navigation & General
  SwitchTab(Tab)
  RefreshTick
  ShowToast(String, ToastType)
  DismissToast(Int)
  // Status
  StatusLoaded(Int)
  // Users
  UsersLoaded(List(UserData))
  UpdateUserFilter(String)
  // Words
  WordsLoaded(List(String))
  UpdateNewWord(String)
  AddWord
  DeleteWord(String)
  OpDone(Result(Nil, String))
  // Commands
  CommandsLoaded(List(#(String, String, String, Option(String))))
  UpdateCmdName(String)
  UpdateCmdResponse(String)
  UpdateCmdType(String)
  UpdateCmdSource(String)
  AddTextCmd
  AddGleamCmd
  DeleteCmd(String)
  CompileCmd(String)
  CmdOpDone(Result(String, String))
  // Quizzes
  QuizzesLoaded(List(#(String, String, Int)))
  UpdateQuizQ(String)
  UpdateQuizA(String)
  UpdateQuizR(String)
  AddQuiz
  DeleteQuiz(String)
  // Votes
  VoteLoaded(Bool, String, List(VoteResult))
  UpdateVoteTopic(String)
  UpdateVoteOptions(String)
  StartVote
  EndVote
  // Plugins
  PluginsLoaded(List(PluginInfo))
  TogglePlugin(String, Bool)
  // Settings
  SettingsLoaded(List(#(String, String)))
  SaveSetting(String, String)
  // Songs
  SongsLoaded(List(SongData), Option(SongData), String)
  UpdateSongUrl(String)
  AddSong
  DeleteSong(Int)
  SongPrev
  SongNext
  SongReplay
  SongMove(Int, Int)
  SongSettingsLoaded(List(#(String, String)))
  SaveSongSetting(String, String)
  // CIME Auth
  AuthStatusLoaded(Bool, String, String)
  CimeDisconnect
  // Broadcast
  BroadcastLoaded(String, List(String), String)
  UpdateBcTitle(String)
  SaveBcTitle
  UpdateBcNewTag(String)
  AddBcTag
  RemoveBcTag(String)
  UpdateBcCatSearch(String)
  CategoriesLoaded(List(#(String, String)))
  SelectCategory(String, String)
  // Chat Settings
  ChatSettingsLoaded(Bool, Int, Bool)
  UpdateSlowMode(Bool)
  UpdateSlowSeconds(String)
  UpdateFollowerOnly(Bool)
  SaveChatSettings
  // Block Manage
  BlockedUsersLoaded(List(#(String, String, String)))
  UpdateBlockTarget(String)
  AddBlock
  RemoveBlock(String)
  // Channel Info
  ChannelInfoLoaded(String, String, String)
  LiveStatusLoaded(Bool, String, Int)
  StreamKeyLoaded(String)
  ToggleStreamKey
}

// --- Model constructor ---

pub fn new(ctx: DashboardContext) -> Model {
  Model(
    ctx: ctx,
    active_tab: Status,
    toasts: [],
    next_toast_id: 0,
    uptime_seconds: 0,
    users: [],
    user_filter: "",
    words: [],
    new_word: "",
    commands: [],
    cmd_name: "",
    cmd_response: "",
    cmd_type: TextCmd,
    cmd_source: "",
    quizzes: [],
    quiz_question: "",
    quiz_answer: "",
    quiz_reward: "10",
    vote_active: False,
    vote_topic_display: "",
    vote_results: [],
    vote_topic: "",
    vote_options: "",
    plugins: [],
    settings: [],
    songs: [],
    current_song: None,
    song_version: "",
    song_url: "",
    song_settings: [],
    cime_authenticated: False,
    cime_expires_at: "",
    cime_channel_name: "",
    bc_title: "",
    bc_tags: [],
    bc_category_name: "",
    bc_new_tag: "",
    bc_cat_search: "",
    bc_categories: [],
    cs_slow_mode: False,
    cs_slow_seconds: 5,
    cs_follower_only: False,
    blocked_users: [],
    block_target: "",
    ch_name: "",
    ch_handle: "",
    ch_image_url: "",
    ch_live: False,
    ch_live_title: "",
    ch_viewer_count: 0,
    stream_key: "",
    stream_key_visible: False,
  )
}
