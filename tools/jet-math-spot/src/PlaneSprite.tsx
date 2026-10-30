import {Img, interpolate, staticFile, useCurrentFrame} from "remotion";

const CELL_W = 288;
const CELL_H = 108;

export const PlaneSprite: React.FC<{
  readonly column: number;
  readonly row: number;
  readonly width: number;
}> = ({column, row, width}) => {
  const scale = width / CELL_W;
  return (
    <div
      style={{
        width,
        height: CELL_H * scale,
        overflow: "hidden",
      }}
    >
      <Img
        src={staticFile("planes.png")}
        style={{
          width: CELL_W * 5 * scale,
          height: CELL_H * 3 * scale,
          marginLeft: -column * CELL_W * scale,
          marginTop: -row * CELL_H * scale,
        }}
      />
    </div>
  );
};

export const PlaneRig: React.FC<{
  readonly column: number;
  readonly row: number;
  readonly width: number;
}> = ({column, row, width}) => {
  const frame = useCurrentFrame();
  const height = (width / CELL_W) * CELL_H;
  const flicker = interpolate(frame % 8, [0, 4, 8], [1, 0.7, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <div style={{position: "relative", width, height}}>
      <div
        style={{
          position: "absolute",
          left: -width * 0.1,
          top: height * 0.34,
          width: width * 0.16,
          height: height * 0.3,
          borderRadius: 999,
          background:
            "radial-gradient(circle, #FFE56A 0%, #FF7A1A 68%, rgba(255,122,26,0) 72%)",
          scale: flicker,
        }}
      />
      <PlaneSprite column={column} row={row} width={width} />
    </div>
  );
};
