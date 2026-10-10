enum ResourceType {
  script('s'),
  image('i'),
  stylesheet('c'),
  xhr('x'),
  subdocument('f'),
  media('m'),
  font('t'),
  other('o');

  const ResourceType(this.code);

  final String code;

  static ResourceType? fromOption(String name) => switch (name) {
    'script' => script,
    'image' => image,
    'stylesheet' || 'css' => stylesheet,
    'xmlhttprequest' || 'xhr' => xhr,
    'subdocument' || 'frame' => subdocument,
    'media' => media,
    'font' => font,
    'ping' || 'websocket' || 'object' || 'other' => other,
    _ => null,
  };
}
