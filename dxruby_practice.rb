# encoding: utf-8
require "dxruby"
include Math

# 初期化
ENEMY_IMG = Image.load("enemy.png")
BULLET_IMG = Image.load("bullet.png")
WIDTH = 640
HEIGHT = 720
ENEMIES = []
BULLETS = []
SPRITES = [ENEMIES,BULLETS]

# 等速直線運動
def liner_uniform_motion(deg,spd)
  Fiber.new do |obj|
    vx = cos(deg*PI/180)*spd
    vy = sin(deg*PI/180)*spd
    loop do
      obj.x += vx
      obj.y += vy
      Fiber.yield
    end
  end
end

# 停止しながら向きを変える
def go_and_stop(go,stop)
  Fiber.new do |obj|
    loop do
      vx = rand(-3..3)
      go.times do
        obj.x += vx
        obj.y += 2
        Fiber.yield
      end
      stop.times do
        Fiber.yield
      end
    end
  end
end

# 移動パターン設定
module MovePattern
  def initialize(x,y,img,pat)
    super(x,y,img)
    @pat = pat
  end
  def update
    super
    @pat.resume(self)
  end
end

module OutOfFrame　
  def update
    super
    vanish unless x.between?(-32,WIDTH) && y.between?(-32,HEIGHT)
  end
end

# 弾
class Bullet < Sprite
  include MovePattern,OutOfFrame
  def initialize(x,y,deg,spd)
    pat = liner_uniform_motion(deg,spd)
    super(x,y,BULLET_IMG,pat)
  end
end

# 敵
class Enemy < Sprite
  include MovePattern,OutOfFrame
  def initialize
    pat = go_and_stop(60,90)
    super(rand(0..WIDTH),0,ENEMY_IMG,pat)

    @type = rand(1..2)
    @tick = 0
  end

  def update
    super
    self.angle += 3
    @tick += 1

    case @type
    when 1
      BULLETS << Bullet.new(x+32,y+32,@tick*5,5) if @tick % 2 == 0
    when 2
      if @tick % 60 == 0
        36.times do |i|
          BULLETS << Bullet.new(x+32,y+32,i*10,5)
        end
      end
    end

  end
end

Window.width = WIDTH
Window.height = HEIGHT
Window.loop do
  ENEMIES << Enemy.new if ENEMIES.size == 0
  Sprite.update SPRITES
  Sprite.clean SPRITES
  Sprite.draw SPRITES
end
