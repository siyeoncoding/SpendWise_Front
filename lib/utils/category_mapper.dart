// lib/utils/category_mapper.dart

/// 한글 → 영어 카테고리 맵핑
const Map<String, String> categoryToEng = {
  '교통/차량': 'transport',
  '식비': 'food',
  '쇼핑': 'shopping',
  '의료/건강': 'health',
  '주거/통신': 'housing',
  '여가/문화': 'leisure',
  '보험/금융': 'finance',
  '교육/학습': 'education',
  '생활용품': 'living',
  '기타': 'etc',
  '선물/경조사': 'gift',
};

/// 영어 → 한글 카테고리 맵핑
final Map<String, String> engToCategory = {
  for (var e in categoryToEng.entries) e.value: e.key,
};

/// 한글 → 영어 key 변환
Map<String, double> convertToEnglishKeys(Map<String, double> original) {
  return {
    for (var entry in original.entries)
      if (categoryToEng.containsKey(entry.key))
        categoryToEng[entry.key]!: entry.value
      else
        'etc': entry.value, // 누락된 key를 etc로 모음
  };
}

/// 영어 → 한글 key 변환
Map<String, double> convertToKoreanKeys(Map<String, dynamic> original) {
  return {
    for (var entry in original.entries)
      engToCategory[entry.key] ?? entry.key: (entry.value as num).toDouble(),
  };
}

/// 누락된 영어 카테고리는 0.0으로 채움
Map<String, double> fillMissingCategories(Map<String, double> input) {
  const requiredCategories = [
    'food', 'transport', 'shopping', 'health', 'housing', 'leisure',
    'finance', 'education', 'living', 'etc', 'gift'
  ];


  final filled = Map<String, double>.from(input);
  for (var category in requiredCategories) {
    filled.putIfAbsent(category, () => 0.0);
  }
  return filled;
}

