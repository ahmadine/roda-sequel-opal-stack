require 'part-example'

def add_example ex
  $document['examples'] << DOM(Template['./part-example.erubi'].render(ex).chomp)
end

$window.on :load_example do
  examples = $document['examples']
  examples.on :mouseover, '.part-example' do |e|
    e.on.animate "background-color" => "red"
  end
  examples.on :mouseout, '.part-example' do |e|
    e.on.animate "background-color" => "blue"
  end

  add_example "hello"
  add_example "from"
  add_example "opal"
end