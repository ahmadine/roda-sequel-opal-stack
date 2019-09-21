class App
  route "example" do |r|
    append_view_subdir '../parts/example/views'

    @examples = ["1", "2", "3", "4"]

    view :example
  end
end