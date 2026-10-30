import {Easing, Interactive, interpolate, useCurrentFrame, useVideoConfig} from "remotion";
import "../fonts";
import {Paper} from "../look";
import {PlaneRig} from "../PlaneSprite";

const coins = [0, 45, 90, 135, 180, 225, 270, 315];

const UpgradeInner = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  return (
    <>
      <Paper />
      <Interactive.Div
        name="Upgrade title"
        style={{
          position: "absolute",
          left: 180,
          top: 70,
          fontFamily: "Rubik Doodle Shadow, cursive",
          fontSize: 130,
          color: "#2A3340",
          opacity: interpolate(frame, [0, 0.25 * fps], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        АПГРЕЙД
      </Interactive.Div>
      <Interactive.Div
        name="Pencil"
        style={{
          position: "absolute",
          left: 620,
          top: 300,
          opacity: interpolate(frame, [0.45 * fps, 0.7 * fps], [1, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          scale: interpolate(frame, [0, 0.3 * fps], [0.7, 1], {
            easing: Easing.spring({damping: 14}),
            output: "perceptual-scale",
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        <PlaneRig column={0} row={0} width={700} />
      </Interactive.Div>
      <Interactive.Div
        name="Pen"
        style={{
          position: "absolute",
          left: 620,
          top: 300,
          opacity: interpolate(
            frame,
            [0.5 * fps, 0.75 * fps, 1.15 * fps, 1.4 * fps],
            [0, 1, 1, 0],
            {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            },
          ),
        }}
      >
        <PlaneRig column={1} row={0} width={700} />
      </Interactive.Div>
      <Interactive.Div
        name="Marker"
        style={{
          position: "absolute",
          left: 620,
          top: 300,
          opacity: interpolate(
            frame,
            [1.2 * fps, 1.45 * fps, 1.8 * fps, 2.05 * fps],
            [0, 1, 1, 0],
            {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            },
          ),
        }}
      >
        <PlaneRig column={2} row={0} width={700} />
      </Interactive.Div>
      <Interactive.Div
        name="Gold pen"
        style={{
          position: "absolute",
          left: 560,
          top: 270,
          opacity: interpolate(frame, [1.9 * fps, 2.15 * fps], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          scale: interpolate(frame, [1.9 * fps, 2.3 * fps], [0.6, 1.08], {
            easing: Easing.spring({damping: 12}),
            output: "perceptual-scale",
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        <PlaneRig column={4} row={0} width={820} />
      </Interactive.Div>
      {coins.map((deg) => {
        const x = Math.round(Math.cos((deg * Math.PI) / 180) * 280);
        const y = Math.round(Math.sin((deg * Math.PI) / 180) * 180);
        return (
          <div
            key={deg}
            style={{
              position: "absolute",
              width: 42,
              height: 42,
              borderRadius: 21,
              backgroundColor: "#F0C94A",
              border: "4px solid #2A3340",
              opacity: interpolate(frame, [2 * fps, 2.15 * fps, 2.7 * fps], [0, 1, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
              left: 960 + interpolate(frame, [2 * fps, 2.55 * fps], [0, x], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
              top: 420 + interpolate(frame, [2 * fps, 2.55 * fps], [0, y], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
            }}
          />
        );
      })}
      <Interactive.Div
        name="Fast name"
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 820,
          textAlign: "center",
          fontFamily: "Nunito, sans-serif",
          fontWeight: 900,
          fontSize: 80,
          color: "#2A3340",
          opacity: interpolate(frame, [0.15 * fps, 0.35 * fps, 0.55 * fps, 0.75 * fps], [0, 1, 1, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        Быстрый
      </Interactive.Div>
      <Interactive.Div
        name="Blue name"
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 820,
          textAlign: "center",
          fontFamily: "Nunito, sans-serif",
          fontWeight: 900,
          fontSize: 80,
          color: "#2A3340",
          opacity: interpolate(frame, [0.7 * fps, 0.9 * fps, 1.2 * fps, 1.4 * fps], [0, 1, 1, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        Синий
      </Interactive.Div>
      <Interactive.Div
        name="Green name"
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 820,
          textAlign: "center",
          fontFamily: "Nunito, sans-serif",
          fontWeight: 900,
          fontSize: 80,
          color: "#2A3340",
          opacity: interpolate(frame, [1.35 * fps, 1.55 * fps, 1.85 * fps, 2.05 * fps], [0, 1, 1, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        Зелёный
      </Interactive.Div>
      <Interactive.Div
        name="Gold name"
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 800,
          textAlign: "center",
          fontFamily: "Nunito, sans-serif",
          fontWeight: 900,
          fontSize: 88,
          color: "#8A5A10",
          opacity: interpolate(frame, [2.05 * fps, 2.3 * fps], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          scale: interpolate(frame, [2.05 * fps, 2.35 * fps], [0.7, 1], {
            easing: Easing.spring({damping: 12}),
            output: "perceptual-scale",
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        Золотой
      </Interactive.Div>
    </>
  );
};

export const Upgrade = Interactive.create({
  Component: UpgradeInner,
  layout: "absolute-fill",
  schema: {
    ...Interactive.backgroundSchema,
  },
});
