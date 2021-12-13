module Map
  module_function

  SYSTEM_LIMIT_NUMBER_OF_MARKERS = 2_000
  DEFAULT_MAX_NUMBER_OF_MARKERS = 100

  def system_limit_number_of_markers
    @system_limit_number_of_markers ||= SS.config.map.map_system_limit_number_of_markers || SYSTEM_LIMIT_NUMBER_OF_MARKERS
  end

  def default_max_number_of_markers
    @default_max_number_of_markers ||= SS.config.map.map_max_point_form || DEFAULT_MAX_NUMBER_OF_MARKERS
  end

  def max_number_of_markers(site)
    site.try(:map_max_number_of_markers) || Map.default_max_number_of_markers
  end
end
