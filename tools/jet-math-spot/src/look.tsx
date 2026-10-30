export const Sky = () => {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        background: "linear-gradient(#69B7EA 0%, #C5E8FF 58%, #F7F1E4 100%)",
      }}
    >
      <div
        style={{
          position: "absolute",
          left: 120,
          top: 80,
          width: 280,
          height: 90,
          borderRadius: 80,
          backgroundColor: "rgba(255,255,255,0.85)",
        }}
      />
      <div
        style={{
          position: "absolute",
          left: 1460,
          top: 140,
          width: 220,
          height: 70,
          borderRadius: 70,
          backgroundColor: "rgba(255,255,255,0.75)",
        }}
      />
      <div
        style={{
          position: "absolute",
          left: 860,
          top: 40,
          width: 160,
          height: 50,
          borderRadius: 50,
          backgroundColor: "rgba(255,255,255,0.7)",
        }}
      />
    </div>
  );
};

export const Paper = () => {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        backgroundColor: "#F7F1E4",
        backgroundImage:
          "linear-gradient(to right, rgba(42,51,64,0.09) 2px, transparent 2px), linear-gradient(to bottom, rgba(42,51,64,0.09) 2px, transparent 2px)",
        backgroundSize: "56px 56px",
      }}
    >
      <div
        style={{
          position: "absolute",
          left: 128,
          top: 0,
          bottom: 0,
          width: 4,
          backgroundColor: "#E85A5A",
        }}
      />
    </div>
  );
};

export const Vignette = () => {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        boxShadow: "inset 0 0 220px rgba(42,51,64,0.28)",
        pointerEvents: "none",
      }}
    />
  );
};
