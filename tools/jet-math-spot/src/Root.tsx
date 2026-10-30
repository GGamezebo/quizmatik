import {Composition, Folder} from "remotion";
import {JetMathSpot} from "./JetMathSpot";
import {RealGameplay, RealGameplayEn, reelFrames} from "./RealGameplay";
import {BossEscape} from "./scenes/BossEscape";
import {EndCard} from "./scenes/EndCard";
import {Hook} from "./scenes/Hook";
import {ProblemCard} from "./scenes/ProblemCard";
import {Trainer} from "./scenes/Trainer";
import {Upgrade} from "./scenes/Upgrade";

export const RemotionRoot = () => {
  return (
    <>
      <Composition
        id="RealGameplay"
        component={RealGameplay}
        durationInFrames={reelFrames(30)}
        fps={30}
        width={1920}
        height={1080}
      />
      <Composition
        id="RealGameplayEn"
        component={RealGameplayEn}
        durationInFrames={reelFrames(30)}
        fps={30}
        width={1920}
        height={1080}
      />
      <Composition
        id="JetMathSpot"
        component={JetMathSpot}
        durationInFrames={450}
        fps={30}
        width={1920}
        height={1080}
      />
      <Folder name="Scenes">
        <Composition
          id="Hook"
          component={Hook}
          durationInFrames={90}
          fps={30}
          width={1920}
          height={1080}
          defaultProps={{
            equation: "8 × 7",
            answer: "56",
            style: {
              backgroundColor: "#7EBFEE",
            },
          }}
        />
        <Composition
          id="Trainer"
          component={Trainer}
          durationInFrames={120}
          fps={30}
          width={1920}
          height={1080}
          defaultProps={{
            style: {
              backgroundColor: "#F7F1E4",
            },
          }}
        />
        <Composition
          id="Upgrade"
          component={Upgrade}
          durationInFrames={90}
          fps={30}
          width={1920}
          height={1080}
          defaultProps={{
            style: {
              backgroundColor: "#F7F1E4",
            },
          }}
        />
        <Composition
          id="BossEscape"
          component={BossEscape}
          durationInFrames={120}
          fps={30}
          width={1920}
          height={1080}
          defaultProps={{
            style: {
              backgroundColor: "#7EBFEE",
            },
          }}
        />
        <Composition
          id="EndCard"
          component={EndCard}
          durationInFrames={62}
          fps={30}
          width={1920}
          height={1080}
          defaultProps={{
            style: {
              backgroundColor: "#F7F1E4",
            },
          }}
        />
      </Folder>
      <Folder name="Elements">
        <Composition
          id="ProblemCard"
          component={ProblemCard}
          durationInFrames={90}
          fps={30}
          width={1280}
          height={150}
          defaultProps={{
            prompt: "9 + 6 =",
            answer: "15",
            showAt: 0,
            solveAt: 12,
            style: {
              width: 1280,
              height: 150,
            },
          }}
        />
      </Folder>
    </>
  );
};
