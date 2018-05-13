<%!
  import datetime
  from templates.utils import md5file
  from templates.data.timecodes import Timecode
%>
<%inherit file="include/base.mako" />
<%namespace file="include/elements.mako" name="el" />

<%block name="head">
<title>${game['name']} | ${config['title']}</title>

<!-- Plyr (https://github.com/sampotts/plyr) -->
<link rel="stylesheet" href="//cdn.plyr.io/2.0.18/plyr.css">
<script src="//cdn.plyr.io/2.0.18/plyr.js"></script>
<!-- Subtitles Octopus (https://github.com/Dador/JavascriptSubtitlesOctopus) -->
<script src="/static/js/subtitles-octopus.js"></script>
<script src="/static/js/player.js?hash=${md5file('static/js/player.js')}"></script>
</%block>

<%block name="content">
<%def name="timecode_link(id, t)">\
<a href="javascript:void(0)" onclick="document.getElementById('wrapper-${id}').seek(${int(t)})">${str(t)}</a>\
</%def>

<%def name="timecode_list(id, timecodes, offset=Timecode(0), text='Таймкоды')">\
% if timecodes >= offset:
  <li>${text}:</li>
  <ul>
  % for t, name in timecodes:
    % if type(t) is type(timecodes):
    ${timecode_list(id, t, offset=offset, text=name)}
    % elif t >= offset:
    <li>${timecode_link(id, t - offset)} - ${name}</li>
    % endif
  % endfor
  </ul>
% endif
</%def>

<%def name="source_link(stream, text=u'Запись')">\
% if stream.get('youtube'):
  <li>${text} (YouTube): <a href="https://www.youtube.com/watch?v=${stream['youtube']}">${stream['youtube']}</a></li>
% elif stream.get('vk'):
  <li>${text} (ВКонтакте): <a href="https://vk.com/video${stream['vk']}">${stream['vk']}</a></li>
% elif stream.get('direct'):
  <li>${text}: <a href="${stream['direct']}">прямая ссылка</a></li>
% endif
</%def>

<%def name="gen_stream(id, stream)">
<% hash = stream.hash %>\
<h2 id="${hash}"><a onclick="window.location.hash = '#${hash}'; return false;" href="/r/?${hash}">${stream['name']}</a></h2>

<ul>
% if stream.get('note'):
  <li>Примечание: ${stream['note']}</li>
% endif
  <li>Ссылки:</li>
  <ul>
    <li>Twitch: <a href="https://www.twitch.tv/videos/${stream['twitch']}">${stream['twitch']}</a></li>
    <li>Субтитры: <a href="../chats/v${stream['twitch']}.ass">v${stream['twitch']}.ass</a></li>
    ${source_link(stream)}
  </ul>
% if stream.get('offset'):
  <li>Эта запись смещена на ${stream['offset']} от начала стрима</li>
% endif
% if stream.get('timecodes'):
  ${timecode_list(id, stream['timecodes'], offset=Timecode(stream.get('offset')))}
% endif
% for i in ['start', 'soft_start']:
  % if stream.get(i):
  <li>Игра начинается с ${timecode_link(id, Timecode(stream[i]) - Timecode(stream.get('offset')))}</li>
  % endif
% endfor
% if stream.get('end'):
  <li>Запись заканчивается в ${timecode_link(id, Timecode(stream['end']) - Timecode(stream.get('offset')))}</li>
% endif
</ul>

<div class="row justify-content-md-center">
  <p class="stream col" id="wrapper-${id}" ${stream.attrs()} />
</div>

% if not stream.player_compatible():
<p>Запись этого стрима в данный момент отсутствует. Если вы попали сюда по
прямой ссылке с YouTube, то это значит, что запись уже есть, но сайт ещё не
обновился. Обычно на это требуется минута или около того, но я оставляю
комментарий ещё до завершения процесса. Нажмите
<a onclick="document.location.reload()">сюда</a>, чтобы попробовать обновить
страницу.</p>
% endif

<h4>Команда для просмотра стрима в проигрывателе MPV</h4>

<%el:code_block>\
% if stream.player_compatible():
mpv ${stream.mpv_args()} ${stream.mpv_file()}
% else:
streamlink -p "mpv ${stream.mpv_args()}" --player-passthrough hls twitch.tv/videos/${stream.twitch} best
% endif
</%el:code_block>

% if game['streams'].index(stream) != len(game['streams']) - 1:
<hr>
% endif
</%def>

<h1><a href="/">Архив</a> → ${game['name']}</h1>
<% id = 0 %> \
% for stream in game['streams']:
${gen_stream(id, stream)}
<% id += 1 %> \
% endfor
</%block>
