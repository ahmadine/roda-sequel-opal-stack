def dev?; !!DEVELOPMENT end
def prod?; !DEVELOPMENT end

%x{
  window.launch = function() {
    var trig = function(e) { #{$window.trigger(*`e`)} };
    if (window.triggers && window.triggers.length)
      for (var i = 0; i < window.triggers.length; i++) { trig(window.triggers[i]); }
    window.triggers = { push: trig };
    window.launch = function() {};
  }
}

$window.on :load_index do
  3.times do |i|
    $document['#foo'] << DOM { |z| z.li { "Opal is working correctly #{i}" } }
  end

  butt1 = $document['butt1']
  butt2 = $document['butt2']
  xdiv = $document['xdiv']

  butt1.on :click do
    xdiv.slide_toggle do
      puts "done"
    end
  end

  butt2.on :click do
    xdiv.fade_toggle do
      puts "done"
    end
  end
end