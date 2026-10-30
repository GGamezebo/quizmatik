import {loadFont} from "@remotion/google-fonts/Nunito";
import {loadFont as loadDoodle} from "@remotion/google-fonts/RubikDoodleShadow";

loadFont("normal", {
  weights: ["700", "800", "900"],
  subsets: ["latin", "cyrillic"],
});

loadDoodle("normal", {
  weights: ["400"],
  subsets: ["latin", "cyrillic"],
});
