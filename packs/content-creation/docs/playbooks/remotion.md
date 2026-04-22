# Remotion

Programmatic video with React. Compose scenes as components, preview in the studio, render to MP4 from the CLI. Use for repeatable video assets that benefit from data-driven composition: intros and outros, social cutdowns, template-driven explainers, audiograms.

## When to reach for it

- the same video shape needs to be produced many times with different inputs
- a scene depends on live data (charts, captions, metrics, schedules)
- the team already thinks in React and components
- the asset must be reproducible from source, not hand-edited

## When not to

- one-off creative edits where a timeline editor is faster
- anything the host or camera operator needs to adjust in real time
- interactive or branching video (Remotion renders, it does not serve)

## Prerequisites

- Node runtime (already in `creative_runtime` permission group)
- `ffmpeg` on `$PATH` - required for rendering, installed at the machine level
- Chrome for rendering - Remotion auto-downloads its own headless build on first render, no manual install

## Start a project

```
npx create-video@latest
```

No global install. The scaffolder prompts for a template; pick the one closest to the deliverable, not the most elaborate.

## Local loop

- `npm start` opens the Remotion Studio on a local port for scene preview and prop iteration
- Scenes are React components under `src/`; compositions are registered in `src/Root.tsx`
- Input props come in via `getInputProps()` - treat them as the contract between the render command and the composition, and validate them with a schema

## Render

```
npx remotion render <CompositionId> out/video.mp4 --props='<json-or-path>'
```

Prefer a file path for `--props` once the payload is nontrivial. Render output belongs under an ignored directory; never commit rendered artifacts.

## Asset and claims discipline

Remotion compositions pull in fonts, footage, music, and logos. The content-creation pack already has `asset-provenance` and `citation-discipline` rules - they apply here the same way they apply to a written draft:

- every bundled asset has a recorded source and license
- captions and on-screen claims are verified before render, not after
- fonts respect licensing for the intended distribution channel

## Handoff checklist

Before shipping a rendered video:

- brand check by `brand-guardian` on a still or short preview, not the final MP4
- editorial review of all on-screen copy and voiceover scripts
- accessibility pass: captions present, contrast legible, motion comfortable
- source payload (props file or data snapshot) archived alongside the render so the output is reproducible
