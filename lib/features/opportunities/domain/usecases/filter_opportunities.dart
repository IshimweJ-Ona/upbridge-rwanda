// Owner: Student 4 · Opportunities & applications
// Holds: Keeps open listings, then applies the category chip and the search text.

import 'package:upbridge/shared/models/models.dart';

const opportunityCategories = ['All', 'Internships', 'Jobs', 'Gigs'];

List<Opportunity> filterOpportunities(
  List<Opportunity> all, {
  required String category,
  String search = '',
}) {
  final query = search.trim().toLowerCase();
  return all.where((o) {
    if (o.state != ListingState.open) return false;
    if (category != 'All' && o.category != category) return false;
    if (query.isEmpty) return true;
    // Search matches title, organisation and category
    return o.title.toLowerCase().contains(query) ||
        o.org.toLowerCase().contains(query) ||
        o.category.toLowerCase().contains(query);
  }).toList();
}
