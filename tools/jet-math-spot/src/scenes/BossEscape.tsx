import {Img, Easing, Interactive, interpolate, staticFile, useCurrentFrame, useVideoConfig} from "remotion";
import "../fonts";
import {Sky, Vignette} from "../look";
import {PlaneRig} from "../PlaneSprite";

const BossEscapeInner = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const row = frame < 0.7 * fps ? 1 : frame < 1.4 * fps ? 2 : frame < 2.1 * fps ? 1 : frame < 2.5 * fps ? 0 : 2;

  return (
    <>
      <Sky />
      <Interactive.Div
        name="Boss title"
        style={{
          position: "absolute",
          left: 160,
          top: 70,
          fontFamily: "Rubik Doodle Shadow, cursive",
          fontSize: 120,
          color: "#2A3340",
          opacity: interpolate(frame, [0, 0.25 * fps, 2.4 * fps, 2.7 * fps], [0, 1, 1, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        БОСС
      </Interactive.Div>
      <Interactive.Div
        name="Boss airship"
        style={{
          position: "absolute",
          left: 1040,
          top: 240,
          width: 760,
          height: 500,
          translate: interpolate(
            frame,
            [0, 0.4 * fps, 2.45 * fps, 3.7 * fps],
            ["480px 30px", "0px 0px", "0px 0px", "60px 720px"],
            {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            },
          ),
          rotate: interpolate(frame, [2.45 * fps, 3.6 * fps], ["0deg", "22deg"], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          opacity: interpolate(frame, [3.2 * fps, 3.7 * fps], [1, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        <Img
          name="Airship"
          src={staticFile("airship.svg")}
          style={{width: 760, height: 438}}
        />
        <Img
          name="Propeller"
          src={staticFile("propeller.svg")}
          style={{
            position: "absolute",
            left: 96,
            top: 78,
            width: 58,
            height: 160,
            rotate: interpolate(frame, [0, 0.2 * fps], ["0deg", "360deg"], {
              extrapolateLeft: "clamp",
              extrapolateRight: "extend",
            }),
          }}
        />
        <div
          style={{
            position: "absolute",
            left: 180,
            top: 0,
            display: "flex",
            gap: 18,
          }}
        >
          <div
            style={{
              width: 54,
              height: 54,
              borderRadius: 27,
              backgroundColor: "#E0B15A",
              border: "5px solid #2A3340",
              scale: interpolate(frame, [0.85 * fps, 1.05 * fps], [1, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
                output: "perceptual-scale",
              }),
            }}
          />
          <div
            style={{
              width: 54,
              height: 54,
              borderRadius: 27,
              backgroundColor: "#E0B15A",
              border: "5px solid #2A3340",
              scale: interpolate(frame, [1.55 * fps, 1.75 * fps], [1, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
                output: "perceptual-scale",
              }),
            }}
          />
          <div
            style={{
              width: 54,
              height: 54,
              borderRadius: 27,
              backgroundColor: "#E0B15A",
              border: "5px solid #2A3340",
              scale: interpolate(frame, [2.25 * fps, 2.45 * fps], [1, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
                output: "perceptual-scale",
              }),
            }}
          />
        </div>
      </Interactive.Div>
      <Interactive.Div
        name="Ink shot"
        style={{
          position: "absolute",
          left: 520,
          top: 620,
          width: 42,
          height: 42,
          borderRadius: 21,
          backgroundColor: "#2A3340",
          opacity: interpolate(frame, [0.7 * fps, 0.78 * fps, 1.05 * fps], [0, 1, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          translate: interpolate(frame, [0.7 * fps, 1.05 * fps], ["0px 0px", "640px -180px"], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      />
      <Interactive.Div
        name="Ink shot two"
        style={{
          position: "absolute",
          left: 500,
          top: 430,
          width: 42,
          height: 42,
          borderRadius: 21,
          backgroundColor: "#2A3340",
          opacity: interpolate(frame, [1.4 * fps, 1.48 * fps, 1.75 * fps], [0, 1, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          translate: interpolate(frame, [1.4 * fps, 1.75 * fps], ["0px 0px", "680px 40px"], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      />
      <Interactive.Div
        name="Ink shot three"
        style={{
          position: "absolute",
          left: 540,
          top: 560,
          width: 48,
          height: 48,
          borderRadius: 24,
          backgroundColor: "#2A3340",
          opacity: interpolate(frame, [2.1 * fps, 2.18 * fps, 2.45 * fps], [0, 1, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          translate: interpolate(frame, [2.1 * fps, 2.45 * fps], ["0px 0px", "620px -40px"], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      />
      <Interactive.Div
        name="Escape plane"
        style={{
          position: "absolute",
          left: 140,
          top: 460,
          translate: interpolate(
            frame,
            [0, 0.7 * fps, 1.4 * fps, 2.1 * fps, 2.5 * fps, 3.7 * fps],
            ["0px 40px", "20px 180px", "0px -90px", "30px 120px", "40px 10px", "1100px -680px"],
            {
              easing: Easing.bezier(0.4, 0, 0.2, 1),
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            },
          ),
          rotate: interpolate(
            frame,
            [0, 0.7 * fps, 1.4 * fps, 2.1 * fps, 2.5 * fps, 3.7 * fps],
            ["10deg", "18deg", "-16deg", "14deg", "-4deg", "-48deg"],
            {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            },
          ),
        }}
      >
        <PlaneRig column={4} row={row} width={480} />
      </Interactive.Div>
      <Interactive.Div
        name="Fly away"
        style={{
          position: "absolute",
          left: 480,
          top: 760,
          fontFamily: "Rubik Doodle Shadow, cursive",
          fontSize: 160,
          color: "#2A3340",
          backgroundColor: "#F3E6C8",
          border: "8px solid #2A3340",
          borderRadius: 32,
          boxShadow: "0 10px 0 #2A3340",
          padding: "4px 36px",
          opacity: interpolate(frame, [2.7 * fps, 2.95 * fps], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          scale: interpolate(frame, [2.7 * fps, 3.05 * fps], [0.5, 1], {
            easing: Easing.spring({damping: 12}),
            output: "perceptual-scale",
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          rotate: "-4deg",
        }}
      >
        УЛЁТ
      </Interactive.Div>
      <div
        style={{
          position: "absolute",
          inset: 0,
          backgroundColor: "#FFFFFF",
          pointerEvents: "none",
          opacity: interpolate(
            frame,
            [0.85 * fps, 0.95 * fps, 1.15 * fps, 1.55 * fps, 1.65 * fps, 1.85 * fps, 2.25 * fps, 2.4 * fps, 2.6 * fps],
            [0, 0.4, 0, 0, 0.5, 0, 0, 0.7, 0],
            {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            },
          ),
        }}
      />
      <Vignette />
    </>
  );
};

export const BossEscape = Interactive.create({
  Component: BossEscapeInner,
  layout: "absolute-fill",
  schema: {
    ...Interactive.backgroundSchema,
  },
});
