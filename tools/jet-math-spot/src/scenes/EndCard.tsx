import {Easing, Interactive, interpolate, useCurrentFrame, useVideoConfig} from "remotion";
import "../fonts";
import {Paper} from "../look";
import {PlaneRig} from "../PlaneSprite";

const EndCardInner = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  return (
    <>
      <Paper />
      <Interactive.Div
        name="Game title"
        style={{
          position: "absolute",
          left: 160,
          right: 160,
          top: 250,
          textAlign: "center",
          fontFamily: "Rubik Doodle Shadow, cursive",
          fontSize: 120,
          lineHeight: 1.05,
          color: "#2A3340",
          scale: interpolate(frame, [0.1 * fps, 0.45 * fps], [0.7, 1], {
            easing: Easing.spring({damping: 14}),
            output: "perceptual-scale",
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          opacity: interpolate(frame, [0.05 * fps, 0.3 * fps], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        Улётная математика
      </Interactive.Div>
      <Interactive.Div
        name="Tagline"
        style={{
          position: "absolute",
          left: 200,
          right: 200,
          top: 560,
          textAlign: "center",
          fontFamily: "Nunito, sans-serif",
          fontWeight: 800,
          fontSize: 72,
          color: "#38704D",
          opacity: interpolate(frame, [0.35 * fps, 0.6 * fps], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          translate: interpolate(frame, [0.35 * fps, 0.65 * fps], ["0px 24px", "0px 0px"], {
            easing: Easing.bezier(0.16, 1, 0.3, 1),
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        Решай. Апгрейдь. Улетай.
      </Interactive.Div>
      <Interactive.Div
        name="End plane"
        style={{
          position: "absolute",
          left: 0,
          top: 760,
          translate: interpolate(frame, [0.25 * fps, 1.5 * fps], ["-500px 0px", "1700px 0px"], {
            easing: Easing.bezier(0.4, 0, 0.2, 1),
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        <PlaneRig column={4} row={2} width={420} />
      </Interactive.Div>
    </>
  );
};

export const EndCard = Interactive.create({
  Component: EndCardInner,
  layout: "absolute-fill",
  schema: {
    ...Interactive.backgroundSchema,
  },
});
