# encoding: utf-8
require "dxruby"
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
    self.x += cos(deg*PI/180)*spd
    self.y += sin(deg*PI/180)*spd
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
    action << [StopAndGo,ZigZag,Wave].sample.new
    action << [ShotAround,ShotSpiral].sample.new
    self.angle = 0
  end

  def update
    super
    self.angle += 5
  end
end

# アクション共通
class Action < Fiber
  def initialize
    super do |sprite|
      loop do
        yield sprite
      end
    end
  end

  def wait
    Fiber.yield
  end

  def wait_seconds(s)
    (s*60).to_i.times{Fiber.yield}
  end
end

# ２秒進んで３秒とまる
class StopAndGo < Action
  def initialize
    super do |sprite|
      wait_seconds(1); sprite.stop = true
      wait_seconds(1.5); sprite.stop = false
    end
  end
end

# ジグザグに３回移動して外に出る
class ZigZag < Action
  def initialize
    super do |sprite|
      sprite.deg = rand(100..120)
      sprite.spd = 4
      wait_seconds(1)

      sprite.deg = rand(-30..-10)
      sprite.spd = 3
      wait_seconds(1)

      sprite.deg = rand(-100..-90)
      sprite.spd = 2
      wait_seconds(1)

      sprite.deg = rand(70..90)
      sprite.spd = 6
      loop{wait}
    end
  end
end

# 左右に揺れて降下
class Wave < Action
  def initialize
    super do |sprite|
      sprite.spd = 5
      60.upto(120) do |deg|
        sprite.deg = deg
        wait()
      end
      120.downto(60) do |deg|
        sprite.deg = deg
        wait()
      end
    end
  end
end

# 全方位に弾を発射
class ShotAround < Action
  def initialize
    super do |sprite|
      36.times do |i|
        BULLETS << Bullet.new(sprite.x+32,sprite.y+32,i*10,5)
      end
      wait_seconds(1)
    end
  end
end

# 渦巻き状に弾を発射
class ShotSpiral < Action
  def initialize
    super do |sprite|
      0.step(355,5) do |deg|
        BULLETS << Bullet.new(sprite.x+32,sprite.y+32,deg,5)
        wait();wait()
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
