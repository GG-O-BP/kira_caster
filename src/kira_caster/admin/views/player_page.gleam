import kira_caster/admin/views/layout
import lustre/attribute.{attribute as attr}
import lustre/element.{type Element, fragment, text}
import lustre/element/html
import wisp.{type Response}

pub fn handle_player_page() -> Response {
  layout.page(
    title: "kira_caster Player",
    head: "<style>" <> player_css() <> "</style>",
    body: player_body(),
    tail: "<script src=\"https://www.youtube.com/iframe_api\"></script>"
      <> "<script>"
      <> player_js()
      <> "</script>",
  )
}

fn player_body() -> Element(msg) {
  fragment([
    html.div([attribute.id("player-wrap")], [
      html.div([attribute.id("yt-player")], []),
      html.div([attribute.class("idle-msg"), attribute.id("idle")], [
        text("대기 중..."),
      ]),
    ]),
    html.div(
      [
        attribute.class("now-bar"),
        attribute.id("now-bar"),
        attr("style", "display:none"),
      ],
      [
        element.element(
          "svg",
          [
            attribute.class("icon"),
            attr("viewBox", "0 0 24 24"),
            attr("fill", "#fff"),
          ],
          [
            element.element(
              "path",
              [attr("d", "M12 3v10.55A4 4 0 1014 17V7h4V3h-6z")],
              [],
            ),
          ],
        ),
        html.span([attribute.class("now-title"), attribute.id("now-title")], []),
        html.span([attribute.class("now-user"), attribute.id("now-user")], []),
      ],
    ),
  ])
}

fn player_css() -> String {
  "
    * { margin:0; padding:0; box-sizing:border-box; }
    body { background:#0e0e10; color:#efeff1; font-family:'Quicksand',sans-serif; overflow:hidden; }
    #player-wrap { position:relative; width:100vw; height:calc(100vh - 56px); background:#000; }
    #yt-player { width:100%; height:100%; }
    .now-bar {
      height:56px; display:flex; align-items:center; gap:12px;
      padding:0 16px; background:linear-gradient(92.54deg,#FF608F 5.84%,#FBB35E 95.21%);
    }
    .now-title { font-weight:700; font-size:15px; flex:1; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .now-user { font-size:13px; opacity:.85; white-space:nowrap; }
    .now-bar .icon { width:20px; height:20px; animation:pulse 1.5s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
    .idle-msg { position:absolute; top:50%; left:50%; transform:translate(-50%,-50%); font-size:18px; color:#888; }
  "
}

fn player_js() -> String {
  "
const base = window.location.origin;
let player = null;
let currentVideoId = '';
let currentVersion = '';
let ready = false;

function onYouTubeIframeAPIReady() {
  player = new YT.Player('yt-player', {
    width: '100%', height: '100%',
    playerVars: { autoplay:1, controls:0, modestbranding:1, rel:0 },
    events: {
      onReady: function() { ready = true; pollCurrent(); },
      onStateChange: function(e) {
        if (e.data === YT.PlayerState.ENDED) {
          fetch(base+'/songs/next',{method:'POST'}).then(function(){});
        }
      }
    }
  });
}

function pollCurrent() {
  setInterval(function() {
    fetch(base+'/songs/current').then(function(r){return r.json()}).then(function(d) {
      if (!d.current) {
        document.getElementById('now-bar').style.display='none';
        document.getElementById('idle').style.display='';
        return;
      }
      if (d.version !== currentVersion) {
        currentVersion = d.version;
        if (d.current.video_id !== currentVideoId) {
          currentVideoId = d.current.video_id;
          player.loadVideoById(currentVideoId);
        } else {
          player.seekTo(0);
        }
        document.getElementById('idle').style.display='none';
        document.getElementById('now-bar').style.display='flex';
        document.getElementById('now-title').textContent = d.current.title;
        document.getElementById('now-user').textContent = d.current.requested_by;
      }
    }).catch(function(){});
  }, 2000);
}
  "
}
