import 'l10n.dart';
import 'models.dart';

/// 2-pose diagram identifiers rendered by [WorkoutPosePainter].
enum PoseKind {
  gluteBridge,
  squat,
  splitSquat,
  clamshell,
  quadrupedHip,
  deadBug,
  birdDog,
  pushUp,
  wallPushUp,
  overheadPress,
  row,
  plank,
  backExtension,
  stepMarch,
  calfRaise,
  catCow,
  hipStretch,
  thoracicTwist,
  childsPose,
}

/// Metadata for a single evidence-grounded exercise in the Lunera Movement Coach.
class ExerciseSpec {
  const ExerciseSpec({
    required this.id,
    required this.nameEn,
    required this.nameId,
    required this.category,
    required this.primaryZone,
    required this.equipment,
    required this.poseKind,
    required this.isTimed,
    required this.baseSets,
    required this.baseRepsOrSec,
    required this.stepsEn,
    required this.stepsId,
    required this.breathCueEn,
    required this.breathCueId,
    required this.easierVariantEn,
    required this.easierVariantId,
    this.sourceRef = 'WHO / NHS / ACE',
  });

  final String id;
  final String nameEn;
  final String nameId;
  final String category; // feminizing | masculinizing | bone_heart | recovery
  final String primaryZone; // lower | upper | core | cardio | mobility
  final String equipment; // bodyweight | dumbbells | bands
  final PoseKind poseKind;
  final bool isTimed;
  final (int gentle, int steady, int active) baseSets;
  final (int gentle, int steady, int active) baseRepsOrSec;
  final List<String> stepsEn;
  final List<String> stepsId;
  final String breathCueEn;
  final String breathCueId;
  final String easierVariantEn;
  final String easierVariantId;
  final String sourceRef;

  String get name => L10n.code == 'id' ? nameId : nameEn;
  List<String> get steps => L10n.code == 'id' ? stepsId : stepsEn;
  String get breathCue => L10n.code == 'id' ? breathCueId : breathCueEn;
  String get easierVariant =>
      L10n.code == 'id' ? easierVariantId : easierVariantEn;

  int setsForLevel(String level) => switch (level) {
        'active' => baseSets.$3,
        'steady' => baseSets.$2,
        _ => baseSets.$1,
      };

  int targetForLevel(String level) => switch (level) {
        'active' => baseRepsOrSec.$3,
        'steady' => baseRepsOrSec.$2,
        _ => baseRepsOrSec.$1,
      };
}

/// Official-reference exercise catalog (WHO Physical Activity Guidelines,
/// NHS Strength & Flexibility Guides, and ACE Exercise Library).
const List<ExerciseSpec> workoutExercises = [
  // ---- Feminizing Focus (Glutes, Lower Body, Core & Posture) ----
  ExerciseSpec(
    id: 'glute_bridge',
    nameEn: 'Glute Bridge',
    nameId: 'Glute Bridge (Angkat Pinggul)',
    category: 'feminizing',
    primaryZone: 'lower',
    equipment: 'bodyweight',
    poseKind: PoseKind.gluteBridge,
    isTimed: false,
    baseSets: (2, 3, 3),
    baseRepsOrSec: (10, 12, 15),
    stepsEn: [
      'Lie on your back with knees bent and feet flat, hip-width apart.',
      'Press through your heels to lift your hips until shoulders, hips, and knees align.',
      'Pause briefly at the top without arching your lower back, then lower with control.',
    ],
    stepsId: [
      'Berbaring telentang dengan lutut ditekuk dan telapak kaki rata selebar pinggul.',
      'Dorong melalui tumit untuk mengangkat pinggul hingga bahu, pinggul, dan lutut sejajar.',
      'Tahan sebentar di atas tanpa melengkungkan punggung bawah, lalu turunkan perlahan.',
    ],
    breathCueEn: 'Exhale as you lift your hips; inhale slowly as you lower.',
    breathCueId: 'Buang napas saat mengangkat pinggul; tarik napas perlahan saat turun.',
    easierVariantEn: 'Lift halfway and pause for 1 second with feet slightly wider.',
    easierVariantId: 'Angkat setengah tinggi saja dan tahan 1 detik dengan kaki sedikit lebih lebar.',
    sourceRef: 'ACE Exercise Library / NHS',
  ),
  ExerciseSpec(
    id: 'split_squat',
    nameEn: 'Supported Split Squat',
    nameId: 'Split Squat Berpegangan',
    category: 'feminizing',
    primaryZone: 'lower',
    equipment: 'bodyweight',
    poseKind: PoseKind.splitSquat,
    isTimed: false,
    baseSets: (2, 3, 3),
    baseRepsOrSec: (6, 8, 12),
    stepsEn: [
      'Stand in a staggered stance with one foot forward and back heel lifted, resting one hand near a wall or chair.',
      'Lower your back knee gently toward the floor while keeping your torso upright.',
      'Push through your front mid-foot to return to standing; switch sides evenly.',
    ],
    stepsId: [
      'Berdiri satu kaki di depan dan tumit belakang terangkat, tangan ringan menyentuh dinding atau kursi.',
      'Turunkan lutut belakang perlahan ke arah lantai sambil menjaga badan tetap tegak.',
      'Dorong melalui telapak kaki depan untuk kembali berdiri; lakukan seimbang kiri dan kanan.',
    ],
    breathCueEn: 'Inhale on the descent; exhale smoothly as you stand up.',
    breathCueId: 'Tarik napas saat turun; buang napas halus saat mendorong naik.',
    easierVariantEn: 'Use a shallow quarter-range dip while holding a sturdy chair.',
    easierVariantId: 'Turun seperempat kedalaman saja sambil berpegangan pada kursi yang kokoh.',
    sourceRef: 'ACE Exercise Library',
  ),
  ExerciseSpec(
    id: 'side_lying_clamshell',
    nameEn: 'Side-Lying Clamshell',
    nameId: 'Clamshell Berbaring Miring',
    category: 'feminizing',
    primaryZone: 'lower',
    equipment: 'bodyweight',
    poseKind: PoseKind.clamshell,
    isTimed: false,
    baseSets: (2, 3, 3),
    baseRepsOrSec: (10, 12, 15),
    stepsEn: [
      'Lie on your side with hips stacked, knees bent ~45 degrees, and feet together.',
      'Keeping your feet touching and pelvis still, lift your top knee like an opening shell.',
      'Lower your knee slowly; complete all reps before switching sides.',
    ],
    stepsId: [
      'Berbaring miring dengan pinggul bertumpuk, lutut ditekuk ~45 derajat, dan kaki rapat.',
      'Jaga kedua kaki tetap menempel dan panggul stabil, buka lutut atas ke arah atas.',
      'Turunkan perlahan; selesaikan repetisi sebelum berganti sisi.',
    ],
    breathCueEn: 'Exhale as your top knee opens; inhale as it closes.',
    breathCueId: 'Buang napas saat membuka lutut atas; tarik napas saat menutup.',
    easierVariantEn: 'Reduce the opening height and rest your head comfortably on your arm.',
    easierVariantId: 'Kurangi tinggi bukaan lutut dan sandarkan kepala dengan nyaman di lengan.',
    sourceRef: 'ACE Exercise Library',
  ),
  ExerciseSpec(
    id: 'fire_hydrant',
    nameEn: 'Quadruped Hip Abduction',
    nameId: 'Angkat Pinggul Samping (Merangkak)',
    category: 'feminizing',
    primaryZone: 'lower',
    equipment: 'bodyweight',
    poseKind: PoseKind.quadrupedHip,
    isTimed: false,
    baseSets: (2, 2, 3),
    baseRepsOrSec: (8, 10, 12),
    stepsEn: [
      'Start on hands and knees with wrists under shoulders and knees under hips.',
      'Keep your knee bent 90 degrees and lift one leg out to the side without twisting your lower back.',
      'Lower with control and switch sides evenly.',
    ],
    stepsId: [
      'Mulai dalam posisi merangkak dengan pergelangan tangan di bawah bahu dan lutut di bawah pinggul.',
      'Jaga lutut tetap menekuk 90 derajat, angkat satu kaki ke samping tanpa memutar punggung.',
      'Turunkan terkontrol dan lakukan seimbang kiri dan kanan.',
    ],
    breathCueEn: 'Exhale gently as you lift; inhale as you return.',
    breathCueId: 'Buang napas lembut saat mengangkat; tarik napas saat kembali.',
    easierVariantEn: 'Perform standing while holding a wall and lifting the leg slightly out.',
    easierVariantId: 'Lakukan sambil berdiri berpegangan dinding dan angkat kaki ke samping sedikit.',
    sourceRef: 'ACE Exercise Library',
  ),
  ExerciseSpec(
    id: 'dead_bug',
    nameEn: 'Dead Bug Core Stability',
    nameId: 'Dead Bug (Stabilitas Inti)',
    category: 'feminizing',
    primaryZone: 'core',
    equipment: 'bodyweight',
    poseKind: PoseKind.deadBug,
    isTimed: false,
    baseSets: (2, 2, 3),
    baseRepsOrSec: (8, 10, 12),
    stepsEn: [
      'Lie on your back, arms reaching up, knees bent at 90 degrees above hips.',
      'Press your lower back softly toward the mat and extend one heel forward while the opposite arm reaches back.',
      'Return to center and alternate sides slowly.',
    ],
    stepsId: [
      'Berbaring telentang, lengan lurus ke atas, lutut ditekuk 90 derajat di atas pinggul.',
      'Tempelkan punggung bawah dengan lembut ke matras, luruskan satu tumit ke depan dan lengan berlawanan ke belakang.',
      'Kembali ke tengah dan bergantian sisi secara perlahan.',
    ],
    breathCueEn: 'Exhale while extending leg and arm; inhale back to start.',
    breathCueId: 'Buang napas saat meluruskan kaki dan tangan; tarik napas saat kembali.',
    easierVariantEn: 'Keep arms steady at your sides and alternate gentle heel taps to the floor.',
    easierVariantId: 'Biarkan lengan di samping badan dan sentuhkan tumit bergantian ringan ke lantai.',
    sourceRef: 'ACE Exercise Library',
  ),
  ExerciseSpec(
    id: 'bird_dog',
    nameEn: 'Bird-Dog Posture Reach',
    nameId: 'Bird-Dog (Keseimbangan Postur)',
    category: 'feminizing',
    primaryZone: 'core',
    equipment: 'bodyweight',
    poseKind: PoseKind.birdDog,
    isTimed: false,
    baseSets: (2, 2, 3),
    baseRepsOrSec: (8, 10, 12),
    stepsEn: [
      'Begin on hands and knees with a neutral, relaxed spine.',
      'Extend one arm forward and the opposite leg straight back at hip height.',
      'Hold for 1–2 seconds, return smoothly, and switch sides.',
    ],
    stepsId: [
      'Mulai pada posisi merangkak dengan tulang belakang netral dan rileks.',
      'Luruskan satu lengan ke depan dan kaki berlawanan ke belakang sejajar pinggul.',
      'Tahan 1–2 detik, kembali perlahan, lalu ganti sisi.',
    ],
    breathCueEn: 'Exhale as you reach out; inhale as you bring knee and hand back.',
    breathCueId: 'Buang napas saat menjulurkan tangan dan kaki; tarik napas saat kembali.',
    easierVariantEn: 'Slide just one foot back along the floor without lifting both limbs together.',
    easierVariantId: 'Geser satu kaki ke belakang menyentuh lantai tanpa mengangkat tangan bersamaan.',
    sourceRef: 'ACE Exercise Library / NHS',
  ),

  // ---- Masculinizing Focus (Upper Body, Shoulders, Back & Strength) ----
  ExerciseSpec(
    id: 'push_up',
    nameEn: 'Incline or Standard Push-Up',
    nameId: 'Push-Up (Incline / Standar)',
    category: 'masculinizing',
    primaryZone: 'upper',
    equipment: 'bodyweight',
    poseKind: PoseKind.pushUp,
    isTimed: false,
    baseSets: (2, 3, 3),
    baseRepsOrSec: (6, 10, 14),
    stepsEn: [
      'Place hands slightly wider than shoulders on a sturdy counter, knees, or floor with core braced.',
      'Lower your chest smoothly with elbows angled ~45 degrees back (not flared wide).',
      'Press evenly through your palms to return to the starting position.',
    ],
    stepsId: [
      'Letakkan tangan sedikit lebih lebar dari bahu di meja kokoh, lutut, atau lantai dengan perut terkunci ringan.',
      'Turunkan dada perlahan dengan siku mengarah ~45 derajat ke belakang.',
      'Dorong merata melalui telapak tangan untuk kembali ke posisi awal.',
    ],
    breathCueEn: 'Inhale as you lower your chest; exhale as you press up.',
    breathCueId: 'Tarik napas saat menurunkan dada; buang napas saat mendorong naik.',
    easierVariantEn: 'Perform standing Wall Push-Ups or elevated counter push-ups.',
    easierVariantId: 'Lakukan Wall Push-Up (dorong dinding) atau bertumpu di meja tinggi.',
    sourceRef: 'NHS Strength Guide / ACE',
  ),
  ExerciseSpec(
    id: 'pike_shoulder_press',
    nameEn: 'Shoulder Press (Bodyweight / Light Load)',
    nameId: 'Dorong Bahu (Bodyweight / Beban Ringan)',
    category: 'masculinizing',
    primaryZone: 'upper',
    equipment: 'dumbbells',
    poseKind: PoseKind.overheadPress,
    isTimed: false,
    baseSets: (2, 3, 3),
    baseRepsOrSec: (8, 10, 12),
    stepsEn: [
      'Stand or sit tall with light dumbbells, water bottles, or resistance band at shoulder height.',
      'Press overhead smoothly until arms are nearly straight without shrugging your neck.',
      'Lower back to shoulder height with steady control.',
    ],
    stepsId: [
      'Berdiri atau duduk tegak dengan dumbbell ringan, botol air, atau resistance band setinggi bahu.',
      'Dorong ke atas perlahan hingga lengan hampir lurus tanpa mengangkat bahu ke telinga.',
      'Turunkan kembali setinggi bahu dengan kendali stabil.',
    ],
    breathCueEn: 'Exhale while pressing overhead; inhale on the way down.',
    breathCueId: 'Buang napas saat mendorong ke atas; tarik napas saat turun.',
    easierVariantEn: 'Use bodyweight-only arms or light water bottles while seated.',
    easierVariantId: 'Gunakan lengan tanpa beban atau botol air ringan sambil duduk.',
    sourceRef: 'ACE Exercise Library',
  ),
  ExerciseSpec(
    id: 'bent_row',
    nameEn: 'Upper-Back Row (Band / Dumbbell)',
    nameId: 'Dayung Punggung Atas (Band / Dumbbell)',
    category: 'masculinizing',
    primaryZone: 'upper',
    equipment: 'bands',
    poseKind: PoseKind.row,
    isTimed: false,
    baseSets: (2, 3, 3),
    baseRepsOrSec: (10, 12, 15),
    stepsEn: [
      'Hinge slightly at the hips with a flat back (or sit holding a band around your feet).',
      'Pull elbows back toward your ribs, gently squeezing your shoulder blades together.',
      'Extend your arms forward slowly without rounding your shoulders.',
    ],
    stepsId: [
      'Condongkan badan sedikit dari pinggul dengan punggung lurus (atau duduk dengan band di telapak kaki).',
      'Tarik siku ke belakang mendekati rusuk sambil merapatkan tulang belikat secara lembut.',
      'Luruskan lengan ke depan perlahan tanpa membungkukkan bahu.',
    ],
    breathCueEn: 'Exhale as you pull back; inhale as you extend forward.',
    breathCueId: 'Buang napas saat menarik ke belakang; tarik napas saat meluruskan.',
    easierVariantEn: 'Perform standing Wall Angels or band-free scapular squeezes.',
    easierVariantId: 'Lakukan tanpa alat dengan merapatkan tulang belikat sambil berdiri.',
    sourceRef: 'ACE Exercise Library / NHS',
  ),
  ExerciseSpec(
    id: 'plank_hold',
    nameEn: 'Forearm Plank Hold',
    nameId: 'Plank Lengan Bawah',
    category: 'masculinizing',
    primaryZone: 'core',
    equipment: 'bodyweight',
    poseKind: PoseKind.plank,
    isTimed: true,
    baseSets: (2, 3, 3),
    baseRepsOrSec: (20, 30, 45),
    stepsEn: [
      'Rest on your forearms with elbows directly beneath shoulders.',
      'Extend legs back (or keep knees resting on the mat) so your body forms a straight line.',
      'Keep your gaze down, brace your core gently, and breathe evenly.',
    ],
    stepsId: [
      'Bertumpu pada lengan bawah dengan siku tepat di bawah bahu.',
      'Luruskan kaki ke belakang (atau tumpu lutut di matras) agar tubuh membentuk garis lurus.',
      'Pandangan ke bawah, kencangkan perut ringan, dan bernapaslah teratur.',
    ],
    breathCueEn: 'Take slow, steady breaths—never hold your breath during a plank.',
    breathCueId: 'Bernapaslah pelan dan teratur—jangan menahan napas selama plank.',
    easierVariantEn: 'Drop knees gently to the floor or place forearms on an elevated sofa/bed edge.',
    easierVariantId: 'Turunkan lutut ke matras atau bertumpu pada tepi sofa/kasur yang lebih tinggi.',
    sourceRef: 'ACE Exercise Library',
  ),
  ExerciseSpec(
    id: 'reverse_snow_angel',
    nameEn: 'Prone Back & Shoulder Sweep',
    nameId: 'Sapuan Punggung & Bahu Tengkurap',
    category: 'masculinizing',
    primaryZone: 'upper',
    equipment: 'bodyweight',
    poseKind: PoseKind.backExtension,
    isTimed: false,
    baseSets: (2, 2, 3),
    baseRepsOrSec: (8, 10, 12),
    stepsEn: [
      'Lie face down with forehead resting softly on a folded towel and toes relaxed on the mat.',
      'Lift hands slightly off the floor and sweep arms in a wide arc from hips toward overhead.',
      'Return slowly to your sides, keeping your neck relaxed.',
    ],
    stepsId: [
      'Berbaring tengkurap dengan dahi bertumpu lembut di handuk lipat dan kaki rileks.',
      'Angkat tangan sedikit dari lantai dan ayunkan melebar dari samping pinggul ke arah atas kepala.',
      'Kembalikan perlahan ke samping tubuh sambil menjaga leher tetap rileks.',
    ],
    breathCueEn: 'Inhale as arms sweep overhead; exhale as they return.',
    breathCueId: 'Tarik napas saat lengan mengayun ke atas; buang napas saat kembali.',
    easierVariantEn: 'Sweep only halfway to shoulder height while keeping toes grounded.',
    easierVariantId: 'Ayunkan lengan cukup hingga sejajar bahu saja.',
    sourceRef: 'ACE Exercise Library',
  ),

  // ---- Bone & Heart Care (WHO Muscle + Bone Strengthening + Low-Impact Cardio) ----
  ExerciseSpec(
    id: 'chair_bodyweight_squat',
    nameEn: 'Bodyweight Squat (or Sit-to-Stand)',
    nameId: 'Squat Tubuh / Duduk-Berdiri',
    category: 'bone_heart',
    primaryZone: 'lower',
    equipment: 'bodyweight',
    poseKind: PoseKind.squat,
    isTimed: false,
    baseSets: (2, 3, 3),
    baseRepsOrSec: (8, 12, 15),
    stepsEn: [
      'Stand with feet shoulder-width apart (optionally with a sturdy chair behind you).',
      'Send your hips back and bend your knees as if sitting down, keeping chest lifted.',
      'Press evenly through both feet to stand tall.',
    ],
    stepsId: [
      'Berdiri dengan kaki selebar bahu (boleh siapkan kursi kokoh di belakangmu).',
      'Dorong pinggul ke belakang dan tekuk lutut seperti hendak duduk, dada tetap tegak.',
      'Dorong merata melalui kedua telapak kaki untuk berdiri tegak.',
    ],
    breathCueEn: 'Inhale on the way down; exhale as you stand up.',
    breathCueId: 'Tarik napas saat turun; buang napas saat berdiri.',
    easierVariantEn: 'Use a chair sit-to-stand: tap the chair lightly and stand right back up.',
    easierVariantId: 'Gunakan kursi (sit-to-stand): sentuh dudukan kursi ringan lalu berdiri kembali.',
    sourceRef: 'NHS Strength & Flex / WHO',
  ),
  ExerciseSpec(
    id: 'brisk_step_march',
    nameEn: 'Low-Impact Brisk Step March',
    nameId: 'Jalan di Tempat Ritmis (Low-Impact)',
    category: 'bone_heart',
    primaryZone: 'cardio',
    equipment: 'bodyweight',
    poseKind: PoseKind.stepMarch,
    isTimed: true,
    baseSets: (2, 3, 3),
    baseRepsOrSec: (30, 45, 60),
    stepsEn: [
      'Stand tall and march briskly in place, lifting knees to a comfortable height.',
      'Swing opposite arms naturally to keep a steady, heart-healthy rhythm.',
      'Land softly on the balls of your feet to keep joints comfortable.',
    ],
    stepsId: [
      'Berdiri tegak dan jalan di tempat dengan ritme sigap, angkat lutut senyamannya.',
      'Ayunkan lengan berlawanan secara alami untuk menjaga ritme jantung yang sehat.',
      'Mendaratlah dengan lembut agar sendi tetap nyaman.',
    ],
    breathCueEn: 'Keep a steady conversational pace—you should still be able to speak.',
    breathCueId: 'Jaga ritme napas stabil—usahakan tetap bisa berbicara dengan nyaman.',
    easierVariantEn: 'March at a slower walking cadence with lower knee lifts.',
    easierVariantId: 'Jalan di tempat dengan tempo lebih santai dan angkatan lutut rendah.',
    sourceRef: 'WHO Physical Activity Guidelines / NHS',
  ),
  ExerciseSpec(
    id: 'standing_calf_raise',
    nameEn: 'Standing Calf Raise',
    nameId: 'Jinjit Penguat Betis & Tulang Kaki',
    category: 'bone_heart',
    primaryZone: 'lower',
    equipment: 'bodyweight',
    poseKind: PoseKind.calfRaise,
    isTimed: false,
    baseSets: (2, 3, 3),
    baseRepsOrSec: (10, 12, 15),
    stepsEn: [
      'Stand near a wall or chair for light balance, feet hip-width apart.',
      'Rise smoothly onto the balls of your feet, pausing 1 second at the top.',
      'Lower your heels slowly all the way back down.',
    ],
    stepsId: [
      'Berdiri dekat dinding atau kursi untuk keseimbangan, kaki selebar pinggul.',
      'Angkat tumit perlahan hingga berjinjit, tahan 1 detik di atas.',
      'Turunkan tumit kembali ke lantai secara perlahan.',
    ],
    breathCueEn: 'Exhale as you rise onto your toes; inhale as heels lower.',
    breathCueId: 'Buang napas saat berjinjit; tarik napas saat tumit turun.',
    easierVariantEn: 'Hold the wall with both hands and lift halfway.',
    easierVariantId: 'Pegang dinding dengan kedua tangan dan angkat tumit setengah tinggi.',
    sourceRef: 'NHS Strength & Balance',
  ),
  ExerciseSpec(
    id: 'wall_push_up',
    nameEn: 'Wall Push-Up',
    nameId: 'Push-Up Dinding',
    category: 'bone_heart',
    primaryZone: 'upper',
    equipment: 'bodyweight',
    poseKind: PoseKind.wallPushUp,
    isTimed: false,
    baseSets: (2, 2, 3),
    baseRepsOrSec: (8, 12, 15),
    stepsEn: [
      'Stand facing a wall roughly an arm’s length away, palms flat at chest height.',
      'Bend your elbows to bring your chest toward the wall while keeping heels down.',
      'Press through your palms back to the starting position.',
    ],
    stepsId: [
      'Berdiri menghadap dinding berjarak sekitar satu lengan, telapak tangan rata setinggi dada.',
      'Tekuk siku mendekatkan dada ke dinding sambil menjaga tumit tetap menapak.',
      'Dorong kembali ke posisi awal secara perlahan.',
    ],
    breathCueEn: 'Inhale toward the wall; exhale as you press away.',
    breathCueId: 'Tarik napas saat mendekat ke dinding; buang napas saat mendorong menjauh.',
    easierVariantEn: 'Step a little closer to the wall for lighter resistance.',
    easierVariantId: 'Berdiri sedikit lebih dekat ke dinding agar bebannya lebih ringan.',
    sourceRef: 'NHS Strength & Flex',
  ),

  // ---- Low-Energy / Trough Recovery (Gentle Mobility & Stretching) ----
  ExerciseSpec(
    id: 'cat_cow',
    nameEn: 'Cat-Cow Spinal Flow',
    nameId: 'Peregangan Punggung Cat-Cow',
    category: 'recovery',
    primaryZone: 'mobility',
    equipment: 'bodyweight',
    poseKind: PoseKind.catCow,
    isTimed: true,
    baseSets: (2, 2, 3),
    baseRepsOrSec: (30, 40, 45),
    stepsEn: [
      'Start on hands and knees with wrists under shoulders and knees under hips.',
      'Inhale as you soften your belly toward the mat and lift your gaze gently.',
      'Exhale as you round your spine upward and tuck your chin lightly.',
    ],
    stepsId: [
      'Mulai dalam posisi merangkak dengan pergelangan tangan di bawah bahu dan lutut di bawah pinggul.',
      'Tarik napas sambil menurunkan perut perlahan dan mengangkat pandangan lembut.',
      'Buang napas sambil melengkungkan punggung ke atas dan menundukkan dagu ringan.',
    ],
    breathCueEn: 'Match each slow movement to one full inhale or exhale.',
    breathCueId: 'Selaraskan setiap gerakan lambat dengan satu tarikan atau hembusan napas penuh.',
    easierVariantEn: 'Can be done seated on a chair with hands resting on your knees.',
    easierVariantId: 'Bisa dilakukan sambil duduk di kursi dengan tangan bertumpu di lutut.',
    sourceRef: 'ACE Exercise Library / NHS',
  ),
  ExerciseSpec(
    id: 'kneeling_hip_stretch',
    nameEn: 'Gentle Hip Flexor & Glute Stretch',
    nameId: 'Peregangan Pinggul & Paha Lembut',
    category: 'recovery',
    primaryZone: 'mobility',
    equipment: 'bodyweight',
    poseKind: PoseKind.hipStretch,
    isTimed: true,
    baseSets: (2, 2, 2),
    baseRepsOrSec: (25, 30, 40),
    stepsEn: [
      'Step one foot forward into a comfortable kneeling or standing lunge (use a cushion under the back knee).',
      'Gently shift your weight slightly forward until you feel a mild stretch in the front hip.',
      'Hold comfortably without bouncing, then switch sides.',
    ],
    stepsId: [
      'Langkahkan satu kaki ke depan dalam posisi lunge berlutut atau berdiri (gunakan bantal tipis di bawah lutut).',
      'Geser berat badan sedikit ke depan hingga terasa regangan ringan di pangkal pinggul.',
      'Tahan dengan nyaman tanpa memantul, lalu ganti sisi.',
    ],
    breathCueEn: 'Relax your shoulders and breathe out slowly into the stretch.',
    breathCueId: 'Rilekskan bahu dan hembuskan napas perlahan selama peregangan.',
    easierVariantEn: 'Keep both feet standing in a shallow step and hold a chair.',
    easierVariantId: 'Lakukan sambil berdiri dengan langkah pendek berpegangan kursi.',
    sourceRef: 'ACE Exercise Library / NHS',
  ),
  ExerciseSpec(
    id: 'open_book_twist',
    nameEn: 'Thoracic Open-Book Stretch',
    nameId: 'Peregangan Dada & Punggung Open-Book',
    category: 'recovery',
    primaryZone: 'mobility',
    equipment: 'bodyweight',
    poseKind: PoseKind.thoracicTwist,
    isTimed: true,
    baseSets: (2, 2, 2),
    baseRepsOrSec: (25, 30, 40),
    stepsEn: [
      'Lie on your side with knees bent in front of you and both arms extended together.',
      'Slowly open your top arm across your body toward the opposite side, following with your eyes.',
      'Hold gently for a breath, close back, and switch sides.',
    ],
    stepsId: [
      'Berbaring miring dengan lutut ditekuk ke depan dan kedua lengan lurus rapat ke depan.',
      'Buka lengan atas perlahan menyilang ke sisi berlawanan mengikuti pandangan mata.',
      'Tahan lembut satu napas penuh, tutup kembali, lalu ganti sisi.',
    ],
    breathCueEn: 'Exhale as your chest opens; inhale as your arm returns.',
    breathCueId: 'Buang napas saat dada terbuka; tarik napas saat lengan kembali.',
    easierVariantEn: 'Rest your opened hand on a pillow instead of reaching all the way to the floor.',
    easierVariantId: 'Letakkan tangan yang terbuka di atas bantal tanpa memaksa menyentuh lantai.',
    sourceRef: 'ACE Exercise Library',
  ),
  ExerciseSpec(
    id: 'childs_pose_breath',
    nameEn: "Restorative Child's Pose & Breath",
    nameId: 'Pose Anak Restoratif & Napas Dalam',
    category: 'recovery',
    primaryZone: 'mobility',
    equipment: 'bodyweight',
    poseKind: PoseKind.childsPose,
    isTimed: true,
    baseSets: (1, 2, 2),
    baseRepsOrSec: (30, 45, 60),
    stepsEn: [
      'Kneel comfortably with big toes touching and knees slightly wide.',
      'Sit hips back toward your heels and fold your torso forward, resting arms ahead.',
      'Let your forehead rest on the mat or a pillow and soften your jaw.',
    ],
    stepsId: [
      'Berlutut dengan nyaman, ujung ibu jari kaki bertemu dan lutut sedikit terbuka.',
      'Dorong pinggul ke arah tumit dan rebahkan badan ke depan dengan lengan terjulur rileks.',
      'Sandarkan dahi di matras atau bantal dan lemaskan bahu serta rahang.',
    ],
    breathCueEn: 'Inhale for 4 seconds into your ribs; exhale slowly for 6 seconds.',
    breathCueId: 'Tarik napas 4 detik ke arah rusuk; buang napas perlahan selama 6 detik.',
    easierVariantEn: 'Place a pillow between your calves and thighs, or rest your forehead on stacked fists.',
    easierVariantId: 'Taruh bantal di antara paha dan betis, atau sandarkan dahi di atas kepalan tangan.',
    sourceRef: 'NHS Flexibility & Relaxation',
  ),
];

ExerciseSpec? exerciseById(String id) {
  for (final e in workoutExercises) {
    if (e.id == id) return e;
  }
  return null;
}

String categoryLabel(String category) => switch (category) {
      'feminizing' => tr('Feminizing Focus'),
      'masculinizing' => tr('Masculinizing Focus'),
      'bone_heart' => tr('Bone & Heart Care'),
      'recovery' => tr('Low-Energy Recovery'),
      _ => tr('Custom Routine'),
    };

String categorySubtitle(String category) => switch (category) {
      'feminizing' => tr('Glutes, lower body, core & posture'),
      'masculinizing' => tr('Upper body, shoulders, back & strength'),
      'bone_heart' => tr('Low-impact cardio & bone-supporting resistance'),
      'recovery' => tr('Gentle mobility & calm breathing for rest or trough days'),
      _ => tr('Your personalized routine'),
    };

String paceLabel(String level) => switch (level) {
      'active' => tr('Active'),
      'steady' => tr('Steady'),
      _ => tr('Gentle'),
    };

WorkoutExerciseItem _itemFromSpec(ExerciseSpec spec, String level,
    {int restSeconds = 45}) {
  final target = spec.targetForLevel(level);
  return WorkoutExerciseItem(
    exerciseId: spec.id,
    sets: spec.setsForLevel(level),
    reps: spec.isTimed ? null : target,
    seconds: spec.isTimed ? target : null,
    restSeconds: restSeconds,
  );
}

/// Builds the 4 curated HRT-aware preset routines calibrated to [level].
List<WorkoutRoutine> buildPresetRoutines(
  String level, {
  List<String> equipment = const ['bodyweight'],
}) {
  final now = DateTime(2026, 1, 1);
  final hasUpperGear =
      equipment.contains('dumbbells') || equipment.contains('bands');

  List<WorkoutExerciseItem> itemsFor(List<String> ids, {int rest = 45}) => [
        for (final id in ids)
          if (exerciseById(id) case final spec?)
            _itemFromSpec(
              spec,
              level,
              restSeconds: rest,
            ).copyWith(
              useEasierVariant:
                  !hasUpperGear && spec.equipment != 'bodyweight',
            ),
      ];

  final estMin = switch (level) {
    'active' => 22,
    'steady' => 17,
    _ => 13,
  };

  return [
    WorkoutRoutine(
      id: 'preset_feminizing',
      title: tr('Feminizing Focus: Lower Body & Posture'),
      category: 'feminizing',
      isCustom: false,
      estimatedMinutes: estMin,
      updatedAt: now,
      items: itemsFor([
        'glute_bridge',
        'side_lying_clamshell',
        'split_squat',
        'dead_bug',
        'bird_dog',
      ]),
    ),
    WorkoutRoutine(
      id: 'preset_masculinizing',
      title: tr('Masculinizing Focus: Upper Body & Core'),
      category: 'masculinizing',
      isCustom: false,
      estimatedMinutes: estMin,
      updatedAt: now,
      items: itemsFor([
        'push_up',
        'bent_row',
        'pike_shoulder_press',
        'reverse_snow_angel',
        'plank_hold',
      ]),
    ),
    WorkoutRoutine(
      id: 'preset_bone_heart',
      title: tr('Bone & Heart Care: Steady Strength'),
      category: 'bone_heart',
      isCustom: false,
      estimatedMinutes: estMin - 2,
      updatedAt: now,
      items: itemsFor([
        'brisk_step_march',
        'chair_bodyweight_squat',
        'wall_push_up',
        'standing_calf_raise',
      ]),
    ),
    WorkoutRoutine(
      id: 'preset_recovery',
      title: tr('Low-Energy / Trough Recovery Flow'),
      category: 'recovery',
      isCustom: false,
      estimatedMinutes: 10,
      updatedAt: now,
      items: itemsFor([
        'cat_cow',
        'kneeling_hip_stretch',
        'open_book_twist',
        'childs_pose_breath',
      ], rest: 25),
    ),
  ];
}

/// Builds a short, welcoming 10-minute session used for Gentle Restart after >=5 days away.
WorkoutRoutine buildEaseBackInRoutine(String focus) {
  final now = DateTime(2026, 1, 1);
  final ids = switch (focus) {
    'masculinizing' => ['wall_push_up', 'cat_cow', 'plank_hold', 'childs_pose_breath'],
    'feminizing' => ['glute_bridge', 'bird_dog', 'kneeling_hip_stretch', 'childs_pose_breath'],
    _ => ['brisk_step_march', 'chair_bodyweight_squat', 'cat_cow', 'childs_pose_breath'],
  };
  return WorkoutRoutine(
    id: 'preset_ease_back_in',
    title: tr('Ease Back In — 10 Min Gentle Start'),
    category: 'recovery',
    isCustom: false,
    estimatedMinutes: 10,
    updatedAt: now,
    items: [
      for (final id in ids)
        if (exerciseById(id) case final spec?)
          _itemFromSpec(spec, 'gentle', restSeconds: 30).copyWith(sets: 2),
    ],
  );
}
