import {Audio, Video} from "@remotion/media";
import {
  AbsoluteFill,
  Easing,
  Interactive,
  Sequence,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import "./fonts";

const frames = (seconds: number, fps: number) => Math.round(seconds * fps);

type Cut = {
  name: string;
  src: string;
  trim: number;
  dur: number;
  note: string;
  sub?: string;
};

// Source seconds are into the recorded takes (chase = addition level 3, boss = addition level 5).
const CUTS: Cut[] = [
  {
    name: "Escape",
    src: "clips/chase_l3.mp4",
    trim: 14.5,
    dur: 3.6,
    note: "Верный ответ — и погоня позади",
    sub: "Так ребёнок влюбляется в счёт",
  },
  {
    name: "Upgrade",
    src: "clips/boss_l5.mp4",
    trim: 10.0,
    dur: 3.2,
    note: "Новый самолёт прилетает за победы",
    sub: "Красивее — да. Считать всё равно самому",
  },
  {
    name: "Attack",
    src: "clips/boss_l5.mp4",
    trim: 16.7,
    dur: 3.4,
    note: "Дирижабль отступает только перед счётом",
    sub: "Каждая цифра становится выстрелом",
  },
  {
    name: "Finish",
    src: "clips/boss_l5.mp4",
    trim: 21.6,
    dur: 3.0,
    note: "Момент, ради которого открывают игру",
  },
  {
    name: "Trophies",
    src: "clips/trophy_ru.mp4",
    trim: 0.3,
    dur: 2.0,
    note: "Сданный экзамен остаётся кубком",
    sub: "Прогресс виден с первого взгляда",
  },
  {
    name: "Mistakes",
    src: "clips/trophy_ru.mp4",
    trim: 2.5,
    dur: 3.6,
    note: "Промахи возвращаются, пока не станут победой",
    sub: "Учит именно то, что не получалось",
  },
];

const EN_CUTS: Cut[] = [
  {
    name: "Escape",
    src: "clips/chase_l3_en.mp4",
    trim: 14.5,
    dur: 3.6,
    note: "A right answer leaves the chase behind",
    sub: "This is how a child falls in love with math",
  },
  {
    name: "Upgrade",
    src: "clips/boss_l5_en.mp4",
    trim: 10.0,
    dur: 3.2,
    note: "Every victory brings a new plane",
    sub: "Shinier, yes. The math is still theirs",
  },
  {
    name: "Attack",
    src: "clips/boss_l5_en.mp4",
    trim: 16.7,
    dur: 3.4,
    note: "The airship only backs down for the math",
    sub: "Every number turns into a shot",
  },
  {
    name: "Finish",
    src: "clips/boss_l5_en.mp4",
    trim: 21.6,
    dur: 3.0,
    note: "The moment kids open the game to see",
  },
  {
    name: "Trophies",
    src: "clips/trophy_en.mp4",
    trim: 0.3,
    dur: 2.0,
    note: "A passed exam stays on the shelf",
    sub: "Progress a parent can see at a glance",
  },
  {
    name: "Mistakes",
    src: "clips/trophy_en.mp4",
    trim: 2.5,
    dur: 3.6,
    note: "Misses return until they turn into wins",
    sub: "It practices exactly what didn't stick",
  },
];

const VICTORY = {trim: 25.0, dur: 3.4};

type CardCopy = {
  src: string;
  grade: string;
  title: string;
  line: string;
  store: string;
  huge: boolean;
};

const RU_CARD: CardCopy = {
  src: "clips/boss_l5.mp4",
  grade: "Для 1–4 класса",
  title: "Улётная математика",
  line: "Счёт, который дети принимают за приключение",
  store: "Скачать в Google Play",
  huge: false,
};

const EN_CARD: CardCopy = {
  src: "clips/boss_l5_en.mp4",
  grade: "Grades 1–4",
  title: "JET MATH",
  line: "The math kids treat as an adventure",
  store: "GOOGLE PLAY",
  huge: true,
};

export const reelFrames = (fps: number, cuts: Cut[] = CUTS) =>
  cuts.reduce((sum, cut) => sum + frames(cut.dur, fps), 0) + frames(VICTORY.dur, fps);

const timeline = (fps: number, cuts: Cut[] = CUTS) => {
  const points: Record<string, number> = {};
  let cursor = 0;
  for (const cut of cuts) {
    points[cut.name] = cursor;
    cursor += frames(cut.dur, fps);
  }
  points.Victory = cursor;
  points.End = cursor + frames(VICTORY.dur, fps);
  return points;
};

const Note = ({title, sub}: {title: string; sub?: string}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const pop = interpolate(frame, [0, 0.22 * fps], [0.9, 1], {
    easing: Easing.bezier(0.16, 1, 0.3, 1),
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const opacity = interpolate(frame, [0, 0.12 * fps], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <Interactive.Div
      name={title}
      style={{
        position: "absolute",
        left: 220,
        width: 1480,
        bottom: 54,
        opacity,
        scale: pop,
        transformOrigin: "center bottom",
        backgroundColor: "#F7F1E4",
        border: "6px solid #2A3340",
        borderRadius: 28,
        padding: "18px 36px 22px",
        textAlign: "center",
        boxShadow: "8px 10px 0 #2A3340",
      }}
    >
      <div
        style={{
          fontFamily: "Nunito, sans-serif",
          fontWeight: 900,
          fontSize: 48,
          lineHeight: 1.12,
          color: "#2A3340",
        }}
      >
        {title}
      </div>
      {sub ? (
        <div
          style={{
            marginTop: 6,
            fontFamily: "Nunito, sans-serif",
            fontWeight: 800,
            fontSize: 32,
            lineHeight: 1.15,
            color: "#38704D",
          }}
        >
          {sub}
        </div>
      ) : null}
    </Interactive.Div>
  );
};

const Footage = ({cut}: {cut: Cut}) => {
  const {fps} = useVideoConfig();

  return (
    <AbsoluteFill>
      <Video
        src={staticFile(cut.src)}
        trimBefore={frames(cut.trim, fps)}
        durationInFrames={frames(cut.dur, fps)}
        muted
        objectFit="cover"
        style={{width: "100%", height: "100%"}}
      />
      <Note title={cut.note} sub={cut.sub} />
    </AbsoluteFill>
  );
};

const VictoryCard = ({card}: {card: CardCopy}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const opacity = interpolate(frame, [0.25 * fps, 0.55 * fps], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const pop = interpolate(frame, [0.25 * fps, 0.6 * fps], [0.92, 1], {
    easing: Easing.bezier(0.16, 1, 0.3, 1),
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill>
      <Video
        src={staticFile(card.src)}
        trimBefore={frames(VICTORY.trim, fps)}
        durationInFrames={frames(VICTORY.dur, fps)}
        muted
        objectFit="cover"
        style={{width: "100%", height: "100%"}}
      />
      <Interactive.Div
        name="Age and promise"
        style={{
          position: "absolute",
          left: card.huge ? 100 : 180,
          width: card.huge ? 1720 : 1560,
          bottom: 48,
          opacity,
          scale: pop,
          transformOrigin: "center bottom",
          backgroundColor: "#F7F1E4",
          border: "6px solid #2A3340",
          borderRadius: 32,
          padding: "26px 40px 30px",
          textAlign: "center",
          boxShadow: "8px 10px 0 #2A3340",
        }}
      >
        <div
          style={{
            fontFamily: "Nunito, sans-serif",
            fontWeight: 800,
            fontSize: 32,
            color: "#38704D",
          }}
        >
          {card.grade}
        </div>
        <div
          style={{
            marginTop: 6,
            fontFamily: "Nunito, sans-serif",
            fontWeight: 900,
            fontSize: card.huge ? 104 : 58,
            lineHeight: 0.95,
            letterSpacing: card.huge ? 2 : 0,
            color: "#2A3340",
          }}
        >
          {card.title}
        </div>
        <div
          style={{
            marginTop: card.huge ? 8 : 4,
            fontFamily: "Nunito, sans-serif",
            fontWeight: 900,
            fontSize: card.huge ? 92 : 36,
            lineHeight: 1,
            letterSpacing: card.huge ? 3 : 0,
            color: card.huge ? "#2A3340" : "#8A5A10",
          }}
        >
          {card.huge ? card.store : card.line}
        </div>
        <div
          style={{
            marginTop: card.huge ? 14 : 16,
            display: card.huge ? "block" : "inline-block",
            backgroundColor: card.huge ? "transparent" : "#2A3340",
            color: card.huge ? "#8A5A10" : "#F7F1E4",
            borderRadius: card.huge ? 0 : 999,
            padding: card.huge ? 0 : "12px 32px",
            fontFamily: "Nunito, sans-serif",
            fontWeight: 800,
            fontSize: card.huge ? 34 : 36,
          }}
        >
          {card.huge ? card.line : card.store}
        </div>
      </Interactive.Div>
    </AbsoluteFill>
  );
};

const Music = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const marks = timeline(fps);
  const attack = marks.Attack;
  const trophy = marks.Trophies;
  const end = marks.End;

  return (
    <>
      <Audio
        name="Battle music"
        src={staticFile("sfx/battle_music.ogg")}
        volume={interpolate(
          frame,
          [
            0,
            0.25 * fps,
            attack - 0.35 * fps,
            attack + 0.3 * fps,
            trophy,
            trophy + 0.45 * fps,
            end - 0.45 * fps,
            end,
          ],
          [0, 0.5, 0.5, 0.08, 0.08, 0.4, 0.4, 0],
          {extrapolateLeft: "clamp", extrapolateRight: "clamp"},
        )}
      />
      <Audio
        name="Boss music"
        src={staticFile("sfx/boss_music.ogg")}
        from={attack - frames(0.15, fps)}
        durationInFrames={trophy - attack + frames(0.7, fps)}
        volume={interpolate(
          frame,
          [attack - 0.15 * fps, attack + 0.4 * fps, trophy - 0.35 * fps, trophy + 0.25 * fps],
          [0, 0.62, 0.62, 0],
          {extrapolateLeft: "clamp", extrapolateRight: "clamp"},
        )}
      />
      <Audio
        name="Escape whoosh"
        src={staticFile("sfx/victory_whoosh.wav")}
        from={frames(3.0, fps)}
        volume={0.8}
      />
      <Audio name="Win" src={staticFile("sfx/win.wav")} from={frames(3.25, fps)} volume={0.4} />
      <Audio
        name="Boss crash"
        src={staticFile("sfx/crash.wav")}
        from={marks.Finish + frames(1.9, fps)}
        volume={0.5}
      />
      <Audio
        name="Mistakes stamp"
        src={staticFile("sfx/stamp.wav")}
        from={marks.Mistakes}
        volume={0.55}
      />
    </>
  );
};

const GameplayReel = ({cuts, card}: {cuts: Cut[]; card: CardCopy}) => {
  const {fps} = useVideoConfig();
  const marks = timeline(fps, cuts);
  const victoryFrom = marks.Victory;

  return (
    <AbsoluteFill style={{backgroundColor: "#69B7EA"}}>
      {cuts.map((cut) => (
        <Sequence
          key={cut.name}
          name={cut.name}
          from={marks[cut.name]}
          durationInFrames={frames(cut.dur, fps)}
          premountFor={fps}
        >
          <Footage cut={cut} />
        </Sequence>
      ))}
      <Sequence name="Victory" from={victoryFrom} durationInFrames={frames(VICTORY.dur, fps)} premountFor={fps}>
        <VictoryCard card={card} />
      </Sequence>
      <Music />
    </AbsoluteFill>
  );
};

export const RealGameplay = () => {
  return <GameplayReel cuts={CUTS} card={RU_CARD} />;
};

export const RealGameplayEn = () => {
  return <GameplayReel cuts={EN_CUTS} card={EN_CARD} />;
};
