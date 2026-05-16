import Foundation

// MARK: - Limiting Joint Track
/// A 12-week quarterly focus protocol for whichever joint scored lowest in the
/// user's most recent movement assessment. User selects one track per quarter.
struct LimitingJointTrack: Identifiable {
    let id: Int
    let name: String
    /// Movement screen test used to confirm progress at week 12.
    let targetTest: String
    /// Recommended weekly practice frequency (2–3 sessions).
    let frequencyPerWeek: Int
    /// The specific drills to perform each session.
    let weeklyProtocol: [MobilityItem]
    /// PNF contract-relax prescription for the primary joint.
    let pnfNote: String
}

// MARK: - Mobility Item
struct MobilityItem: Identifiable {
    let id: Int
    let name: String
    let durationOrReps: String  // e.g. "60s/side" or "10 reps"
    let cue: String             // Short coaching note
}

// MARK: - Mobility Category
struct MobilityCategory: Identifiable {
    let id: Int
    let name: String            // e.g. "Hips"
    let items: [MobilityItem]
}

// MARK: - Activation Item (pre-lift)
struct ActivationItem: Identifiable {
    let id: Int
    let name: String
    let sets: Int
    let reps: Int
}

// MARK: - Mobility Catalog
enum MobilityCatalog {

    // MARK: Daily 10-Minute Routine (do every day, am or pm)
    static let dailyRoutine: [MobilityItem] = [
        MobilityItem(id: 0,  name: "Cat-Cow",
                     durationOrReps: "10 reps",
                     cue: "Breathe in on arch, out on round. Move from the spine, not the hips."),
        MobilityItem(id: 1,  name: "World's Greatest Stretch",
                     durationOrReps: "5/side",
                     cue: "Front foot step, drop hip, rotate thoracic spine toward ceiling."),
        MobilityItem(id: 2,  name: "90/90 Hip Switches",
                     durationOrReps: "8 total",
                     cue: "Both knees at 90°. Rotate slowly; keep torso tall."),
        MobilityItem(id: 3,  name: "Thoracic Rotations (quadruped)",
                     durationOrReps: "8/side",
                     cue: "Hand behind head. Rotate upper back; keep hips still."),
        MobilityItem(id: 4,  name: "Couch Stretch",
                     durationOrReps: "60s/side",
                     cue: "Back foot on wall/couch. Squeeze glute of back leg. Don't arch lower back."),
        MobilityItem(id: 5,  name: "Pigeon Pose",
                     durationOrReps: "60s/side",
                     cue: "Front shin parallel to mat. Relax into it — don't force. Breathe."),
        MobilityItem(id: 6,  name: "Standing Forward Fold",
                     durationOrReps: "60s",
                     cue: "Soft bend in knees. Hang heavy from the hips; don't round the lower back."),
        MobilityItem(id: 7,  name: "Wall Shoulder Slides",
                     durationOrReps: "10 reps",
                     cue: "Arms against wall in 'W'. Slide up to 'Y'. Keep contact the entire time."),
        MobilityItem(id: 8,  name: "Ankle Wall Mobilization",
                     durationOrReps: "8/side",
                     cue: "Toes ~4in from wall. Drive knee over pinky toe — keep heel down."),
        MobilityItem(id: 9,  name: "Deep Squat Hold",
                     durationOrReps: "60s",
                     cue: "Heels flat. Chest up. Elbows inside knees pushing out. Breathe."),
    ]

    // MARK: Pre-Lift Activation (5 min before training)
    static let preActivation: [ActivationItem] = [
        ActivationItem(id: 0, name: "Glute Bridges",       sets: 2, reps: 10),
        ActivationItem(id: 1, name: "Band Pull-Aparts",     sets: 2, reps: 15),
        ActivationItem(id: 2, name: "Bodyweight Squats",    sets: 2, reps: 10),
        ActivationItem(id: 3, name: "Scapular Pulls",       sets: 2, reps: 10),
        ActivationItem(id: 4, name: "Arm Circles",          sets: 1, reps: 10),
    ]

    // MARK: Post-Lift Cooldown
    static let cooldownSteps: [String] = [
        "5 min easy walking to bring heart rate down.",
        "Static stretch each muscle group trained — hold 30 seconds per stretch.",
        "Focus on the largest/most worked muscles of the session.",
    ]

    // MARK: Mobility Library (by body region)
    static let categories: [MobilityCategory] = [
        MobilityCategory(id: 0, name: "Hips", items: [
            MobilityItem(id: 0, name: "90/90 Stretch",
                         durationOrReps: "60s/side",
                         cue: "Tall torso; lean forward over front shin for deeper stretch."),
            MobilityItem(id: 1, name: "Pigeon Pose",
                         durationOrReps: "60–90s/side",
                         cue: "Support on forearms if tight. Breathe into the glute."),
            MobilityItem(id: 2, name: "Couch Stretch",
                         durationOrReps: "60s/side",
                         cue: "Hip flexor + quad. Maintain neutral pelvis. Progress: arms overhead."),
            MobilityItem(id: 3, name: "Cossack Squat",
                         durationOrReps: "6/side",
                         cue: "Shift weight to one side; opposite leg straight. Great hip adductor stretch."),
            MobilityItem(id: 4, name: "Hip Flexor Kneeling Lunge",
                         durationOrReps: "45s/side",
                         cue: "Back knee down, tuck pelvis under, lean forward slightly."),
        ]),
        MobilityCategory(id: 1, name: "Shoulders", items: [
            MobilityItem(id: 0, name: "Wall Angels",
                         durationOrReps: "10 reps",
                         cue: "Full contact — head, upper back, hips on wall. Slow and controlled."),
            MobilityItem(id: 1, name: "Doorway Chest Stretch",
                         durationOrReps: "45s/side",
                         cue: "Elbow at 90°, lean into doorframe. Feel the pec/front delt."),
            MobilityItem(id: 2, name: "Cross-Body Shoulder Stretch",
                         durationOrReps: "30s/side",
                         cue: "Pull elbow across body gently. Targets posterior capsule."),
            MobilityItem(id: 3, name: "Sleeper Stretch",
                         durationOrReps: "30s/side",
                         cue: "Side-lying; push wrist down toward floor. Great for internal rotation."),
        ]),
        MobilityCategory(id: 2, name: "T-Spine", items: [
            MobilityItem(id: 0, name: "Thread the Needle",
                         durationOrReps: "8/side",
                         cue: "On all fours; thread arm under and through. Rotate thoracic spine fully."),
            MobilityItem(id: 1, name: "Thoracic Extension over Foam Roller",
                         durationOrReps: "60s at each segment",
                         cue: "Place roller perpendicular to spine. Work up in 1-vertebra segments."),
            MobilityItem(id: 2, name: "Quadruped T-Spine Rotation",
                         durationOrReps: "8/side",
                         cue: "Hand behind head. Lock lumbar; rotate only the thoracic."),
            MobilityItem(id: 3, name: "Child's Pose with Rotation",
                         durationOrReps: "30s/side",
                         cue: "Thread arm through in child's pose; reach further with each exhale."),
        ]),
        MobilityCategory(id: 3, name: "Ankles", items: [
            MobilityItem(id: 0, name: "Ankle Wall Mobilization",
                         durationOrReps: "10/side",
                         cue: "Drive knee past toes over pinky toe; heel stays down. Add load as improves."),
            MobilityItem(id: 1, name: "Banded Ankle Distraction",
                         durationOrReps: "60s/side",
                         cue: "Band around ankle pulling forward. Work through full dorsiflexion range."),
            MobilityItem(id: 2, name: "Calf Stretch (straight leg)",
                         durationOrReps: "45s/side",
                         cue: "Rear foot flat; lean into wall. Feel the gastroc."),
            MobilityItem(id: 3, name: "Calf Stretch (bent knee)",
                         durationOrReps: "45s/side",
                         cue: "Slight bend in knee targets soleus. Often tighter than gastroc."),
        ]),
        MobilityCategory(id: 4, name: "Hamstrings", items: [
            MobilityItem(id: 0, name: "Standing Forward Fold",
                         durationOrReps: "60s",
                         cue: "Soft knees. Gravity does the work — just breathe and sink."),
            MobilityItem(id: 1, name: "Supine Hamstring Stretch",
                         durationOrReps: "45s/side",
                         cue: "Loop band or towel around foot. Keep opposite hip grounded."),
            MobilityItem(id: 2, name: "Seated Forward Fold",
                         durationOrReps: "60s",
                         cue: "Hinge from hips, not the back. Flex feet. Reach for shins/feet."),
            MobilityItem(id: 3, name: "Nordic Eccentric (slow)",
                         durationOrReps: "5 reps",
                         cue: "Use as mobility if loaded eccentrics are too intense initially."),
        ]),
        MobilityCategory(id: 5, name: "Lower Back", items: [
            MobilityItem(id: 0, name: "Child's Pose",
                         durationOrReps: "60–90s",
                         cue: "Arms extended, hips to heels. Breathe into the lower back. Don't rush."),
            MobilityItem(id: 1, name: "Supine Knee-to-Chest",
                         durationOrReps: "45s/side + bilateral",
                         cue: "Gentle traction on lumbar. Great first-thing-in-morning movement."),
            MobilityItem(id: 2, name: "McKenzie Press-Up",
                         durationOrReps: "10 reps",
                         cue: "Hands under shoulders; press up while hips stay on floor. Extension bias."),
            MobilityItem(id: 3, name: "Dead Bug",
                         durationOrReps: "10/side",
                         cue: "Lower back pressed into floor. Move slowly; never lose lumbar contact."),
        ]),
        MobilityCategory(id: 6, name: "Wrists", items: [
            MobilityItem(id: 0, name: "Wrist Circles",
                         durationOrReps: "10 each direction",
                         cue: "Full range, slow. Loaded with bodyweight for better adaptation."),
            MobilityItem(id: 1, name: "Prayer Stretch",
                         durationOrReps: "30s",
                         cue: "Palms together, elbows at 90°. Slowly lower hands while maintaining palm contact."),
            MobilityItem(id: 2, name: "Reverse Prayer Stretch",
                         durationOrReps: "30s",
                         cue: "Backs of hands together, fingers pointing down. Gentle wrist extension."),
        ]),
        MobilityCategory(id: 7, name: "Neck", items: [
            MobilityItem(id: 0, name: "Chin Tucks",
                         durationOrReps: "10 reps",
                         cue: "Draw chin straight back (not down). Creates space in cervical spine."),
            MobilityItem(id: 1, name: "Neck Side Bend",
                         durationOrReps: "30s/side",
                         cue: "Ear to shoulder; opposite hand light traction on the wrist. No rotation."),
            MobilityItem(id: 2, name: "Upper Trap Stretch",
                         durationOrReps: "30s/side",
                         cue: "Look toward armpit; add light downward hand pressure on the crown."),
        ]),
    ]

    // MARK: Quarterly Limiting-Joint Focus Tracks
    /// Three evidence-informed 12-week protocols. Pick whichever joint tested
    /// worst in the last assessment (sit-to-rise, shoulder flexion, knee-to-wall).
    /// Perform the selected track 2–3× per week as an add-on to the daily routine.
    static let limitingJointTracks: [LimitingJointTrack] = [

        LimitingJointTrack(
            id: 0,
            name: "Hips (12-week focus)",
            targetTest: "Sit-to-rise score ≥9/10 + 90/90 hip switch with full internal rotation",
            frequencyPerWeek: 3,
            weeklyProtocol: [
                MobilityItem(id: 0,
                             name: "90/90 PNF Hip Rotations",
                             durationOrReps: "3 sets: 6s contract / 30s relax",
                             cue: "In the 90/90 position, gently press the knee into the floor (6s), then relax and sink deeper (30s). PNF contract-relax beats passive stretching for ROM gains."),
                MobilityItem(id: 1,
                             name: "Cossack Squat",
                             durationOrReps: "8/side",
                             cue: "Shift weight laterally into a deep side squat while keeping the opposite leg straight. Move slowly; only go as low as your hips allow without pelvic tuck."),
                MobilityItem(id: 2,
                             name: "ATG Split Squat (assisted)",
                             durationOrReps: "8/side",
                             cue: "Hold a post or band for balance. Sink the back knee to the floor, driving the front knee far over toes. This loads the hip flexor through full range."),
                MobilityItem(id: 3,
                             name: "Couch Stretch (loaded)",
                             durationOrReps: "60s/side",
                             cue: "Back foot on wall/bench, front shin vertical. Add a light plate on the front thigh for passive load. Squeeze the glute of the back leg — don't arch lower back."),
                MobilityItem(id: 4,
                             name: "Pigeon Pose (passive)",
                             durationOrReps: "90s/side",
                             cue: "Front shin parallel to mat. Relax completely — breathe into the outer hip. If elevated, prop on a block; avoid forcing."),
            ],
            pnfNote: "On 90/90 position: 3 sets × 6s isometric contract (press knee down) / 30s passive relax. Re-measure sit-to-rise at week 6 and week 12."
        ),

        LimitingJointTrack(
            id: 1,
            name: "T-Spine (12-week focus)",
            targetTest: "Shoulder flexion ≥170° bilateral + thoracic rotation ≥45°/side",
            frequencyPerWeek: 3,
            weeklyProtocol: [
                MobilityItem(id: 0,
                             name: "Thoracic Extension over Foam Roller",
                             durationOrReps: "6 segments × 30s",
                             cue: "Roller perpendicular to spine. Start at T12, work up to T1 in 1-vertebra increments. Arms crossed on chest. Breathe into each level — exhale to relax into extension."),
                MobilityItem(id: 1,
                             name: "Open Book (side-lying)",
                             durationOrReps: "8/side",
                             cue: "Knees stacked at 90°. Reach the top arm back toward the floor, rotating only the thoracic spine. Let the eye follow the hand. Keep hips stacked — no lumbar rotation."),
                MobilityItem(id: 2,
                             name: "Quadruped T-Spine Rotation",
                             durationOrReps: "8/side",
                             cue: "On all fours. Hand behind head. Lock the lumbar by bracing core, then rotate the elbow up toward the ceiling as far as possible. Only the thoracic moves."),
                MobilityItem(id: 3,
                             name: "Bench T-Spine Stretch",
                             durationOrReps: "60s",
                             cue: "Kneel in front of a bench, elbows on the surface shoulder-width. Drop your head between your arms and sink your chest toward the floor. Arms overhead as you relax deeper."),
                MobilityItem(id: 4,
                             name: "Wall Slides",
                             durationOrReps: "10 reps",
                             cue: "Stand with back against the wall, arms in W position with full contact. Slide up to Y, maintaining wrist and elbow contact throughout. If you lose contact, stop and reset."),
            ],
            pnfNote: "On thoracic rotation: place hand behind head, rotate to end-range, isometrically resist (press elbow toward floor) for 6s, then relax and rotate further for 30s. 3 sets/side."
        ),

        LimitingJointTrack(
            id: 2,
            name: "Ankles (12-week focus)",
            targetTest: "Knee-to-wall ≥10 cm (heel-to-wall distance) + full ATG squat hold",
            frequencyPerWeek: 3,
            weeklyProtocol: [
                MobilityItem(id: 0,
                             name: "Banded Ankle Distraction PNF",
                             durationOrReps: "3 sets: 60s/side",
                             cue: "Band looped around ankle pulling forward (anterior direction). Drive knee over pinky toe repeatedly through full dorsiflexion range. The band distracts the talar joint, creating space for greater ROM."),
                MobilityItem(id: 1,
                             name: "Knee-to-Wall Mobilisation",
                             durationOrReps: "8/side",
                             cue: "Toes 4–5 inches from wall. Drive knee over pinky toe, keeping heel flat. Measure distance each session. Progress by moving foot further back as range improves."),
                MobilityItem(id: 2,
                             name: "Eccentric Calf Raise",
                             durationOrReps: "10 reps (3s eccentric)",
                             cue: "On a step edge. Rise on both feet; lower on one, taking 3 seconds. This builds tendon compliance (Achilles), which is often the limiting factor in ankle DF, not joint ROM."),
                MobilityItem(id: 3,
                             name: "ATG Squat Hold",
                             durationOrReps: "60s",
                             cue: "Full depth squat, heels flat. Hold a post or band for assistance as needed. Chest up, knees tracking over toes. Time increases weekly as DF improves."),
            ],
            pnfNote: "With banded distraction: drive knee to end-range dorsiflexion, press against a wall for 6s isometric, relax 30s. 3 sets per side. Measure knee-to-wall cm at baseline, week 6, week 12."
        ),
    ]
}
