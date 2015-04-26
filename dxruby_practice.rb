# encoding: utf-8
require "dxruby"
require "pry"
include Math

# 初期化
Window.width = 640
Window.height = 720
ENEMIES = []
BULLETS = []
SPRITES = [ENEMIES,BULLETS]

# 敵物体共通
class LinerMover < Sprite
  attr_accessor :deg, :spd, :action, :stop
  def initialize(x,y,deg,spd,img)
    super(x,y,img)
    self.deg = deg
    self.spd = spd
    self.action = []
    self.stop = false
  end

  def update
    action.each{|a|a.resume(self)}
    return if stop
    begin
      self.x += cos(deg*PI/180)*spd
      self.y += sin(deg*PI/180)*spd
    rescue
      binding.pry
    end
    vanish unless in_frame?
  end

  def in_frame?
    x.between?(-32,Window.width) && y.between?(-32,Window.height)
  end
end

# 弾
class Bullet < LinerMover
  IMG = Image.load("bullet.png")

  def initialize(x,y,deg,spd)
    super(x,y,deg,spd,IMG)
  end
end

# 敵
class Enemy < LinerMover
  IMG = Image.load("enemy.png")

  def initialize(x,y)
    super(x,y,rand(80..100),rand(1..4),IMG)
    action << [stop_and_go,zigzag,wave].sample
    action << [shot_around,shot_spiral].sample
    self.angle = 0
  end

  def update
    super
    self.angle += 5
  end
end

# ２秒進んで３秒とまる
def stop_and_go
  Fiber.new do |sprite|
    loop do
      60.times{Fiber.yield}
      sprite.stop = true
      90.times{Fiber.yield}
      sprite.stop = false
    end
  end
end

# ジグザグに３回移動して外に出る
def zigzag
  Fiber.new do |sprite|
    sprite.deg = rand(100..120)
    sprite.spd = 4
    60.times{Fiber.yield}

    sprite.deg = rand(-30..-10)
    sprite.spd = 3
    60.times{Fiber.yield}

    sprite.deg = rand(-100..-90)
    sprite.spd = 2
    60.times{Fiber.yield}

    sprite.deg = rand(70..90)
    sprite.spd = 6
    loop{Fiber.yield}
  end
end

def wave
  Fiber.new do |sprite|
    sprite.spd = 5
    loop do
      60.upto(120) do |deg|
        sprite.deg = deg
        Fiber.yield
      end
      120.downto(60) do |deg|
        sprite.deg = deg
        Fiber.yield
      end
    end
  end
end

# 全方位に弾を発射
def shot_around
  Fiber.new do |sprite|
    loop do
      36.times do |i|
        BULLETS << Bullet.new(sprite.x+32,sprite.y+32,i*10,5)
      end
      60.times{Fiber.yield}
    end
  end
end

# 渦巻き状に弾を発射
def shot_spiral
  Fiber.new do |sprite|
    loop do
      0.step(355,5) do |deg|
        BULLETS << Bullet.new(sprite.x+32,sprite.y+32,deg,5)
        2.times{Fiber.yield}
      end
    end
  end
end

# 敵出現パターン
ENCOUNTER = Fiber.new do
  loop do
    ENEMIES << Enemy.new(rand(300..340),0)
    rand(360).times{Fiber.yield}
  end
end

# メイン処理
Window.loop do
  ENCOUNTER.resume
  Sprite.update SPRITES
  Sprite.clean SPRITES
  Sprite.draw SPRITES
end
