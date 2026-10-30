import {Audio} from "@remotion/media";
import {linearTiming, TransitionSeries} from "@remotion/transitions";
import {wipe} from "@remotion/transitions/wipe";
import {interpolate, staticFile, useCurrentFrame, useVideoConfig} from "remotion";
import "./fonts";
import {BossEscape} from "./scenes/BossEscape";
import {EndCard} from "./scenes/EndCard";
import {Hook} from "./scenes/Hook";
import {Trainer} from "./scenes/Trainer";
import {Upgrade} from "./scenes/Upgrade";

const BattleBed = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  return (
    <Audio
      name="Battle bed"
      src={staticFile("sfx/battle_music.ogg")}
      durationInFrames={9 * fps}
      volume={interpolate(
        frame,
        [0, 0.3 * fps, 0.7 * fps, 1.15 * fps, 8.2 * fps, 9 * fps],
        [0.08, 0.42, 0.2, 0.36, 0.36, 0],
        {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        },
      )}
    />
  );
};

const BossBed = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  return (
    <Audio
      name="Boss bed"
      src={staticFile("sfx/boss_music.ogg")}
      from={8.5 * fps}
      durationInFrames={6.5 * fps}
      volume={interpolate(frame, [8.5 * fps, 9.2 * fps, 14.2 * fps, 15 * fps], [0, 0.48, 0.48, 0], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      })}
    />
  );
};

const Hits = () => {
  const {fps} = useVideoConfig();

  return (
    <>
      <Audio name="Whoosh" src={staticFile("sfx/whoosh.wav")} volume={0.9} />
      <Audio name="Whip" src={staticFile("sfx/whip.wav")} from={0.08 * fps} volume={0.45} />
      <Audio
        name="Battle sting"
        src={staticFile("sfx/battle_start.wav")}
        from={0.12 * fps}
        volume={0.6}
      />
      <Audio name="Shot" src={staticFile("sfx/shoot.wav")} from={0.62 * fps} volume={0.55} />
      <Audio name="Pop" src={staticFile("sfx/pop.wav")} from={0.78 * fps} volume={0.75} />
      <Audio name="Stamp" src={staticFile("sfx/stamp.wav")} from={0.86 * fps} volume={0.85} />
      <Audio name="Correct" src={staticFile("sfx/correct.wav")} from={1.05 * fps} volume={0.6} />
      <Audio
        name="Sum correct"
        src={staticFile("sfx/correct.wav")}
        from={3 * fps - 8 + 0.55 * fps}
        volume={0.6}
      />
      <Audio
        name="Difference correct"
        src={staticFile("sfx/correct.wav")}
        from={3 * fps - 8 + 1.3 * fps}
        volume={0.6}
      />
      <Audio
        name="Hole series"
        src={staticFile("sfx/series.wav")}
        from={3 * fps - 8 + 2.2 * fps}
        volume={0.7}
      />
      <Audio
        name="Division stamp"
        src={staticFile("sfx/stamp.wav")}
        from={3 * fps - 8 + 3.15 * fps}
        volume={0.75}
      />
      <Audio
        name="Upgrade click"
        src={staticFile("sfx/correct.wav")}
        from={7 * fps - 16 + 0.7 * fps}
        volume={0.45}
      />
      <Audio
        name="Gold series"
        src={staticFile("sfx/series.wav")}
        from={7 * fps - 16 + 2 * fps}
        volume={0.7}
      />
      <Audio
        name="Boss shot"
        src={staticFile("sfx/shoot.wav")}
        from={10 * fps - 24 + 0.7 * fps}
        volume={0.6}
      />
      <Audio
        name="Boss shot two"
        src={staticFile("sfx/shoot.wav")}
        from={10 * fps - 24 + 1.4 * fps}
        volume={0.6}
      />
      <Audio
        name="Boss shot three"
        src={staticFile("sfx/shoot.wav")}
        from={10 * fps - 24 + 2.1 * fps}
        volume={0.65}
      />
      <Audio
        name="Boss crash"
        src={staticFile("sfx/crash.wav")}
        from={10 * fps - 24 + 2.4 * fps}
        volume={0.8}
      />
      <Audio
        name="Escape whoosh"
        src={staticFile("sfx/victory_whoosh.wav")}
        from={10 * fps - 24 + 2.6 * fps}
        durationInFrames={1.6 * fps}
        volume={0.7}
      />
      <Audio
        name="Win sting"
        src={staticFile("sfx/win.wav")}
        from={14 * fps - 32}
        durationInFrames={2 * fps}
        volume={0.75}
      />
    </>
  );
};

export const JetMathSpot = () => {
  const {fps} = useVideoConfig();

  return (
    <>
      <TransitionSeries>
        <TransitionSeries.Sequence name="Hook" durationInFrames={3 * fps}>
          <Hook
            name="Hook"
            equation="8 × 7"
            answer="56"
            style={{
              backgroundColor: "#7EBFEE",
            }}
          />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition
          presentation={wipe({direction: "from-right"})}
          timing={linearTiming({durationInFrames: 8})}
        />
        <TransitionSeries.Sequence name="Trainer" durationInFrames={4 * fps}>
          <Trainer
            name="Trainer"
            style={{
              backgroundColor: "#F7F1E4",
            }}
          />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition
          presentation={wipe({direction: "from-left"})}
          timing={linearTiming({durationInFrames: 8})}
        />
        <TransitionSeries.Sequence name="Upgrade" durationInFrames={3 * fps}>
          <Upgrade
            name="Upgrade"
            style={{
              backgroundColor: "#F7F1E4",
            }}
          />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition
          presentation={wipe({direction: "from-right"})}
          timing={linearTiming({durationInFrames: 8})}
        />
        <TransitionSeries.Sequence name="Boss" durationInFrames={4 * fps}>
          <BossEscape
            name="Boss"
            style={{
              backgroundColor: "#7EBFEE",
            }}
          />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition
          presentation={wipe({direction: "from-bottom"})}
          timing={linearTiming({durationInFrames: 8})}
        />
        <TransitionSeries.Sequence name="End" durationInFrames={2 * fps + 2}>
          <EndCard
            name="End card"
            style={{
              backgroundColor: "#F7F1E4",
            }}
          />
        </TransitionSeries.Sequence>
      </TransitionSeries>
      <BattleBed />
      <BossBed />
      <Hits />
    </>
  );
};
