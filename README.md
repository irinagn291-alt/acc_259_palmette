# Palmette

Palmette is a hand-savings garden for people who will not link a bank. You plant a named goal, pour cash onto the open vine’s leader, then pinch that leader so wood records the target. Waiting cash never writes a node bead.

## Who it is for

Savers who want one visible target on a palmette trellis, added by hand, without a bank graph or a typed balance.

## Architecture

**Leader-pinch encoding.** A `Vine` is the aggregate: name, target, `vineSeed`, a `Leader` holding `Flush` and `Wood`, and `NodeMark` beads. A `Pour` writes Flush only. `pinchLeader` is the only fold that moves Flush into Wood and writes a `NodeMark` for every 0.25 / 0.5 / 0.75 / 1.0 of that vine’s own target that Wood newly reaches. Retract peels Flush and floors at 0; Wood stays. Progress is wood divided by target — Flush never enters the ratio.

This pattern fits the product because the persisted verb is pinch, not a typed balance. Unpinched flush can already look halfway up the cane; beads wait for lignify. One `VineStore` owns mutation. Views observe `GardenWatch` and never touch `UserDefaults`.

## Unique feature

**Pinch-then-node.** Home is the garden. Pour lengthens the dashed waiting cane; hatched wood and beads stay put. Pinch moves the whole flush at once. Unpinched flush never beads a node. Analytics counts NodeMarks and ripe vines, not a deposit list.

## Art

Style: 3D glass render with glassmorphism. Base prompt reused for every asset:

```
3D glass render with glassmorphism: studio-lit palmette espalier of translucent glass canes on a low trellis, frosted refraction, soft bloom, golden-hour warmth in the light not in named pigments, quiet uncluttered ground, isolated subjects, no text, no letters, no logo, no photoreal stock, no specified colours
```

Exact prompts:

**pmt_AppIcon** — A single palmette of translucent glass canes on a tiny trellis, 3D glass render, subject centred filling the canvas edge to edge, no text, no letters, no words, no alpha, no transparency, no rounded corners, no drop shadow outside the canvas

**pmt_Splash** — A tall vertical 3D glass trellis of palmette canes, frosted glassmorphism, quiet uncluttered centre band for a wordmark, studio light, no readable text

**pmt_Onboarding1** — 3D glass still life of a palmette vine on a garden trellis, what the product is in one glance, isolated cutout, no text

**pmt_Onboarding2** — 3D glass mid-gesture: fingers pinching the leader of a glass cane so flush becomes wood, glassmorphism, isolated cutout, no text

**pmt_Onboarding3** — 3D glass palmette with several lignified canes and quartile glass node beads, accumulated garden, isolated cutout, no text

**pmt_EmptyHome** — An empty 3D glass trellis with no canes seated, waiting to be planted, calm and inviting, never sad, isolated cutout, no text

**pmt_EmptyList** — An empty 3D glass ledger pane with no node beads, calm, isolated cutout, no text

**pmt_CardBackdrop** — Abstract low-contrast 3D frosted glass trellis slats and soft bloom, quiet enough for text on top, filling the canvas, no letters

**pmt_ControlFace** — The face of a pinch as a single physical control: a glass leader bud between two fingers, 3D glass cutout, isolated, no text

**pmt_TwistHero** — 3D glass emblem of pinch-then-node: a leader with unpinched flush beside lignified wood wearing quartile node beads, glassmorphism cutout, no text

**pmt_SuccessMark** — A small glass node bead seated on lignified wood after a pinch, 3D glass cutout, confirmation not fireworks, no letters

**pmt_HeaderDecor** — A wide low 3D glass band of palmette canes along a trellis rail, frosted glassmorphism, low contrast, no readable text

## How this differs

This is the first savings vine in the batch: the garden is the trellis, and pinch is the persisted verb. It never cuts a subscription, has no meal slots or barcode, does not bed remainder storeys, and has no quantum step. Milestones are quartiles of each vine’s own target. There is no Plot or GardenGame tab.

## Build

```bash
cd Palmette
xcodegen generate
xcodebuild -scheme Palmette -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Palmette -destination 'platform=iOS Simulator,id=<UDID>' test
```

iOS 17, Swift 6.2, no Swift packages. Simulator seed `pmt.demo.v1` fills several vines, leaves flush on the open vine so Pinch the leader is enabled, and marks onboarding complete. `-ReviewScreen today|log|goals` opens Garden, Analytics, and Settings after onboarding.
