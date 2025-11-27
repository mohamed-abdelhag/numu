import 'package:flutter/material.dart';
import '../models/city.dart';

/// Screen for selecting a city for manual prayer time calculation.
/// Displays cities grouped by region with search functionality.
class CitySelectionScreen extends StatefulWidget {
  final String? selectedCityId;

  const CitySelectionScreen({
    super.key,
    this.selectedCityId,
  });

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedRegion;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredCities = _searchQuery.isEmpty
        ? MajorCities.all
        : MajorCities.search(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select City'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cities...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // City list
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults(filteredCities, theme)
                : _buildRegionGroups(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<City> cities, ThemeData theme) {
    if (cities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No cities found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        return _buildCityTile(city, theme);
      },
    );
  }

  Widget _buildRegionGroups(ThemeData theme) {
    final regions = MajorCities.byRegion;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: regions.length,
      itemBuilder: (context, index) {
        final region = regions.keys.elementAt(index);
        final cities = regions[region]!;
        final isExpanded = _expandedRegion == region;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  region,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('${cities.length} cities'),
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () {
                  setState(() {
                    _expandedRegion = isExpanded ? null : region;
                  });
                },
              ),
              if (isExpanded)
                ...cities.map((city) => _buildCityTile(city, theme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCityTile(City city, ThemeData theme) {
    final isSelected = city.id == widget.selectedCityId;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        child: Text(
          city.countryCode,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(city.name),
      subtitle: Text(city.country),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: () {
        Navigator.of(context).pop(city);
      },
    );
  }
}
