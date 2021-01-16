class OSProject
  def initialize(type, dir)
    @type = type
    @dir = dir
  end

  def type
    @type
  end

  def dir
    @dir
  end

  def add_sdk
    puts "type:" + self.type + " dir: " + self.dir
  end
end
