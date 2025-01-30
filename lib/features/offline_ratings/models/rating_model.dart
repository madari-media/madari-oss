class RatingModel {
  final String tconst;
  final double averageRating;
  final int numVotes;

  RatingModel({
    required this.tconst,
    required this.averageRating,
    required this.numVotes,
  });

  factory RatingModel.fromTsv(List<String> columns) {
    return RatingModel(
      tconst: columns[0],
      averageRating: double.parse(columns[1]),
      numVotes: int.parse(columns[2]),
    );
  }
}
