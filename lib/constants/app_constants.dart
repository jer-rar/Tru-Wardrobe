const String kAppVersion = '1.0.1';
const int kAppVersionCode = 2;

const String kSupabaseUrl = 'https://yxqrbjpvckvzgspgczok.supabase.co';
// New-style publishable key — not a JWT, safe to keep even after legacy
// JWT-based API keys (anon/service_role) are disabled on the project.
const String kSupabasePublishableKey = 'sb_publishable_scIFDiHtAmAX03A5ITfW8A_vPf-mO9J';

const String kWardrobeImagesBucket = 'tw-wardrobe-images';

// Brand palette — distinct from TruBrief's orange, same dark/card structure.
const int kBgColor = 0xFF000000;
const int kCardColor = 0xFF1C1C1E;
const int kAccentColor = 0xFFC17A5B; // warm terracotta
const int kPlaceholderColor = 0xFF2A2A2A;

const List<String> kItemCategories = [
  'top',
  'bottom',
  'dress',
  'outerwear',
  'shoes',
  'accessory',
  'bag',
];

const List<String> kItemPatterns = [
  'solid',
  'striped',
  'plaid',
  'floral',
  'graphic',
  'textured',
  'other',
];

const List<String> kItemSeasons = [
  'spring',
  'summer',
  'fall',
  'winter',
  'all-season',
];

const List<String> kItemFormality = [
  'casual',
  'business-casual',
  'formal',
  'athletic',
];

// Matches the keys colorNameToSwatch() understands, title-cased for display.
const List<String> kColorOptions = [
  'Black',
  'White',
  'Gray',
  'Red',
  'Maroon',
  'Pink',
  'Orange',
  'Brown',
  'Tan',
  'Beige',
  'Yellow',
  'Gold',
  'Green',
  'Olive',
  'Teal',
  'Blue',
  'Navy',
  'Purple',
  'Lavender',
  'Plum',
  'Cream',
  'Ivory',
  'Silver',
  'Denim',
  'Khaki',
  'Other',
];

const String kNoneOption = 'None';

const List<String> kSizeOptions = [
  'XS',
  'S',
  'M',
  'L',
  'XL',
  'XXL',
  'XXXL',
  'One Size',
  'Other',
];
