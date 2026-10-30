import {Easing, Interactive, interpolate, useCurrentFrame, useVideoConfig} from "remotion";
import "../fonts";
import {Paper} from "../look";
import {ProblemCard} from "./ProblemCard";

const TrainerInner = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  return (
    <>
      <Paper />
      <Interactive.Div
        name="Examples title"
        style={{
          position: "absolute",
          left: 220,
          top: 70,
          fontFamily: "Rubik Doodle Shadow, cursive",
          fontSize: 120,
          color: "#2A3340",
          opacity: interpolate(frame, [0, 0.25 * fps], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          translate: interpolate(frame, [0, 0.3 * fps], ["0px -30px", "0px 0px"], {
            easing: Easing.spring({damping: 16}),
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        ПРИМЕРЫ
      </Interactive.Div>
      <Interactive.Div
        name="Streak"
        style={{
          position: "absolute",
          right: 180,
          top: 80,
          fontFamily: "Nunito, sans-serif",
          fontWeight: 900,
          fontSize: 92,
          color: "#38704D",
          opacity: interpolate(frame, [3.3 * fps, 3.5 * fps], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          scale: interpolate(frame, [3.3 * fps, 3.6 * fps], [0.4, 1], {
            easing: Easing.spring({damping: 12}),
            output: "perceptual-scale",
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        серия ×4
      </Interactive.Div>
      <ProblemCard
        name="Addition"
        prompt="9 + 6 ="
        answer="15"
        showAt={0.15 * fps}
        solveAt={0.55 * fps}
        style={{
          position: "absolute",
          left: 220,
          top: 250,
          width: 1280,
          height: 150,
        }}
      />
      <ProblemCard
        name="Subtraction"
        prompt="14 − 8 ="
        answer="6"
        showAt={0.85 * fps}
        solveAt={1.3 * fps}
        style={{
          position: "absolute",
          left: 220,
          top: 420,
          width: 1280,
          height: 150,
        }}
      />
      <Interactive.Div
        name="Missing operand"
        style={{
          position: "absolute",
          left: 220,
          top: 590,
          width: 1280,
          height: 150,
          boxSizing: "border-box",
          borderRadius: 28,
          backgroundColor: "#F3E6C8",
          border: "6px solid #E39B2B",
          boxShadow: "0 10px 0 #2A3340",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          paddingLeft: 40,
          paddingRight: 28,
          fontFamily: "Nunito, sans-serif",
          fontWeight: 800,
          fontSize: 76,
          color: "#2A3340",
          opacity: interpolate(frame, [1.55 * fps, 1.55 * fps + 8], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          translate: interpolate(
            frame,
            [1.55 * fps, 1.55 * fps + 10],
            ["80px 0px", "0px 0px"],
            {
              easing: Easing.bezier(0.16, 1, 0.3, 1),
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            },
          ),
        }}
      >
        <div style={{display: "flex", alignItems: "center", gap: 16}}>
          <div style={{position: "relative", width: 90, height: 90}}>
            <div
              style={{
                position: "absolute",
                inset: 0,
                color: "#E85A5A",
                opacity: interpolate(frame, [2.15 * fps, 2.35 * fps], [1, 0], {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                }),
              }}
            >
              ?
            </div>
            <div
              style={{
                position: "absolute",
                inset: 0,
                color: "#38704D",
                fontWeight: 900,
                opacity: interpolate(frame, [2.2 * fps, 2.4 * fps], [0, 1], {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                }),
                scale: interpolate(frame, [2.2 * fps, 2.45 * fps], [1.5, 1], {
                  easing: Easing.spring({damping: 12}),
                  output: "perceptual-scale",
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                }),
              }}
            >
              4
            </div>
          </div>
          <div>+ 3 = 7</div>
        </div>
        <div
          style={{
            fontFamily: "Nunito, sans-serif",
            fontWeight: 900,
            fontSize: 36,
            letterSpacing: 1,
            color: "#E39B2B",
            border: "4px solid #E39B2B",
            borderRadius: 14,
            padding: "8px 16px",
            opacity: interpolate(frame, [1.55 * fps, 1.75 * fps], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          НАЙДИ ЧИСЛО
        </div>
      </Interactive.Div>
      <ProblemCard
        name="Division"
        prompt="48 ÷ 6 ="
        answer="8"
        showAt={2.55 * fps}
        solveAt={3.15 * fps}
        style={{
          position: "absolute",
          left: 220,
          top: 760,
          width: 1280,
          height: 150,
        }}
      />
    </>
  );
};

export const Trainer = Interactive.create({
  Component: TrainerInner,
  layout: "absolute-fill",
  schema: {
    ...Interactive.backgroundSchema,
  },
});
