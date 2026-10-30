import {Easing, Interactive, interpolate, useCurrentFrame, useVideoConfig} from "remotion";
import "../fonts";
import {Sky, Vignette} from "../look";
import {PlaneRig} from "../PlaneSprite";

const streaks = [150, 310, 470, 640, 800, 960];

const HookInner = ({
  equation,
  answer,
}: {
  readonly equation: string;
  readonly answer: string;
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  return (
    <>
      <Sky />
      <div
        style={{
          position: "absolute",
          inset: 0,
          scale: interpolate(frame, [0, 0.25 * fps, 0.8 * fps, 1 * fps], [1.18, 1, 1.06, 1], {
            easing: Easing.bezier(0.16, 1, 0.3, 1),
            output: "perceptual-scale",
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          translate: interpolate(
            frame,
            [0.7 * fps, 0.78 * fps, 0.86 * fps, 0.94 * fps, 1.05 * fps],
            ["0px 0px", "-22px 12px", "16px -14px", "-8px 6px", "0px 0px"],
            {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            },
          ),
        }}
      >
        {streaks.map((top, index) => (
          <div
            key={top}
            style={{
              position: "absolute",
              top,
              width: 180 + (index % 3) * 90,
              height: 12,
              borderRadius: 8,
              backgroundColor: "rgba(255,255,255,0.8)",
              left: interpolate(
                frame,
                [0, 0.7 * fps],
                [1500 - index * 180, -700 - index * 40],
                {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                },
              ),
              opacity: interpolate(frame, [0, 0.45 * fps, 0.9 * fps], [1, 0.85, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
            }}
          />
        ))}
        <Interactive.Div
          name="Example"
          style={{
            position: "absolute",
            left: 150,
            top: 250,
            fontFamily: "Rubik Doodle Shadow, cursive",
            fontSize: 210,
            color: "#2A3340",
            lineHeight: 1,
            scale: interpolate(frame, [0, 0.3 * fps], [1.25, 1], {
              easing: Easing.bezier(0.16, 1, 0.3, 1),
              output: "perceptual-scale",
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          {equation}
        </Interactive.Div>
        <Interactive.Div
          name="Pencil plane"
          style={{
            position: "absolute",
            left: 40,
            top: 390,
            zIndex: 3,
            translate: interpolate(
              frame,
              [0, 0.7 * fps, 1.15 * fps, 2.6 * fps],
              ["-680px 10px", "760px -50px", "80px 150px", "120px 160px"],
              {
                easing: Easing.bezier(0.2, 0.8, 0.2, 1),
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              },
            ),
            rotate: interpolate(
              frame,
              [0, 0.7 * fps, 1.2 * fps, 2.6 * fps],
              ["-14deg", "-2deg", "8deg", "4deg"],
              {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              },
            ),
          }}
        >
          <PlaneRig column={0} row={0} width={520} />
        </Interactive.Div>
        <Interactive.Div
          name="Unknown balloon"
          style={{
            position: "absolute",
            left: 1180,
            top: 180,
            zIndex: 2,
            width: 420,
            height: 420,
            borderRadius: 210,
            backgroundColor: "#F7F1E4",
            border: "10px solid #2A3340",
            boxShadow: "0 16px 0 #2A3340",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontFamily: "Rubik Doodle Shadow, cursive",
            fontSize: 220,
            color: "#E85A5A",
            rotate: interpolate(
              frame,
              [0, 0.15 * fps, 0.3 * fps, 0.45 * fps, 0.6 * fps, 0.75 * fps],
              ["-7deg", "7deg", "-6deg", "5deg", "-3deg", "0deg"],
              {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              },
            ),
            scale: interpolate(frame, [0.68 * fps, 0.86 * fps], [1, 1.35], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
              output: "perceptual-scale",
            }),
            opacity: interpolate(frame, [0.72 * fps, 0.88 * fps], [1, 0], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          ?
        </Interactive.Div>
        <Interactive.Div
          name="Answer stamp"
          style={{
            position: "absolute",
            left: 1210,
            top: 210,
            zIndex: 4,
            width: 360,
            height: 360,
            borderRadius: 180,
            border: "16px solid #38704D",
            color: "#38704D",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontFamily: "Rubik Doodle Shadow, cursive",
            fontSize: 180,
            backgroundColor: "rgba(243,230,200,0.94)",
            opacity: interpolate(frame, [0.8 * fps, 0.96 * fps], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
            scale: interpolate(frame, [0.8 * fps, 1.12 * fps], [1.8, 1], {
              easing: Easing.spring({damping: 12}),
              output: "perceptual-scale",
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
            rotate: interpolate(frame, [0.8 * fps, 1.12 * fps], ["-18deg", "-8deg"], {
              easing: Easing.spring({damping: 14}),
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          {answer}
        </Interactive.Div>
        <Interactive.Div
          name="Trainer banner"
          style={{
            position: "absolute",
            left: 360,
            top: 800,
            zIndex: 5,
            width: 1200,
            textAlign: "center",
            fontFamily: "Rubik Doodle Shadow, cursive",
            fontSize: 92,
            color: "#2A3340",
            backgroundColor: "#F3E6C8",
            border: "6px solid #2A3340",
            borderRadius: 28,
            boxShadow: "0 8px 0 #2A3340",
            paddingTop: 8,
            paddingBottom: 8,
            opacity: interpolate(frame, [1 * fps, 1.25 * fps], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
            translate: interpolate(frame, [1 * fps, 1.3 * fps], ["0px 50px", "0px 0px"], {
              easing: Easing.spring({damping: 14}),
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
            rotate: interpolate(frame, [1 * fps, 1.3 * fps], ["-8deg", "-2deg"], {
              easing: Easing.spring({damping: 14}),
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          СУПЕР-ТРЕНАЖЁР
        </Interactive.Div>
      </div>
      <div
        style={{
          position: "absolute",
          inset: 0,
          backgroundColor: "#FFFFFF",
          pointerEvents: "none",
          opacity: interpolate(
            frame,
            [0, 0.16 * fps, 0.68 * fps, 0.76 * fps, 0.92 * fps],
            [0.55, 0, 0, 0.75, 0],
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

export const Hook = Interactive.create({
  Component: HookInner,
  layout: "absolute-fill",
  schema: {
    ...Interactive.backgroundSchema,
    equation: {type: "string", default: "8 × 7", description: "Example"},
    answer: {type: "string", default: "56", description: "Answer"},
  },
});
