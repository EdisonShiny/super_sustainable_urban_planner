import 'index_score.dart';

/// Per-category guidance (Problem + Solution).
class CategoryAdvice {
  const CategoryAdvice({
    required this.problem,
    required this.solution,
  });

  final String problem;
  final String solution;
}

/// A factor group (e.g., "Vegetation / Green Coverage", "Air Quality") with
/// four category bands and a short data support note.
/// NOTE: Keep const constructor (assert removed so const map works).
class FactorGroup {
  const FactorGroup({
    required this.title,
    required this.categories, // expected length = 4 (0–24, 25–49, 50–74, 75–100)
    required this.dataSupport,
  });

  final String title;
  final List<CategoryAdvice> categories;
  final String dataSupport;
}

/// Captures how an index is themed and computed. Flexible factors list allows
/// 2 groups (e.g., GCI/CRI) or 3 groups (HI) without changing UI code.
class IndexDefinition {
  const IndexDefinition({
    required this.type,
    required this.introText,
    required this.formulaText,
    required this.factors,
  });

  final indexType type;
  final String introText;
  final String formulaText;
  final List<FactorGroup> factors;
}

/// Convenience helper to access a definition.
IndexDefinition? findIndexDefinition(indexType type) => kIndexDefinitions[type];

/// Canonical registry describing every index hierarchy and weighting rule.
const Map<indexType, IndexDefinition> kIndexDefinitions = {
  // --------------------------
  // GCI
  // --------------------------
  indexType.gci: IndexDefinition(
    type: indexType.gci,
    introText:
        'The Green Coverage Index evaluates how well a city balances land environment and human settlement density. It is composed of:\n'
        '- Vegetation / Green Coverage (NDVI from MODIS/Terra satellites)\n'
        '- Population / Housing Density (SEDAC GPWv4 data)',
    formulaText: 'GCI = (0.5 · Vegetation) + (0.5 · Housing Cover)',
    factors: [
      FactorGroup(
        title: 'Vegetation / Green Coverage',
        categories: [
          CategoryAdvice(
            problem:
                '- Very low or barren vegetation cover. This results in weak ecological resilience, severe heat islands, and reduced carbon absorption.',
            solution:
                '- Launch large-scale tree planting, restore degraded lands, and mandate minimum green area ratios in new developments.',
          ),
          CategoryAdvice(
            problem:
                '- Sparse vegetation cover, fragmented parks, and limited shade in urban cores.',
            solution:
                '- Expand community parks, incentivize rooftop and vertical gardens, and strengthen zoning rules to integrate green corridors.',
          ),
          CategoryAdvice(
            problem:
                '- Moderate vegetation coverage, adequate in parts of the city but unevenly distributed, leaving some communities underserved.',
            solution:
                '- Prioritize equitable green space access, link fragmented parks, and implement city-wide greening programs near transport hubs and dense housing.',
          ),
          CategoryAdvice(
            problem:
                '- High, dense, and healthy vegetation coverage but requires ongoing management and monitoring.',
            solution:
                '- Maintain tree health, monitor satellite NDVI for long-term trends, and preserve green infrastructure during expansion.',
          ),
        ],
        dataSupport:
            '- Resource: MOD13Q1 — MODIS/Terra Vegetation Indices 16-Day L3 Global 250 m SIN Grid.\n'
            '- Satellite: Terra (MODIS instrument).',
      ),
      FactorGroup(
        title: 'Population / Housing Density',
        categories: [
          CategoryAdvice(
            problem:
                '- Very low density (sprawl). Inefficient land use, high infrastructure cost per capita, weak public transport viability.',
            solution:
                '- Promote compact, mixed-use neighborhoods with clustered housing and improved transport connectivity.',
          ),
          CategoryAdvice(
            problem:
                '- Low to moderate density. Some urban efficiency achieved, but risks of fragmented growth remain.',
            solution:
                '- Guide growth into transit-oriented districts, maintain open space while preventing leapfrog sprawl.',
          ),
          CategoryAdvice(
            problem:
                '- Balanced density (100–1,000/km²). Optimal land and infrastructure efficiency, but risk of overcrowding if unmanaged.',
            solution:
                '- Preserve balanced density by enforcing housing codes, monitoring density growth, and aligning with green coverage targets.',
          ),
          CategoryAdvice(
            problem:
                '- Very high density (>10,000/km²). Overcrowding, congestion, and loss of livability despite efficient land use.',
            solution:
                '- Decentralize growth, expand affordable housing in nearby regions, and invest in public transport plus vertical greening.',
          ),
        ],
        dataSupport:
            '- Resource: Gridded Population of the World, Version 4 (GPWv4): Population Density, Revision 11 — CIESIN, Columbia University.\n'
            '- Note: Not directly satellite-derived; modeled from national census data at ~1 km (30 arc-second) resolution.',
      ),
    ],
  ),

  // --------------------------
  // CRI
  // --------------------------
  indexType.cri: IndexDefinition(
    type: indexType.cri,
    introText:
        'The Climate Resilience Index (CRI) measures how well a city can withstand and adapt to climate-related shocks and natural hazards. It focuses on two major stress factors:\n- drought risk (too dry or too wet compared to normal)\n- flood occurrence probability\nBy combining these two dimensions, CRI provides a snapshot of how resilient urban systems are to extreme weather and water-related risks.',
    formulaText:
        'CRI = (0.5·Drought Index) + (0.5·Flood Occurrence Probability)',
    factors: [
      FactorGroup(
        title: 'Drought / Dryness Index',
        categories: [
          CategoryAdvice(
            problem:
                '- Extreme drought or extreme wetness conditions (very far from normal). Severe water stress or flooding risks threaten food supply, water systems, and infrastructure.',
            solution:
                '- Deploy water rationing, rainwater harvesting, and groundwater recharge. Invest in irrigation efficiency and drought-resistant crops.',
          ),
          CategoryAdvice(
            problem:
                '- Moderate drought or wetness stress. Water supply becoming unreliable; rising risk of seasonal shortages.',
            solution:
                '- Improve watershed management, enforce water-saving policies, and enhance soil moisture retention with sustainable farming and landscaping practices.',
          ),
          CategoryAdvice(
            problem:
                '- Mild deviations from normal. System is stable but vulnerable to climate extremes.',
            solution:
                '- Strengthen early-warning drought monitoring, improve reservoir management, and diversify city water sources.',
          ),
          // NOTE: Fixed text (previously vegetation-like message)
          CategoryAdvice(
            problem:
                '- Near-normal moisture conditions. Current conditions are favorable but resilience can degrade without preparation.',
            solution:
                '- Maintain diversified water sources, protect wetlands/aquifers, and keep early-warning systems active.',
          ),
        ],
        dataSupport:
            '- Resource: FLDAS Soil Moisture Anomaly (Surface or Root Zone)',
      ),
      FactorGroup(
        title: 'Flood Occurrence Probability',
        categories: [
          CategoryAdvice(
            problem:
                '- Located in the highest hazard flood zones (deciles 9–10). High probability of frequent or severe floods.',
            solution:
                '- Implement strict no-build zones in flood plains, construct levees and flood defenses, and relocate vulnerable populations.',
          ),
          CategoryAdvice(
            problem:
                '- Moderate to high flood hazard (deciles 7–8). Infrastructure and housing at increasing flood risk.',
            solution:
                '- Upgrade drainage, introduce permeable pavements, and enhance emergency response systems.',
          ),
          CategoryAdvice(
            problem:
                '- Moderate hazard (deciles 4–6). Flood risk present but manageable.',
            solution:
                '- Incorporate green infrastructure such as wetlands and rain gardens to reduce surface runoff.',
          ),
          CategoryAdvice(
            problem: '- Low hazard (deciles 1–3). Flood risk is minimal.',
            solution:
                '- Continue flood monitoring and enforce zoning to maintain safe land use patterns.',
          ),
        ],
        dataSupport: '- Resource: Global Flood Hazard Frequency and Distribution',
      ),
    ],
  ),

  // --------------------------
  // HI
  // --------------------------
  indexType.hi: IndexDefinition(
    type: indexType.hi,
    introText:
        'The Health Index (HI) evaluates how healthy and livable a city is, based on both environmental conditions and resident perspectives. It integrates three fields:\n- air quality (PM2.5)\n - land surface temperature (LST)\n- resident feedback on satisfaction.\nBy combining physical environmental data with community input, HI gives a balanced picture of urban well-being.',
    formulaText:
        'HI = (0.4·Air Quality) + (0.4·Land Surface Temperature) + (0.2·Resident Feedback)',
    factors: [
      FactorGroup(
        title: 'Air Quality (PM2.5 concentration)',
        categories: [
          CategoryAdvice(
            problem:
                '- Very unhealthy to hazardous PM2.5 (>55 µg/m³). Serious public health risk.',
            solution:
                '- Enforce emission controls, restrict industrial pollution, promote clean energy, and alert vulnerable populations.',
          ),
          CategoryAdvice(
            problem:
                '- Unhealthy for sensitive groups (35–55 µg/m³). Children and elderly at risk.',
            solution:
                '- Expand green belts, regulate traffic flows, and provide real-time pollution alerts.',
          ),
          CategoryAdvice(
            problem:
                '- Moderate PM2.5 levels (12–35 µg/m³). Air is acceptable, but prolonged exposure carries risks.',
            solution:
                '- Encourage public transport, incentivize EVs, and monitor pollution hotspots.',
          ),
          CategoryAdvice(
            problem: '- Good air quality (0–12 µg/m³). Clean and safe for all residents.',
            solution:
                '- Maintain clean air policies, continue urban greening, and monitor seasonal pollution risks.',
          ),
        ],
        dataSupport:
            '- Resource: PM2.5 Concentration (Open-Meteo Air Quality API)',
      ),
      FactorGroup(
        title: 'Land Surface Temperature',
        categories: [
          CategoryAdvice(
            problem:
                '- Extreme heat (>40°C) or extreme cold (<5°C). Unsafe for residents and damaging for infrastructure.',
            solution:
                '- Introduce heatwave action plans, cool roofing, shaded walkways, and emergency shelters.',
          ),
          CategoryAdvice(
            problem:
                '- High heat stress (35–40°C) or cold stress (5–10°C). Energy demand spikes for cooling/heating.',
            solution:
                '- Enhance ventilation in urban design, deploy cooling centers, and invest in resilient energy infrastructure.',
          ),
          CategoryAdvice(
            problem:
                '- Moderate warmth/coolness (10–15°C or 30–35°C). Livable but causes some seasonal strain.',
            solution:
                '- Promote reflective building materials, expand urban tree canopy, and integrate heat-resilient urban design.',
          ),
          CategoryAdvice(
            problem:
                '- Comfortable range (15–30°C). Optimal for human health and urban livability.',
            solution:
                '- Maintain green urban planning policies and continue monitoring with satellite data.',
          ),
        ],
        dataSupport:
            '- Resource: Land Surface Temperature (LST_1KM) – VNP21A1D',
      ),
      FactorGroup(
        title: 'Resident Feedback and City Leader Engagement',
        categories: [
          CategoryAdvice(
            problem:
                '- Residents rate city conditions very poorly (1 star). Dissatisfaction with health, environment, and services.',
            solution:
                '- Hold community consultations, address top concerns immediately, and integrate public feedback into planning.',
          ),
          CategoryAdvice(
            problem:
                '- Residents moderately dissatisfied (2 stars). Trust in local governance is weak.',
            solution:
                '- Improve communication, target quick wins (clean water, waste management), and report back progress transparently.',
          ),
          CategoryAdvice(
            problem:
                '- Residents are fairly satisfied (3–4 stars). The city is livable but still faces issues.',
            solution:
                '- Involve residents in co-design of parks, transit, and health initiatives to boost satisfaction.',
          ),
          CategoryAdvice(
            problem:
                '- Residents are highly satisfied (5 stars). The community feels safe, healthy, and engaged.',
            solution:
                '- Maintain strong governance, keep community engagement channels open, and showcase best practices globally.',
          ),
        ],
        dataSupport:
            '- Collected directly via resident ratings (1–5 stars for 20% increments).',
      ),
    ],
  ),
};
