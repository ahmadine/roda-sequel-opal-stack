class App
  def trigger_js *args
    "<script>(window.triggers=window.triggers||[]).push(#{args.to_json});</script>"
  end
end