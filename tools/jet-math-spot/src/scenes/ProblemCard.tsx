import type React from "react";
import {Easing, Interactive, interpolate, useCurrentFrame} from "remotion";
import "../fonts";

const ProblemCardInner = ({
  prompt,
  answer,
  showAt,
  solveAt,
  style,
}: {
  readonly prompt: string;
  readonly answer: string;
  readonly showAt: number;
  readonly solveAt: number;
  readonly style: React.CSSProperties;
}) => {
  const frame = useCurrentFrame();

  return (
    <div style={style}>
      <div
        style={{
          width: "100%",
          height: "100%",
          boxSizing: "border-box",
          borderRadius: 28,
          backgroundColor: "#F3E6C8",
          border: "6px solid #2A3340",
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
          opacity: interpolate(frame, [showAt, showAt + 8], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          translate: interpolate(
            frame,
            [showAt, showAt + 10],
            ["80px 0px", "0px 0px"],
            {
              easing: Easing.bezier(0.16, 1, 0.3, 1),
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            },
          ),
        }}
      >
        <div>{prompt}</div>
        <div style={{display: "flex", alignItems: "center", gap: 28}}>
          <div
            style={{
              color: "#38704D",
              fontWeight: 900,
              scale: interpolate(frame, [solveAt, solveAt + 8], [0, 1], {
                easing: Easing.spring({damping: 12}),
                output: "perceptual-scale",
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
            }}
          >
            {answer}
          </div>
          <svg width="78" height="78" viewBox="0 0 78 78">
            <circle
              cx="39"
              cy="39"
              r="30"
              fill="none"
              stroke="#38704D"
              strokeWidth="8"
              style={{
                opacity: interpolate(frame, [solveAt, solveAt + 6], [0, 1], {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                }),
              }}
            />
            <path
              d="M22 40 L34 52 L56 26"
              fill="none"
              stroke="#38704D"
              strokeWidth="8"
              strokeLinecap="round"
              strokeLinejoin="round"
              style={{
                opacity: interpolate(frame, [solveAt + 2, solveAt + 8], [0, 1], {
                  extrapolateLeft: "clamp",
                  extrapolateRight: "clamp",
                }),
              }}
            />
          </svg>
        </div>
      </div>
    </div>
  );
};

export const ProblemCard = Interactive.create({
  Component: ProblemCardInner,
  layout: "none",
  schema: {
    prompt: {type: "string", default: "9 + 6 =", description: "Problem"},
    answer: {type: "string", default: "15", description: "Answer"},
    showAt: {
      type: "number",
      default: 0,
      min: 0,
      step: 1,
      description: "Show at frame",
      hiddenFromList: false,
      keyframable: false,
    },
    solveAt: {
      type: "number",
      default: 12,
      min: 0,
      step: 1,
      description: "Solve at frame",
      hiddenFromList: false,
      keyframable: false,
    },
  },
});
