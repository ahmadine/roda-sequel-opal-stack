class MiniIrb
  def start
    DOM {
      div.miniirb! {
        div.mi_container {
          div.mi_content "miniirb @ #{RUBY_ENGINE}-#{RUBY_ENGINE_VERSION} (ruby-#{RUBY_VERSION})"
          form.mi_form {
            input.mi_input type: text
          }
        }
      }
    }.append_to($document.body)

    @miniirb = $document['#miniirb']
    @container = @miniirb.at_css '.mi_container'
    @content = @miniirb.at_css '.mi_content'
    @form = @miniirb.at_css '.mi_form'
    @input = @miniirb.at_css '.mi_input'

    @history = []
    @history_ptr = 0

    @tmpcode = ''

    @form.on :submit, &method(:execute)
    @miniirb.on(:click) { @input.focus }
    @input.on :keydown, &method(:history)
    @input.focus
  end

  def history e
    if e.key == :ArrowDown
      @history_ptr += 1
      @history_ptr = [@history_ptr, @history.length].min
      @input.value = @history[@history_ptr]
      e.prevent
    elsif e.key == :ArrowUp
      @history_ptr -= 1
      @history_ptr = [@history_ptr, 0].max
      @input.value = @history[@history_ptr]
      e.prevent
    end
  end

  LINEBREAKS = [
    "unexpected token $end",
    "unterminated string meets end of file"
  ]

  def extract_modifiers code
    @mods = {}
    if code.start_with? "show" # show compiled source
      code = code[5..-1]
      @mods[:show] = true
    elsif code.start_with? "ls" # pry-like ls
      code = code[3..-1]
      @mods[:ls] = true
    end
    @mods[:empty] = true if code.nil?
    code || ""
  end

  def handle_modifiers
    if @mods[:show]
      @content.text += "\n#{@compiled_code.chomp}\n-----------"
    end

    if @mods[:ls]
      if @mods[:native]
        # TODO
      elsif !@mods[:native]
        methods = imethods = @out.methods
        ancestors = @out.class.ancestors
        constants = []

        if [Class, Module].include? @out.class
          imethods = @out.instance_methods
          ancestors = @out.ancestors
          constants = @out.constants
        end

        out = ""
        ancestors.each do |a|
          im = a.instance_methods(false)
          meths = (im & imethods)
          methods -= meths
          imethods -= meths
          next if meths.empty? || [Object, BasicObject, Kernel].include?(a)
          out = "#{a.name}#methods: #{meths.sort.join("  ")}\n" + out
        end
        methods &= @out.methods(false)
        out = "self.methods: #{methods.sort.join("  ")}\n" + out if !methods.empty?
        out = "constants: #{constants.sort.join("  ")}\n" + out if !constants.empty?
        @content.text += "\n#{out.chomp}"
      end
    end
  end

  def execute e
    e.prevent

    code = @input.value || ""
    @history[@history_ptr,0] = [code]
    @history_ptr += 1
    @input.value = ""
    @content.text += "\nopal> #{code}"

    out = nil

    runcode = extract_modifiers(@tmpcode + code)

    begin
      @compiled_code = Opal::Compiler.new(runcode, irb: true).compile
      @out = `eval(#{@compiled_code})`
    rescue Exception => ex
      if Opal::SyntaxError === ex && LINEBREAKS.include?(ex.message)
        @tmpcode = @tmpcode + code + "\n"
      else
        @tmpcode = ''
        handle_modifiers
        @content.text += "\n#{ex.class.name}: #{ex.message}"
      end
    else
      @tmpcode = ''
      if native? @out
        @out = Native(@out)
        @mods[:native] = true
      end
      handle_modifiers
      @content.text += "\n=>#{@mods[:native] ? " Native:" : ""} #{@out.inspect}"
    end

    @container.scroll.to :bottom
  end
end

def miniirb
  MiniIrb.new.start
end

`window.miniirb = function() { #{miniirb} }`