
class Carre {
  int verticalSum;
  int horizontalSum;
  int value; // 0 if white, -1 if black

  Carre(this.verticalSum, this.horizontalSum, this.value);

  Carre.fromJson(Map<String, dynamic> json)
    : verticalSum = json['verticalSum'] as int,
    horizontalSum = json['horizontalSum'] as int,
    value = json['value'] as int;

  Map<String, dynamic> toJson() => {
        'verticalSum': verticalSum,
        'horizontalSum': horizontalSum,
        'value': value,
  };

  @override 
  String toString() {
    return '{$verticalSum,$horizontalSum,$value}';
  }
}