# FactoryWatch

FactoryWatch is a small factory-floor video monitoring prototype. It publishes prerecorded clips as RTSP camera streams, monitors those streams for failures, and runs a separate computer-vision worker on sampled footage.

It is an engineering prototype for learning and demonstration, **not a production safety system**.

## Language split

| Component | Language | Why |
|---|---|---|
| Camera fleet simulator | Go | Process supervision (start, watch and kill FFmpeg) fits `os/exec`, `context` and goroutines. |
| Stream health monitor | Go | Long-running per-camera readers with timeouts and reconnects. |
| Backend (with PostgreSQL) | Go | Simple HTTP + SQL service. |
| CV inference worker | Python 3.15 | The ML libraries (PyTorch, PyAV) live in Python. |
| Dashboard | TypeScript | Minimal UI. |

Services talk to each other with JSON over HTTP, so mixing languages is cheap.

## Build order

1. **Setup and streaming foundation** — done
2. Camera fleet simulator
3. Stream health monitor
4. Backend and PostgreSQL
5. CV inference worker
6. Dashboard

Design docs and plans for each step live in [`docs/superpowers/`](docs/superpowers/). The original specifications are [`backend-spec.md`](backend-spec.md) and [`camera-fleet-spec.md`](camera-fleet-spec.md).

## Prerequisites

Installed system-wide (Homebrew on macOS):

- Go 1.27+
- Python 3.15 (`python3.15`) and `uv` — used from step 5
- FFmpeg and ffprobe
- MediaMTX
- curl

Check them with `make check-tools`.

## Quick start

```bash
make check-tools      # 1. confirm all tools are installed
make sample-videos    # 2. generate three small test clips into videos/
make mediamtx         # 3. terminal 1: run the RTSP server (foreground)
make smoke            # 4. terminal 2: publish two clips, verify both, clean up
```

`make` on its own lists all targets.

## Viewing a stream by hand

With `make mediamtx` running, publish one clip (Ctrl-C to stop):

```bash
ffmpeg -hide_banner -loglevel warning \
  -re -stream_loop -1 -i videos/sample-1.mp4 \
  -an -c:v copy -f rtsp -rtsp_transport tcp \
  rtsp://localhost:8554/DEMO-1
```

In another terminal, watch it or list publishers:

```bash
ffplay -rtsp_transport tcp rtsp://localhost:8554/DEMO-1
curl http://127.0.0.1:9997/v3/paths/list
```

MediaMTX listing a publisher does **not** prove frames are fresh or decodable. Checking that is the stream monitor's job.

## Sample videos

`make sample-videos` writes `videos/sample-{1,2,3}.mp4`: 640x360, 15 fps, 20 s, H.264 with no B-frames and a keyframe every 2 s. These settings let FFmpeg publish with `-c:v copy` (no re-encoding). The script checks each clip and uses FFmpeg's `freezedetect` filter to make sure none of them contain a frozen section. Video files are not committed.

## Repository layout

```text
factorywatch/
├── Makefile                      # single entry point
├── infrastructure/mediamtx/      # MediaMTX config (local now, Docker later)
├── scripts/                      # check-tools, sample videos, smoke check
├── videos/                       # local clips (ignored by Git)
├── datasets/                     # dataset subset for the CV step (ignored by Git)
└── docs/superpowers/             # design docs and implementation plans
```

Service folders (`simulator/`, `stream-monitor/`, `backend/`, `cv-worker/`, `dashboard/`) are added as each step is built.
