//checked for plus_string
let countryToCluster = {
  AM = "CIS" // Armenia
  AZ = "CIS" // Azerbaijan
  BY = "CIS" // Belarus
  BG = "CIS" // Bulgaria
  HR = "CIS" // Croatia
  EE = "CIS" // Estonia
  FI = "CIS" // Finland
  GE = "CIS" // Georgia
  HU = "CIS" // Hungary
  KZ = "CIS" // Kazakhstan
  KG = "CIS" // Kyrgyzstan
  LV = "CIS" // Latvia
  LT = "CIS" // Lithuania
  MD = "CIS" // Moldova
  PL = "CIS" // Poland
  RU = "CIS" // Russia
  SK = "CIS" // Slovakia
  SI = "CIS" // Slovenia
  SE = "CIS" // Sweden
  TM = "CIS" // Turkmenistan
  UZ = "CIS" // Uzbekistan
  AF = "CIS" // Afghanistan
  BH = "CIS" // Bahrain
  BD = "CIS" // Bangladesh
  BT = "CIS" // Bhutan
  BN = "CIS" // Brunei
  KH = "CIS" // Cambodia
  CX = "CIS" // Christmas Island
  CC = "CIS" // Cocos Islands
  IO = "CIS" // Diego Garcia
  HK = "CIS" // Hong Kong
  ID = "SA" // Indonesia
  IR = "CIS" // Iran
  IQ = "CIS" // Iraq
  IL = "CIS" // Israel
  JO = "CIS" // Jordan
  KW = "CIS" // Kuwait
  LB = "CIS" // Lebanon
  MV = "CIS" // Maldives
  OM = "CIS" // Oman
  PK = "CIS" // Pakistan
  PS = "CIS" // Palestine
  QA = "CIS" // Qatar
  SA = "CIS" // Saudi Arabia
  SY = "CIS" // Syria
  TJ = "CIS" // Tajikistan
  TR = "CIS" // Turkey
  AE = "CIS" // United Arab Emirates
  YE = "CIS" // Yemen

  AL = "EU" // Albania
  AD = "EU" // Andorra
  AT = "EU" // Austria
  BE = "EU" // Belgium
  BA = "EU" // Bosnia
  CY = "EU" // Cyprus
  CZ = "EU" // Czech Republic
  DK = "EU" // Denmark
  FO = "EU" // Faroe Islands
  FR = "EU" // France
  DE = "EU" // Germany
  GI = "EU" // Gibraltar
  GR = "EU" // Greece
  IS = "EU" // Iceland
  IE = "EU" // Ireland
  IM = "EU" // Isle of Man
  IT = "EU" // Italy
  RS = "CIS" // Serbia
  LI = "EU" // Liechtenstein
  LU = "EU" // Luxembourg
  MK = "EU" // Macedonia
  MT = "EU" // Malta
  MC = "EU" // Monaco
  ME = "EU" // Montenegro
  NL = "EU" // Netherlands
  NO = "EU" // Norway
  PT = "EU" // Portugal
  RO = "EU" // Romania
  SM = "EU" // San Marino
  ES = "EU" // Spain
  CH = "EU" // Switzerland
  UA = "EU" // Ukraine
  GB = "EU" // United Kingdom
  VA = "EU" // Vatican city

  AR = "NA" // Argentina
  BO = "NA" // Bolivia
  BR = "NA" // Brazil
  CL = "NA" // Chile
  CO = "NA" // Colombia
  EC = "NA" // Ecuador
  FK = "NA" // Falkland Islands
  GF = "NA" // French Guiana
  GY = "NA" // Guyana
  PY = "NA" // Paraguay
  PE = "NA" // Peru
  SR = "NA" // Suriname
  UY = "NA" // Uruguay
  VE = "NA" // Venezuela
  AI = "NA" // Anguilla
  AG = "NA" // Antigua and Barbuda
  AW = "NA" // Aruba
  BS = "NA" // Bahamas
  BB = "NA" // Barbados
  BZ = "NA" // Belize
  BM = "NA" // Bermuda
  VG = "NA" // British Virgin Islands
  CA = "NA" // Canada
  KY = "NA" // Cayman Islands
  CR = "NA" // Costa Rica
  CU = "NA" // Cuba
  CW = "NA" // Curacao
  DM = "NA" // Dominica
  DO = "NA" // Dominican Republic
  SV = "NA" // El Salvador
  GL = "NA" // Greenland
  GD = "NA" // Grenada and Carriacuou
  GP = "NA" // Guadeloupe
  GT = "NA" // Guatemala
  HT = "NA" // Haiti
  HN = "NA" // Honduras
  JM = "NA" // Jamaica
  MQ = "NA" // Martinique
  MX = "NA" // Mexico
  MS = "NA" // Montserrat
  KN = "NA" // Saint Kitts and Nevis
  NI = "NA" // Nicaragua
  PA = "NA" // Panama
  PR = "NA" // Puerto Rico
  BQ = "NA" // Saba, Sint Eustatius, Bonaire
  SX = "NA" // Sint Maarten
  LC = "NA" // St. Lucia
  PM = "NA" // St. Pierre and Miquelon
  VC = "NA" // St. Vincent
  TT = "NA" // Trinidad and Tobago
  TC = "NA" // Turks and Caicos Islands
  VI = "NA" // NA Virgin Islands
  US = "NA" // United States
  AS = "NA" // American Samoa
  AU = "SA;NA" // Australia
  NZ = "SA;NA" // New Zealand
  CK = "NA" // Cook Islands
  TL = "NA" // East Timor
  FM = "NA" // Federated States of Micronesia
  FJ = "NA" // Fiji Islands
  PF = "NA" // French Polynesia
  GU = "NA" // Guam
  KI = "NA" // Kiribati
  MP = "NA" // Northern Mariana Islands
  MH = "NA" // Marshall Islands
  UM = "NA" // United States Minor Outlying Islands
  NR = "NA" // Nauru
  NC = "NA" // New Caledonia
  NU = "NA" // Niue
  NF = "NA" // Norfolk Island
  PW = "NA" // Palau
  PG = "NA" // Papua New Guinea
  WS = "NA" // Samoa
  SB = "NA" // Solomon Islands
  TK = "NA" // Tokelau
  TO = "NA" // Tonga
  TV = "NA" // Tuvalu
  VU = "NA" // Vanuatu
  WF = "NA" // Wallis and Futuna Islands

  CN = "SA" // China
  IN = "SA" // India
  JP = "SA" // Japan
  LA = "SA" // Laos
  MO = "SA" // Macau
  MY = "SA" // Malaysia
  MN = "SA" // Mongolia
  MM = "SA" // Myanmar
  NP = "SA" // Nepal
  KP = "SA" // North Korea
  PH = "SA" // Philippines
  SG = "SA" // Singapore
  KR = "SA" // South Korea
  LK = "SA" // Sri Lanka
  TW = "SA" // Taiwan
  TH = "SA" // Thailand
  VN = "SA" // Vietnam
}

let getClustersByCountry = @(code) countryToCluster?[code].split_by_chars(";", true) ?? []

return {
  getClustersByCountry
}
