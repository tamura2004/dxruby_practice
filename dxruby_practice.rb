# encoding: utf-8
require "dxruby"
include Math

# 初期化
Window.width = 640
Window.height = 720
ENEMIES = []
BULLETS = []
SPRITES = [ENEMIES,BULLETS]

# 移動物体共通
class MovingSprite < Sprite
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
class Bullet < MovingSprite
  IMG = Image.load("bullet.png")

  def initialize(x,y,deg,spd)
    super(x,y,deg,spd,IMG)
  end
end

# 敵
class Enemy < MovingSprite
  IMG = Image.load("enemy.png")

  def initialize(x,y)
    super(x,y,rand(80..100),rand(1..4),IMG)
    action << [StopAndGo,ZigZag,Wave].sample.new
    action << [ShotAround,ShotSpiral,Lazor].sample.new
    self.angle = 0
  end

  def update
    super
    self.angle += 5
  end
end

# アクション共通
class Action < Fiber
  def initialize(&block)
    super do |sprite|
      loop do
        sprite.instance_eval(&block)
      end
    end
  end
end

module ActionDSL
  # Action用DSL
  def wait_sec(sec=1)
    (sec*60).to_i.times{Fiber.yield}
  end

  def wait_tick(t=1)
    t.to_i.times{Fiber.yield}
  end

  def stay
    self.stop = true
  end

  def go
    self.stop = false
  end

  def goto_in_time(xx,yy,sec)
    dx = xx-x
    dy = yy-y
    self.deg = atan2(dy,dx)*180/PI
    self.spd = sqrt(dx**2+dy**2)/(sec*60)
    wait_sec(sec)
  end

  def shot(deg,spd)
    BULLETS << Bullet.new(x+32,y+32,deg,spd)
  end
end

class MovingSprite
  include ActionDSL
end


# ２秒進んで３秒とまる
class StopAndGo < Action
  def initialize
    super do
      wait_sec(1); stay; wait_sec(2); go
    end
  end
end

# ジグザグに３回移動して外に出る
class ZigZag < Action
  def initialize
    super do
      goto_in_time(100,600,2)
      goto_in_time(500,100,1)
      goto_in_time(50,200,3)
      goto_in_time(320,900,3)
    end
  end
end

# 左右に揺れて降下
class Wave < Action
  def initialize
    super do
      10.times do |i|
        goto_in_time(50,i*100+50,1)
        goto_in_time(558,i*100+100,1)
      end
    end
  end
end

# 全方位に弾を発射
class ShotAround < Action
  def initialize
    super do
      36.times do |i|
        shot(i*10,5)
      end
      wait_sec(1)
    end
  end
end

# 渦巻き状に弾を発射
class ShotSpiral < Action
  def initialize
    super do
      0.step(355,5) do |d|
        shot(d,5)
        wait_tick(2)
      end
    end
  end
end

# レーザーもどき
class Lazor < Action
  def initialize
    super do
      deg = rand(45..135)
      stay
      24.times{shot(deg,5);wait_tick}
      go
      wait_sec(3)
    end
  end
end

# 敵出現パターン
ENCOUNTER = Fiber.new do
  loop do
    ENEMIES << Enemy.new(rand(300..340),0)
    180.times{Fiber.yield}
  end
end

# メイン処理
Window.loop do
  ENCOUNTER.resume
  Sprite.update SPRITES
  Sprite.clean SPRITES
  Sprite.draw SPRITES
end
