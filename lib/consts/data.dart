const List<DefaultAddon> defaultAppAddons = [
  DefaultAddon(
    icon: "https://downloads.madari.media/icon.png",
    title: "Madari Catalog",
    url: "https://catalog.madari.media/manifest.json",
  ),
];

class DefaultAddon {
  final String title;
  final String icon;
  final String url;

  const DefaultAddon({
    required this.title,
    required this.url,
    required this.icon,
  });
}
