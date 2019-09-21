class OpalBuilder < Opal::Builder
  attr_accessor :build_source_map

  def to_s
    if @build_source_map
      super + "\n" + source_map.to_data_uri_comment
    else
      super
    end
  end
end