class Action < Fiber
  def initialize(x)
    super(){loop{x+=1;puts x;stop;go;Fiber.yield}}
  end
  def stop
    puts "stop"
  end
  def go
    puts "go"
  end
end

a = Action.new(1)
b = Action.new(2)
c = Action.new(3)

[a,b,c].each(&:resume)
[a,b,c].each(&:resume)
