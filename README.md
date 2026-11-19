# twitch-iina

Twitch kijken in IINA via [Streamlink Twitch GUI](https://github.com/streamlink/streamlink-twitch-gui),
met 2K (1440p, ook in H.265) en automatisch terug naar live. Voor macOS.

- **`iina-twitch`**: de speler. Zet de stream zonder hercoderen om naar MPEG-TS en speelt hem af in IINA,
  met echte picture-in-picture.
- **`live.lua`**: loop je meer dan 6 seconden achter (bijvoorbeeld na een pauze), dan springt de speler
  naar 3 seconden vóór live en toont hij "Terug naar live".
- **`twitch-2k-login`**: zet je Twitch-login en de 2K-codecs in Streamlinks `config.twitch`.

## Installeren

```sh
brew install --cask iina
brew install thedutchsmoke/tap/twitch-iina
twitch-2k-login
```

Daarna in Streamlink Twitch GUI: **Instellingen → Streaming**

- Player preset: **No preset**
- Video player: `/opt/homebrew/bin/iina-twitch` (Intel-Mac: `/usr/local/bin/iina-twitch`)
- Parameters: leeg

Bijwerken gaat met `brew upgrade`. Controleren of de login nog geldig is: `twitch-2k-login --check`.

## Twitch-login (eenmalig per Mac)

Twitch geeft een Streamlink die niet is ingelogd alleen omgezette versies, dus maximaal 1080p of minder.
De GUI geeft zijn eigen login niet door aan Streamlink. Daarom staat je login in
`~/Library/Application Support/streamlink/config.twitch`; Streamlink leest dat ook als de GUI hem start.

`twitch-2k-login` vraagt het token verborgen, controleert het bij Twitch en slaat het op (rechten 600).
Het token is de cookie `auth-token` van twitch.tv. Ingelogd op twitch.tv, in de browserconsole:

```js
copy(document.cookie.match(/auth-token=([^;]+)/)[1])
```

Plak het daarna bij de vraag. Het token van de GUI zelf werkt niet (ander client-ID).
Krijg je weer maximaal 1080p, dan is de login verlopen: voer `twitch-2k-login` opnieuw uit.

## Waarom zo

- Twitch levert 2K per kanaal als H.264 (MPEG-TS) of alleen als H.265 (fMP4). De ffmpeg in IINA 1.5.1
  (9.0.1) stopt bij fMP4 uit een pipe na een paar seconden (`trun sample count ... exceeds`).
  Daarom kopieert ffmpeg (Homebrew) de stream eerst naar MPEG-TS. Dat kost ongeveer 0,3% van één CPU-kern.
- `live.lua` springt alleen binnen mpv's eigen buffer. Met `force-seekable` probeert ffmpeg terug te
  zoeken in de pipe, en daarop stopt de stream.
- IINA geeft `--mpv-script` pas door als mpv al draait; daarom laadt `iina-twitch` het script via
  mpv's IPC-socket (`/tmp/iina-twitch-<pid>.sock`).
- Landen op 3 seconden vóór live: Twitch levert blokken van 2 seconden. Met minder buffer loopt hij leeg.

## Zonder IINA: mpv

Wil je geen picture-in-picture, dan kan het ook zonder omzetting met mpv (`brew install mpv`):
in de GUI de preset **MPV**, vinkje **seeking** uit, en als parameters

```
--cache=yes --demuxer-seekable-cache=yes --script=/opt/homebrew/share/twitch-iina/live.lua
```

## Ontwikkelen

Code in deze repo, de formule in [TheDutchSmoke/homebrew-tap](https://github.com/TheDutchSmoke/homebrew-tap).
Nieuwe versie: `VERSION` in beide scripts ophogen, taggen (`vX.Y.Z`), en in de formule `url` en `sha256` bijwerken.

Licentie: MIT.
