enum CharacterId { bao, poko, po, koko, momo, dodo }

enum CharacterUnlockState { unlocked, comingSoon }

class FamilyCharacter {
  const FamilyCharacter({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.cardColorValue,
    required this.unlockState,
    required this.ageLabel,
    required this.role,
  });

  final CharacterId id;
  final String name;
  final String subtitle;
  final int cardColorValue;
  final CharacterUnlockState unlockState;
  final String ageLabel;
  final String role;

  bool get isUnlocked => unlockState == CharacterUnlockState.unlocked;
}

const familyCharacters = <FamilyCharacter>[
  FamilyCharacter(
    id: CharacterId.bao,
    name: 'Bao',
    subtitle: 'Baby Panda • Let\'s Learn Together!',
    cardColorValue: 0xFF8ECBE8,
    unlockState: CharacterUnlockState.unlocked,
    ageLabel: '0–2',
    role: 'Baby Panda',
  ),
  FamilyCharacter(
    id: CharacterId.poko,
    name: 'Poko',
    subtitle: 'Baby Panda • Let\'s Sing & Draw!',
    cardColorValue: 0xFFF5B8C8,
    unlockState: CharacterUnlockState.unlocked,
    ageLabel: '0–2',
    role: 'Baby Panda',
  ),
  FamilyCharacter(
    id: CharacterId.po,
    name: 'Po',
    subtitle: 'Big Brother • Sports & Energy!',
    cardColorValue: 0xFFF5D76E,
    unlockState: CharacterUnlockState.comingSoon,
    ageLabel: '2–5',
    role: 'Brother',
  ),
  FamilyCharacter(
    id: CharacterId.koko,
    name: 'Koko',
    subtitle: 'Big Sister • Art & Music!',
    cardColorValue: 0xFFC8B8E8,
    unlockState: CharacterUnlockState.comingSoon,
    ageLabel: '2–5',
    role: 'Sister',
  ),
  FamilyCharacter(
    id: CharacterId.momo,
    name: 'Momo',
    subtitle: 'Mama • Warm Hugs & Encouragement',
    cardColorValue: 0xFFF5A88A,
    unlockState: CharacterUnlockState.comingSoon,
    ageLabel: 'Grown-up',
    role: 'Mother',
  ),
  FamilyCharacter(
    id: CharacterId.dodo,
    name: 'Dodo',
    subtitle: 'Papa • Funny & Playful',
    cardColorValue: 0xFFA8E0C8,
    unlockState: CharacterUnlockState.comingSoon,
    ageLabel: 'Grown-up',
    role: 'Father',
  ),
];

FamilyCharacter characterById(CharacterId id) =>
    familyCharacters.firstWhere((c) => c.id == id);
