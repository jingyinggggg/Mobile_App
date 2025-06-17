import 'dart:convert';

import 'package:assignment_tripmate/autocomplete_predictions.dart';

// The Autocomplete response contains place predictions and status
class PlaceAutoCompleteResponse{
  final String? status;
  final List<AutoCompletePredictions>? predictions;

  PlaceAutoCompleteResponse({this.status, this.predictions});

  factory PlaceAutoCompleteResponse.fromJson(Map<String, dynamic> json){
    return PlaceAutoCompleteResponse(
      status: json['status'] as String?,
      predictions: json['predictions'] != null
        ? json['predictions']
          .map<AutoCompletePredictions>(
            (json) => AutoCompletePredictions.fromJson(json))
          .toList()
        :null,
    );
  }

  static PlaceAutoCompleteResponse parseAutoCompleteResult(String responseBody){
    final parsed = json.decode(responseBody).cast<String, dynamic>();
    return PlaceAutoCompleteResponse.fromJson(parsed);
  }
}