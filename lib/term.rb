class Term
  def initialize
  end

  def color(text, name)
    colors = {
      aqua: "1;36m",
      black: "1;30m",
      blue: "1;34m",
      green: "1;32m",
      purple: "1;35m",
      red: "1;31m",
      white: "1m",
      yellow: "1;33m"
    }
    return "\033[#{colors[name]}#{text}\033[0m"
  end

  def content(text)
    return unless text
    cr = "\r\e[0K" # keep cursor at beginning of line so we overwrite existing text each time
    print "#{cr}#{text}"
  end

  def readc # get user input one char at a time
    # thanks, _Ruby Cookbook_!
    state = `stty -g`
    begin
      `stty raw -echo cbreak`
      $stdin.getc
    ensure
      `stty #{state}`
    end
  end

  def show(text, with_leading_newline=false)
    puts '' if with_leading_newline
    puts text
  end
end
